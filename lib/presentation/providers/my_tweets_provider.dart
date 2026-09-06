import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/tweet.dart';
import '../../domain/usecases/tweet_usecases.dart';
import 'dependency_injection.dart';

/// 自分のツイート状態管理Provider
///
/// 役割:
/// - ログインユーザーが投稿したツイートのみを表示管理
/// - マイページの左タブ「ボル活」で使用
/// - ページネーション機能（無限スクロール対応）
/// - プルリフレッシュ機能
///
/// クリーンアーキテクチャにおける位置づけ:
/// - Presentation層の状態管理
/// - Domain層のGetUserTweetsUseCaseを呼び出し
/// - UIコンポーネント（my_tweets_section.dart）から参照される
///
/// 単一責任の原則:
/// - 自分のツイート表示に関する責任のみを持つ
/// - 総合ツイートや他ユーザー表示とは分離
/// - ユーザーIDによる状態管理（family provider使用）

/// 自分のツイート状態管理
///
/// 役割:
/// - ログインユーザーのツイート一覧を管理
/// - ページネーション機能
/// - ローディング状態管理
/// - プルリフレッシュ対応
///
/// クリーンアーキテクチャにおける位置づき:
/// - Presentation層のProvider
/// - Domain層のUseCaseを呼び出し
class MyTweetsState {
  final List<Tweet> tweets;
  final bool isLoading;
  final bool hasMore;

  /// 初回取得（まだ一度もサーバーから結果を受け取っていない）かどうか。
  /// 骨組み（スケルトン）はこれが true の間だけ出す。
  /// プルリフレッシュでは true に戻さない（更新中も今の一覧／空状態を出し続ける・#77）
  final bool isFirstFetch;

  /// プルリフレッシュで先頭ページを取り直している最中か。
  /// この間も tweets は保持したまま（新しいページが届いた時点で差し替える）
  final bool isRefreshing;

  final String? error;

  /// 次ページ取得用カーソル（＝取得済み最後のツイートの投稿日時ISO8601）。
  /// nullなら先頭から取得。リフレッシュ時は新規stateを作ることでnullに戻る。
  final String? nextCursor;

  const MyTweetsState({
    required this.tweets,
    required this.isLoading,
    required this.hasMore,
    required this.isFirstFetch,
    this.isRefreshing = false,
    this.error,
    this.nextCursor,
  });

  /// [clearError] を true にすると error を null に戻す
  /// （`error: null` は「変更なし」扱いになるため、明示的に消すためのフラグ）
  MyTweetsState copyWith({
    List<Tweet>? tweets,
    bool? isLoading,
    bool? hasMore,
    bool? isFirstFetch,
    bool? isRefreshing,
    String? error,
    bool clearError = false,
    String? nextCursor,
  }) {
    return MyTweetsState(
      tweets: tweets ?? this.tweets,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      isFirstFetch: isFirstFetch ?? this.isFirstFetch,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: clearError ? null : (error ?? this.error),
      nextCursor: nextCursor ?? this.nextCursor,
    );
  }
}

/// 自分のツイート状態を管理するStateNotifier
class MyTweetsNotifier extends StateNotifier<MyTweetsState> {
  final String userId;
  final GetUserTweetsUseCase _getUserTweetsUseCase;
  static const int _pageSize = 20;
  bool _isLoading = false;

  MyTweetsNotifier(this.userId, this._getUserTweetsUseCase)
      : super(const MyTweetsState(
          tweets: [],
          isLoading: false,
          hasMore: true,
          isFirstFetch: true,
        )) {
    _fetchTweets();
  }

