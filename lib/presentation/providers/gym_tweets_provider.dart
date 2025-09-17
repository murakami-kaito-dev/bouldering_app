import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/tweet.dart';
import '../../domain/usecases/tweet_usecases.dart';
import 'dependency_injection.dart';

/// ジム別ツイート状態管理Provider（施設ツイート）
///
/// 役割:
/// - 特定ジムでの投稿のみを表示管理
/// - ジム詳細ページの右タブ「ボル活」で使用
/// - ログイン・未ログイン問わず表示可能
/// - ページネーション機能（無限スクロール対応）
/// - プルリフレッシュ機能
///
/// クリーンアーキテクチャにおける位置づけ:
/// - Presentation層の状態管理
/// - Domain層のGetGymTweetsUseCaseを呼び出し
/// - UIコンポーネント（gym_detail_page.dart内）から参照される
///
/// 単一責任の原則:
/// - ジム別ツイート表示に関する責任のみを持つ
/// - 総合ツイートやユーザー別表示とは分離
/// - ジムIDによる状態管理（family provider使用）

/// 特定ジムのツイート状態
class GymTweetsState {
  final List<Tweet> tweets;
  final bool isLoading;
  final bool hasMore;
  final String? error;

  const GymTweetsState({
    required this.tweets,
    required this.isLoading,
    required this.hasMore,
    this.error,
  });

  GymTweetsState copyWith({
    List<Tweet>? tweets,
    bool? isLoading,
    bool? hasMore,
    String? error,
  }) {
    return GymTweetsState(
      tweets: tweets ?? this.tweets,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }
}

/// 特定ジムのツイート管理StateNotifier
///
/// 役割:
/// - 指定されたジムのツイートのみを管理
/// - ページネーション機能
/// - 他のツイートプロバイダーとの干渉を防ぐ
class GymTweetsNotifier extends StateNotifier<GymTweetsState> {
  final int gymId;
  final GetGymTweetsUseCase _getGymTweetsUseCase;
  static const int _pageSize = 20;
  bool _isLoading = false;

  GymTweetsNotifier(this.gymId, this._getGymTweetsUseCase)
      : super(const GymTweetsState(
          tweets: [],
          isLoading: false,
          hasMore: true,
        )) {
    // 自動初期化：指定ジムのツイートを取得
    _fetchGymTweets();
  }

  /// 指定ジムのツイートを取得
  Future<void> _fetchGymTweets() async {
    if (_isLoading || !state.hasMore) return;

    _isLoading = true;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final tweets = await _getGymTweetsUseCase.execute(
        gymId,
        limit: _pageSize,
        offset: state.tweets.length,
      );

      final List<Tweet> newTweetsList = tweets;

      if (newTweetsList.isEmpty) {
        state = state.copyWith(
          hasMore: false,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          tweets: [...state.tweets, ...newTweetsList],
          hasMore: newTweetsList.length >= _pageSize,
          isLoading: false,
        );
      }
    } catch (error) {
      state = state.copyWith(
        hasMore: false,
        isLoading: false,
        error: 'ジムのツイート取得に失敗しました: $error',
      );
    } finally {
      _isLoading = false;
    }
  }

  /// さらにツイートを読み込み（ページネーション）
  void loadMore() {
    _fetchGymTweets();
  }

  /// リフレッシュ（最初から取得し直し）
  Future<void> refresh() async {
    state = const GymTweetsState(
      tweets: [],
      isLoading: false,
      hasMore: true,
    );
    await _fetchGymTweets();
  }
}

/// 特定ジムのツイートプロバイダー
///
/// ジムIDごとに独立したインスタンスを管理
/// 過去のプロジェクトのspecificGymTweetsProviderと同様の役割
final gymTweetsProvider =
    StateNotifierProvider.family<GymTweetsNotifier, GymTweetsState, int>(
        (ref, gymId) {
  final getGymTweetsUseCase = ref.read(getGymTweetsUseCaseProvider);
  return GymTweetsNotifier(gymId, getGymTweetsUseCase);
});
