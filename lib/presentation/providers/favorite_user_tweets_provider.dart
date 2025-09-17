import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/tweet.dart';
import '../../domain/usecases/tweet_usecases.dart';
import 'dependency_injection.dart';

/// お気に入りユーザーツイート状態管理Provider
///
/// 役割:
/// - ログインユーザーがお気に入り登録したユーザーのツイートのみ表示管理
/// - ボル活タブの右タブ「お気に入り」で使用
/// - ページネーション機能（無限スクロール対応）
/// - プルリフレッシュ機能
///
/// クリーンアーキテクチャにおける位置づけ:
/// - Presentation層の状態管理
/// - Domain層のGetFavoriteTweetsUseCaseを呼び出し
/// - UIコンポーネント（favorite_tweets_section.dart）から参照される
///
/// 単一責任の原則:
/// - お気に入りユーザーツイート表示に関する責任のみを持つ
/// - 総合ツイートや他ユーザー表示とは分離
/// - ユーザーIDによる状態管理（family provider使用）

class FavoriteUserTweetsState {
  final List<Tweet> favoriteUserTweets;
  final bool hasMore;
  final bool isFirstFetch;
  final String? nextCursor;

  FavoriteUserTweetsState({
    required this.favoriteUserTweets,
    required this.hasMore,
    required this.isFirstFetch,
    this.nextCursor,
  });
}

class FavoriteUserTweetsNotifier
    extends StateNotifier<FavoriteUserTweetsState> {
  bool _isLoading = false;
  final String userId;
  final GetFavoriteTweetsUseCase _getFavoriteTweetsUseCase;

  FavoriteUserTweetsNotifier(this.userId, this._getFavoriteTweetsUseCase)
      : super(FavoriteUserTweetsState(
          favoriteUserTweets: [],
          hasMore: true,
          isFirstFetch: true,
          nextCursor: null,
        )) {
    _fetchMoreFavoriteUserTweets();
  }

  Future<void> _fetchMoreFavoriteUserTweets() async {
    if (_isLoading || !state.hasMore) return;

    _isLoading = true;

    try {
      // カーソルベースページネーション: 現在の最後のツイートの日時をカーソルとして使用
      final tweets = await _getFavoriteTweetsUseCase.execute(
        userId,
        cursor: state.nextCursor,
        limit: 20,
      );

      final List<Tweet> newFavoriteUserTweetsList = tweets;

      if (newFavoriteUserTweetsList.isEmpty) {
        // これ以上データがない場合
        state = FavoriteUserTweetsState(
          favoriteUserTweets: state.favoriteUserTweets,
          hasMore: false,
          isFirstFetch: false,
          nextCursor: state.nextCursor,
        );
      } else {
        // 次のカーソルは取得したツイートリストの最後のツイートの投稿日時
        final nextCursor = newFavoriteUserTweetsList.isNotEmpty 
            ? newFavoriteUserTweetsList.last.tweetedDate.toIso8601String()
            : null;
            
        state = FavoriteUserTweetsState(
          favoriteUserTweets: [
            ...state.favoriteUserTweets,
            ...newFavoriteUserTweetsList
          ],
          hasMore: newFavoriteUserTweetsList.length >= 20,
          isFirstFetch: false,
          nextCursor: nextCursor,
        );
      }
    } catch (error) {
      // エラーログ出力(開発環境のみ出力)
      // print('Error fetching favorite user tweets: $error');
      state = FavoriteUserTweetsState(
        favoriteUserTweets: state.favoriteUserTweets,
        hasMore: false,
        isFirstFetch: false,
        nextCursor: state.nextCursor,
      );
    } finally {
      _isLoading = false;
    }
  }

  void fetchMoreFavoriteUserTweets() {
    _fetchMoreFavoriteUserTweets();
  }

  /// Pull-to-Refresh対応：お気に入りユーザーのツイート一覧を初期化して再取得
  Future<void> refreshTweets() async {
    if (_isLoading) return;

    // 状態を初期化して最新ツイートを取得（カーソルもリセット）
    state = FavoriteUserTweetsState(
      favoriteUserTweets: [],
      hasMore: true,
      isFirstFetch: false, // リフレッシュ時は初回フェッチではない
      nextCursor: null,
    );

    await _fetchMoreFavoriteUserTweets();
  }
}

/// お気に入りユーザーのツイート一覧Provider
final favoriteUserTweetsProvider = StateNotifierProvider.family
    .autoDispose<FavoriteUserTweetsNotifier, FavoriteUserTweetsState, String>(
        (ref, userId) {
  final getFavoriteTweetsUseCase = ref.read(getFavoriteTweetsUseCaseProvider);
  return FavoriteUserTweetsNotifier(userId, getFavoriteTweetsUseCase);
});
