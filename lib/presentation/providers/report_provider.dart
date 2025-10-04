import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecases/report_usecase.dart';
import 'dependency_injection.dart';

/// 報告投稿状態管理Provider
///
/// 役割:
/// - ツイート報告機能の管理
/// - 報告処理中の状態管理
/// - エラーハンドリング
///
/// クリーンアーキテクチャにおける位置づけ:
/// - Presentation層の状態管理
/// - Domain層のUseCaseを呼び出し
/// - UIコンポーネントから参照される
///
/// 使用場所:
/// - report_page.dart: 報告フォーム画面
/// - boul_log.dart: ツイート表示コンポーネント
///
/// 単一責任の原則:
/// - ツイート報告に関する責任のみを持つ
/// - 他の機能とは分離
/// - 他のプロバイダーとの依存関係なし

/// 報告投稿状態を管理するStateNotifier
///
/// AsyncValue<bool>の意味:
/// - loading: 報告処理中
/// - data(true): 報告成功
/// - data(false): 初期状態または報告失敗
/// - error: エラー発生
class ReportNotifier extends StateNotifier<AsyncValue<bool>> {
  final CreateReportUseCase _createReportUseCase;

  /// コンストラクタ
  ///
  /// 初期状態はdata(false)
  ReportNotifier(this._createReportUseCase)
      : super(const AsyncValue.data(false));

  /// 報告を送信
  ///
  /// [reporterUserId] 報告者のユーザーID
  /// [targetUserId] 報告対象ツイートの投稿者ID
  /// [targetTweetId] 報告対象のツイートID
  /// [reportDescription] 報告内容の詳細
  ///
  /// 返り値:
  /// - true: 報告成功
  /// - false: 報告失敗
  ///
  /// 処理フロー:
  /// 1. ローディング状態に設定
  /// 2. UseCaseを呼び出して報告処理実行
  /// 3. 成功/失敗を状態に反映
  /// 4. 結果を返す
  Future<bool> submitReport({
    required String reporterUserId,
    required String targetUserId,
    required int targetTweetId,
    required String reportDescription,
  }) async {
    // 報告処理開始（ローディング状態）
    state = const AsyncValue.loading();

    try {
      // 報告送信処理を実行
      final success = await _createReportUseCase.execute(
        reporterUserId: reporterUserId,
        targetUserId: targetUserId,
        targetTweetId: targetTweetId,
        reportDescription: reportDescription,
      );

      // 成功状態を設定
      state = AsyncValue.data(success);
      return success;
    } catch (e, stackTrace) {
      // エラー状態を設定
      state = AsyncValue.error(e, stackTrace);
      return false;
    }
  }

  /// 状態をリセット
  ///
  /// 報告画面を離れる時や、再度報告フォームを開く際に呼び出す
  void reset() {
    state = const AsyncValue.data(false);
  }
}

/// 報告機能プロバイダー
///
/// 使用方法:
/// ```dart
/// final reportNotifier = ref.read(reportProvider.notifier);
/// final reportState = ref.watch(reportProvider);
/// 
/// // 報告を送信
/// final success = await reportNotifier.submitReport(
///   reporterUserId: myUserId,
///   targetUserId: tweetUserId,
///   targetTweetId: tweetId,
///   reportDescription: description,
/// );
/// ```
final reportProvider = StateNotifierProvider<ReportNotifier, AsyncValue<bool>>((ref) {
  final createReportUseCase = ref.read(createReportUseCaseProvider);
  return ReportNotifier(createReportUseCase);
});