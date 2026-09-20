import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/comment.dart';
import '../../domain/entities/tweet.dart';
import '../../domain/usecases/comment_usecases.dart';
import 'dependency_injection.dart';
import 'favorite_user_tweets_provider.dart';
import 'general_tweets_provider.dart';
import 'gym_tweets_provider.dart';
import 'my_tweets_provider.dart';
import 'other_user_tweets_provider.dart';
import 'user_provider.dart';

/// スレッド（コメント）状態管理 Provider
///
/// 役割:
/// - 1 ツイートのコメント一覧（作成日時 昇順・フラット）を保持
/// - 投稿（返信を含む）・削除を反映
/// - 表示の 2 段化・削除済みの表示ルールは画面側（TweetDetailPage）で行う
///
/// クリーンアーキテクチャにおける位置づけ:
/// - Presentation 層の状態管理
/// - Domain 層のコメント UseCase を呼び出す
///
/// autoDispose: スレッド画面を閉じたら破棄する（一覧系と違い、画面ごとに読み直してよい）

class TweetCommentsState {
  final List<Comment> comments;

  /// 初回読み込み中か
  final bool isLoading;

  /// 追加読み込み中か
  final bool isLoadingMore;
  final bool hasMore;
  final bool isSending;
  final String? error;
  final String? nextCursor;

  const TweetCommentsState({
    required this.comments,
    required this.isLoading,
    this.isLoadingMore = false,
    required this.hasMore,
    this.isSending = false,
    this.error,
    this.nextCursor,
  });

  TweetCommentsState copyWith({
    List<Comment>? comments,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    bool? isSending,
    String? error,
    String? nextCursor,
  }) {
    return TweetCommentsState(
      comments: comments ?? this.comments,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      isSending: isSending ?? this.isSending,
      error: error,
      nextCursor: nextCursor ?? this.nextCursor,
    );
  }
}

class TweetCommentsNotifier extends StateNotifier<TweetCommentsState> {
  final int tweetId;
  final GetTweetCommentsUseCase _getComments;
  final CreateCommentUseCase _createComment;
  final DeleteCommentUseCase _deleteComment;

  static const int _pageSize = 50;

  /// 初回に自動で読み進める最大ページ数（木構造を途中で切らないため、まとめて読む）
  static const int _initialMaxPages = 5;

  bool _isFetching = false;

  TweetCommentsNotifier(
    this.tweetId,
    this._getComments,
    this._createComment,
    this._deleteComment,
  ) : super(const TweetCommentsState(
          comments: [],
          isLoading: true,
          hasMore: true,
        )) {
    _initialLoad();
  }

  Future<void> _initialLoad() async {
    for (var page = 0; page < _initialMaxPages && state.hasMore; page++) {
      final ok = await _fetchNextPage();
      if (!ok) break;
    }
    if (mounted) {
      state = state.copyWith(isLoading: false, error: state.error);
    }
  }

  /// 次ページを取得して末尾に足す。失敗時は false
  Future<bool> _fetchNextPage() async {
    if (_isFetching || !state.hasMore) return false;
    _isFetching = true;
    try {
      final fetched = await _getComments.execute(
        tweetId,
        limit: _pageSize,
        cursor: state.nextCursor,
      );
      if (!mounted) return false;

      // 既に持っている ID は重複させない（同一ミリ秒の境界対策）
      final known = state.comments.map((c) => c.id).toSet();
      final fresh = fetched.where((c) => !known.contains(c.id)).toList();

      state = state.copyWith(
        comments: [...state.comments, ...fresh],
        hasMore: fetched.length >= _pageSize,
        nextCursor: fetched.isNotEmpty
            ? fetched.last.createdAt.toUtc().toIso8601String()
            : state.nextCursor,
        error: null,
      );
      return true;
    } catch (e) {
      if (mounted) {
        state = state.copyWith(hasMore: false, error: 'コメントの取得に失敗しました');
      }
      return false;
    } finally {
      _isFetching = false;
    }
  }

