import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/tweet.dart';
import '../../domain/usecases/tweet_usecases.dart';
import 'dependency_injection.dart';

/// 総合ツイート状態管理Provider
///
/// 役割:
/// - 全ユーザーの投稿したツイートを最新順で表示管理
/// - ボル活タブの左タブ「みんなのボル活」で使用
/// - ページネーション機能（無限スクロール対応）
/// - プルリフレッシュ機能
///
/// クリーンアーキテクチャにおける位置づけ:
/// - Presentation層の状態管理
/// - Domain層のGetTweetsUseCaseを呼び出し
/// - UIコンポーネント（general_tweets_section.dart）から参照される
///
/// 単一責任の原則:
/// - 総合ツイート表示に関する責任のみを持つ
/// - 特定ユーザーやジム別表示とは分離
/// - 投稿機能とは分離

class GeneralTweetsState {
  final List<Tweet> generalTweets;
  final bool hasMore;
  final bool isFirstFetch;
  final String? nextCursor;

  GeneralTweetsState({
    required this.generalTweets,
    required this.hasMore,
    required this.isFirstFetch,
    this.nextCursor,
  });
}

class GeneralTweetsNotifier extends StateNotifier<GeneralTweetsState> {
  bool _isLoading = false;
  final GetTweetsUseCase _getTweetsUseCase;

  GeneralTweetsNotifier(this._getTweetsUseCase)
      : super(GeneralTweetsState(
          generalTweets: [],
          hasMore: true,
          isFirstFetch: true,
          nextCursor: null,
        )) {
    _fetchMoreGeneralTweets();
  }

  Future<void> _fetchMoreGeneralTweets() async {
    if (_isLoading || !state.hasMore) return;

    _isLoading = true;

    try {
      // カーソルベースページネーション: 現在の最後のツイートの日時をカーソルとして使用
      final tweets = await _getTweetsUseCase.execute(
        cursor: state.nextCursor,
        limit: 20,
      );

      final List<Tweet> newGeneralTweetsList = tweets;

      if (newGeneralTweetsList.isEmpty) {
        // これ以上データがない場合
        state = GeneralTweetsState(
          generalTweets: state.generalTweets,
          hasMore: false,
          isFirstFetch: false,
          nextCursor: state.nextCursor,
        );
      } else {
        // 次のカーソルは取得したツイートリストの最後のツイートの投稿日時
        final nextCursor = newGeneralTweetsList.isNotEmpty 
            ? newGeneralTweetsList.last.tweetedDate.toIso8601String()
            : null;
            
        state = GeneralTweetsState(
          generalTweets: [...state.generalTweets, ...newGeneralTweetsList],
          hasMore: newGeneralTweetsList.length >= 20,
          isFirstFetch: false,
          nextCursor: nextCursor,
        );
      }
    } catch (error) {
      // エラーログ出力(開発環境で出力)
      // print('Error fetching general tweets: $error');
      state = GeneralTweetsState(
        generalTweets: state.generalTweets,
        hasMore: false,
        isFirstFetch: false,
        nextCursor: state.nextCursor,
      );
    } finally {
      _isLoading = false;
    }
  }

  void fetchMoreGeneralTweets() {
    _fetchMoreGeneralTweets();
  }

  /// Pull-to-Refresh対応：ツイート一覧を初期化して再取得
  Future<void> refreshTweets() async {
    if (_isLoading) return;

    // 状態を初期化して最新ツイートを取得（カーソルもリセット）
    state = GeneralTweetsState(
      generalTweets: [],
      hasMore: true,
      isFirstFetch: false, // リフレッシュ時は初回フェッチではない
      nextCursor: null,
    );

    await _fetchMoreGeneralTweets();
  }
}

/// 全体ツイート一覧Provider
final generalTweetsProvider = StateNotifierProvider.autoDispose<
    GeneralTweetsNotifier, GeneralTweetsState>((ref) {
  final getTweetsUseCase = ref.read(getTweetsUseCaseProvider);
  return GeneralTweetsNotifier(getTweetsUseCase);
});
