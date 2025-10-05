import '../entities/report.dart';
import '../repositories/report_repository.dart';
import '../exceptions/app_exceptions.dart';

/// 報告作成のユースケース
/// 
/// ツイートの不適切な内容を報告するビジネスロジックを担当
class CreateReportUseCase {
  final ReportRepository _reportRepository;

  CreateReportUseCase(this._reportRepository);

  /// 報告を作成する
  /// 
  /// [reporterUserId] 報告者のユーザーID
  /// [targetUserId] 報告対象ツイートの投稿者ID
  /// [targetTweetId] 報告対象のツイートID
  /// [reportDescription] 報告内容の詳細
  Future<bool> execute({
    required String reporterUserId,
    required String targetUserId,
    required int targetTweetId,
    required String reportDescription,
  }) async {
    try {
      // バリデーション
      if (reportDescription.trim().isEmpty) {
        throw const ValidationException(
          message: '報告内容を入力してください',
          errors: {'reportDescription': '報告内容は必須です'},
          code: 'EMPTY_REPORT_DESCRIPTION',
        );
      }

      // 報告内容の文字数制限（必要に応じて調整）
      if (reportDescription.length > 1000) {
        throw const ValidationException(
          message: '報告内容は1000文字以内で入力してください',
          errors: {'reportDescription': '報告内容が長すぎます'},
          code: 'REPORT_DESCRIPTION_TOO_LONG',
        );
      }

      // 自分自身のツイートを報告しようとしているかチェック（二重チェック）
      // UI側でも制御するが、安全のため
      if (reporterUserId == targetUserId) {
        throw const ValidationException(
          message: '自分のツイートを報告することはできません',
          errors: {'targetUserId': '自分のツイートは報告できません'},
          code: 'CANNOT_REPORT_OWN_TWEET',
        );
      }

      // Reportエンティティを作成
      final report = Report(
        reporterUserId: reporterUserId,
        targetUserId: targetUserId,
        targetTweetId: targetTweetId,
        reportDescription: reportDescription,
      );

      // リポジトリ経由で報告を送信
      return await _reportRepository.createReport(report);
    } catch (e) {
      if (e is AppException) rethrow;
      throw DataSaveException(
        message: '報告の送信に失敗しました',
        originalError: e,
      );
    }
  }
}