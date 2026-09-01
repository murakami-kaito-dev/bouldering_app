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

  /// 直近の取得が失敗したか（オフライン等）。
  /// 「本当にデータがない（空）」と「取得に失敗した」を区別するために持つ
  final bool hasError;

  GeneralTweetsState({
    required this.generalTweets,
    required this.hasMore,
    required this.isFirstFetch,
    this.nextCursor,
    this.hasError = false,
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
      // 取得失敗（オフライン等）。hasMore:false で止めるが hasError を立てて
      // 「データ終端」と区別する（以前は区別がなく、オフライン起動時に
      // 真っ白のまま復旧手段がない状態になっていた）
      state = GeneralTweetsState(
        generalTweets: state.generalTweets,
        hasMore: false,
        isFirstFetch: false,
        nextCursor: state.nextCursor,
        hasError: true,
      );
    } finally {
      _isLoading = false;
    }
  }

  void fetchMoreGeneralTweets() {
    _fetchMoreGeneralTweets();
  }

  /// 初回取得が失敗して1件も表示できていない場合のみ取得し直す
  ///
  /// オフライン起動からの自己回復用（アプリ復帰時に app.dart から呼ばれる）。
  /// 正常に表示できている場合は何もしない（余計な再取得をしない）
  Future<void> retryInitialIfFailed() async {
    if (state.hasError && state.generalTweets.isEmpty) {
      await refreshTweets();
    }
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
///
/// autoDispose は意図的に付けていない。
/// タブを開くたびに Notifier が再生成され、コンストラクタで毎回 DB 取得されるのを防ぐため、
/// 状態をアプリ生存期間中保持する。DB アクセスは「アプリ起動後の初回取得」と
/// 「Pull-refresh（refreshTweets）」のときだけに限定される。
final generalTweetsProvider = StateNotifierProvider<
    GeneralTweetsNotifier, GeneralTweetsState>((ref) {
  final getTweetsUseCase = ref.read(getTweetsUseCaseProvider);
  return GeneralTweetsNotifier(getTweetsUseCase);
});
