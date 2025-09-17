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
  final bool isFirstFetch;
  final String? error;

  const MyTweetsState({
    required this.tweets,
    required this.isLoading,
    required this.hasMore,
    required this.isFirstFetch,
    this.error,
  });

  MyTweetsState copyWith({
    List<Tweet>? tweets,
    bool? isLoading,
    bool? hasMore,
    bool? isFirstFetch,
    String? error,
  }) {
    return MyTweetsState(
      tweets: tweets ?? this.tweets,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      isFirstFetch: isFirstFetch ?? this.isFirstFetch,
      error: error ?? this.error,
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
  Future<void> refresh() async {
    state = const MyTweetsState(
      tweets: [],
      isLoading: false,
      hasMore: true,
      isFirstFetch: true,
    );
    await _fetchTweets();
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
/// ツイート読み込み状態を取得
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