import '../entities/report.dart';

/// 報告リポジトリのインターフェース
/// 
/// 報告機能に関するデータ操作を定義
/// POSTのみ実装（GETは不要）
abstract class ReportRepository {
  /// ツイートの報告を作成する
  /// 
  /// [report] 報告内容
  /// 成功時はtrue、失敗時はfalseを返す
  Future<bool> createReport(Report report);
}