  /// さらに読み込む（初回 5 ページを超える長いスレッド用）
  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore) return;
    state = state.copyWith(isLoadingMore: true, error: state.error);
    await _fetchNextPage();
    if (mounted) state = state.copyWith(isLoadingMore: false, error: state.error);
  }

  /// 最初から読み直す
  Future<void> refresh() async {
    if (_isFetching) return;
    state = const TweetCommentsState(
      comments: [],
      isLoading: true,
      hasMore: true,
    );
    await _initialLoad();
  }

  /// コメント投稿（返信は [parentCommentId] を付ける）。成功時は一覧末尾に追加して返す
  ///
  /// 失敗時は例外を投げる（画面側で SnackBar を出す）
  Future<Comment> addComment({
    required String content,
    int? parentCommentId,
  }) async {
    state = state.copyWith(isSending: true, error: state.error);
    try {
      final created = await _createComment.execute(
        tweetId,
        content: content,
        parentCommentId: parentCommentId,
      );
      if (mounted) {
        state = state.copyWith(
          comments: [...state.comments, created],
          isSending: false,
          error: state.error,
        );
      }
      return created;
    } catch (e) {
      if (mounted) state = state.copyWith(isSending: false, error: state.error);
      rethrow;
    }
  }

  /// コメント削除（論理削除）。成功時はその行を「削除済み」に置き換える
  ///
  /// 失敗時は例外を投げる（画面側で SnackBar を出す）
  Future<void> deleteComment(int commentId) async {
    await _deleteComment.execute(commentId);
    if (!mounted) return;
    state = state.copyWith(
      comments: [
        for (final c in state.comments)
          c.id == commentId ? c.copyWith(isDeleted: true, content: '') : c,
      ],
      error: state.error,
    );
  }
}

/// ツイートごとのコメント一覧 Provider
final tweetCommentsProvider = StateNotifierProvider.autoDispose
    .family<TweetCommentsNotifier, TweetCommentsState, int>((ref, tweetId) {
  return TweetCommentsNotifier(
    tweetId,
    ref.read(getTweetCommentsUseCaseProvider),
    ref.read(createCommentUseCaseProvider),
    ref.read(deleteCommentUseCaseProvider),
  );
});

/// コメント数の変化（+1 / -1）を、生きている各一覧 Notifier に反映する
///
/// 同じツイートが複数の一覧（みんなのボル活・お気に入り・ジム・他ユーザー・自分）に
/// 同時に載っていても件数が食い違わないようにする。`ref.exists` で生成済みのものだけ触る
/// （family Provider は引数ごとに別インスタンスなので、ツイートの投稿者・ジム・自分の ID から特定する）
void syncTweetCommentCount(WidgetRef ref, Tweet tweet, int delta) {
  final myUserId = ref.read(userProvider).valueOrNull?.id;

  if (ref.exists(generalTweetsProvider)) {
    ref.read(generalTweetsProvider.notifier).updateCommentCount(tweet.id, delta);
  }
  if (ref.exists(gymTweetsProvider(tweet.gymId))) {
    ref
        .read(gymTweetsProvider(tweet.gymId).notifier)
        .updateCommentCount(tweet.id, delta);
  }
  if (ref.exists(otherUserTweetsProvider(tweet.userId))) {
    ref
        .read(otherUserTweetsProvider(tweet.userId).notifier)
        .updateCommentCount(tweet.id, delta);
  }
  if (myUserId != null) {
    if (ref.exists(myTweetsProvider(myUserId))) {
      ref
          .read(myTweetsProvider(myUserId).notifier)
          .updateCommentCount(tweet.id, delta);
    }
    if (ref.exists(favoriteUserTweetsProvider(myUserId))) {
      ref
          .read(favoriteUserTweetsProvider(myUserId).notifier)
          .updateCommentCount(tweet.id, delta);
    }
  }
}