  /// ツイートを取得する
  ///
  /// ページネーション対応
  Future<void> _fetchTweets() async {
    if (_isLoading || !state.hasMore) return;

    _isLoading = true;

    try {
      final tweets = await _getUserTweetsUseCase.execute(
        userId,
        cursor: state.nextCursor,
        limit: _pageSize,
      );

      final List<Tweet> newTweetsList = tweets;

      if (newTweetsList.isEmpty) {
        state = state.copyWith(
          hasMore: false,
          isFirstFetch: false,
          clearError: true,
        );
      } else {
        state = state.copyWith(
          tweets: [...state.tweets, ...newTweetsList],
          hasMore: newTweetsList.length >= _pageSize,
          isFirstFetch: false,
          clearError: true,
          // 次ページは「今回取得した最後のツイートより前」を取りに行く
          nextCursor: newTweetsList.last.tweetedDate.toIso8601String(),
        );
      }
    } catch (error) {
      state = state.copyWith(
        hasMore: false,
        isFirstFetch: false,
        error: '自分のツイート取得に失敗しました: $error',
      );
    } finally {
      _isLoading = false;
    }
  }

  /// さらにツイートを読み込み（ページネーション）
  void loadMore() {
    _fetchTweets();
  }

  /// ツイート一覧を更新（プルリフレッシュ用）
  ///
  /// 表示中の一覧（または空状態）はそのまま残し、先頭ページを取り直して
  /// 届いた時点で差し替える（tweets を先に空にしない・isFirstFetch も立てない＝骨組みを出さない・#77）。
  /// 取得に失敗した場合は以前の一覧を保持したまま false を返す
  /// （呼び出し側で SnackBar 等で知らせる。一覧をエラー表示に置き換えない）。
  Future<bool> refresh() async {
    // 初回取得や追加読込が進行中なら重ねて取りに行かない（進行中の結果がそのまま反映される）
    if (_isLoading) return true;

    _isLoading = true;
    state = state.copyWith(isRefreshing: true);

    try {
      final tweets = await _getUserTweetsUseCase.execute(
        userId,
        cursor: null,
        limit: _pageSize,
      );

      state = MyTweetsState(
        tweets: tweets,
        isLoading: false,
        hasMore: tweets.length >= _pageSize,
        isFirstFetch: false,
        isRefreshing: false,
        error: null,
        nextCursor:
            tweets.isEmpty ? null : tweets.last.tweetedDate.toIso8601String(),
      );
      return true;
    } catch (_) {
      state = state.copyWith(isRefreshing: false);
      return false;
    } finally {
      _isLoading = false;
    }
  }

  /// 削除済みのツイートを一覧から取り除く（#75）
  ///
  /// サーバー側で削除が成功したあとに呼ぶ。再取得はせず、メモリ上の一覧から
  /// 該当 ID だけを外す（O(n)）。nextCursor は「取得済み最後のツイートの投稿日時」で、
  /// そのツイートが消えても「その日時より前」を取る境界としてそのまま有効なので触らない。
  void removeTweet(int tweetId) {
    if (!state.tweets.any((t) => t.id == tweetId)) return;
    state = state.copyWith(
      tweets: state.tweets.where((t) => t.id != tweetId).toList(),
    );
  }

  /// ツイートをクリア
  void clear() {
    state = const MyTweetsState(
      tweets: [],
      isLoading: false,
      hasMore: true,
      isFirstFetch: true,
    );
  }
}

/// 自分のツイート管理Provider
///
/// ユーザーIDごとに独立してツイート一覧を管理
final myTweetsProvider = StateNotifierProvider.family<
    MyTweetsNotifier, MyTweetsState, String>(
  (ref, userId) {
    final getUserTweetsUseCase = ref.read(getUserTweetsUseCaseProvider);
    return MyTweetsNotifier(userId, getUserTweetsUseCase);
  },
);

/// 自分のツイートローディング状態Provider
///
/// 「初回読込中（まだ一度もデータを受け取っていない）」かどうかを返す。
/// プルリフレッシュ中は true にならない（isRefreshing を見ること）
final isMyTweetsLoadingProvider =
    Provider.family<bool, String>((ref, userId) {
  final tweetsState = ref.watch(myTweetsProvider(userId));
  return tweetsState.isFirstFetch;
});

/// 自分のツイート一覧Provider
///
/// ツイート一覧を取得
final myTweetsListProvider =
    Provider.family<List<Tweet>, String>((ref, userId) {
  final tweetsState = ref.watch(myTweetsProvider(userId));
  return tweetsState.tweets;
});
