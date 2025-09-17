import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/tweet.dart';
import '../../domain/usecases/tweet_usecases.dart';
import 'dependency_injection.dart';

/// 他ユーザーツイート状態管理Provider
///
/// 役割:
/// - 特定の他ユーザーが投稿したツイートのみを表示管理
/// - 他ユーザーのプロフィールページで使用
/// - ページネーション機能（無限スクロール対応）
/// - プルリフレッシュ機能
/// - ローディング状態管理
///
/// クリーンアーキテクチャにおける位置づけ:
/// - Presentation層の状態管理
/// - Domain層のGetUserTweetsUseCaseを呼び出し
/// - UIコンポーネント（other_user_tweets_section.dart）から参照される
///
/// 単一責任の原則:
/// - 他ユーザーツイート表示に関する責任のみを持つ
/// - 自分のツイートや総合表示とは分離
/// - ユーザーIDによる状態管理（family provider使用）

/// 他ユーザーのツイート状態管理
class OtherUserTweetsState {
  final List<Tweet> tweets;
  final bool isLoading;
  final bool hasMore;
  final bool isFirstFetch;
  final String? error;

  const OtherUserTweetsState({
    required this.tweets,
    required this.isLoading,
    required this.hasMore,
    required this.isFirstFetch,
    this.error,
  });

  OtherUserTweetsState copyWith({
    List<Tweet>? tweets,
    bool? isLoading,
    bool? hasMore,
    bool? isFirstFetch,
    String? error,
  }) {
    return OtherUserTweetsState(
      tweets: tweets ?? this.tweets,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      isFirstFetch: isFirstFetch ?? this.isFirstFetch,
      error: error ?? this.error,
    );
  }
}

/// 他ユーザーのツイート状態を管理するStateNotifier
class OtherUserTweetsNotifier extends StateNotifier<OtherUserTweetsState> {
  final String userId;
  final GetUserTweetsUseCase _getUserTweetsUseCase;
  static const int _pageSize = 20;
  bool _isLoading = false;

  OtherUserTweetsNotifier(this.userId, this._getUserTweetsUseCase)
      : super(const OtherUserTweetsState(
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
        offset: state.tweets.length,
        limit: _pageSize,
      );

      final List<Tweet> newTweetsList = tweets;

      if (newTweetsList.isEmpty) {
        state = state.copyWith(
          hasMore: false,
          isFirstFetch: false,
          error: null,
        );
      } else {
        state = state.copyWith(
          tweets: [...state.tweets, ...newTweetsList],
          hasMore: newTweetsList.length >= _pageSize,
          isFirstFetch: false,
          error: null,
        );
      }
    } catch (error) {
      state = state.copyWith(
        hasMore: false,
        isFirstFetch: false,
        error: 'ツイートの取得に失敗しました: $error',
      );
    } finally {
      _isLoading = false;
    }
  }

  void fetchTweets() {
    _fetchTweets();
  }

  /// ツイート一覧を更新（プルリフレッシュ用）
  Future<void> refresh() async {
    state = const OtherUserTweetsState(
      tweets: [],
      isLoading: false,
      hasMore: true,
      isFirstFetch: true,
    );
    await _fetchTweets();
  }

  /// ツイートをクリア
  void clear() {
    state = const OtherUserTweetsState(
      tweets: [],
      isLoading: false,
      hasMore: true,
      isFirstFetch: true,
    );
  }
}

/// 他ユーザーツイート管理Provider
///
/// ユーザーIDごとに独立してツイート一覧を管理
final otherUserTweetsProvider = StateNotifierProvider.family<
    OtherUserTweetsNotifier, OtherUserTweetsState, String>(
  (ref, userId) {
    final getUserTweetsUseCase = ref.read(getUserTweetsUseCaseProvider);
    return OtherUserTweetsNotifier(userId, getUserTweetsUseCase);
  },
);

/// 他ユーザーツイートローディング状態Provider
///
/// 指定ユーザーのツイート読み込み状態を取得
final isOtherUserTweetsLoadingProvider =
    Provider.family<bool, String>((ref, userId) {
  final tweetsState = ref.watch(otherUserTweetsProvider(userId));
  return tweetsState.isFirstFetch;
});

/// 他ユーザーツイート一覧Provider
///
/// 指定ユーザーのツイート一覧を取得
final otherUserTweetsListProvider =
    Provider.family<List<Tweet>, String>((ref, userId) {
  final tweetsState = ref.watch(otherUserTweetsProvider(userId));
  return tweetsState.tweets;
});
