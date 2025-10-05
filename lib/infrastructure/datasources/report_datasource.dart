import '../services/api_client.dart';
import '../../domain/entities/report.dart';

/// 報告データソースクラス
/// 
/// 役割:
/// - 報告関連のAPI通信を担当
/// - 報告作成のPOSTリクエスト処理
/// 
/// クリーンアーキテクチャにおける位置づけ:
/// - Infrastructure層のデータソースコンポーネント
/// - 外部API（報告API）との通信窓口
/// - Repository実装から呼び出される
class ReportDataSource {
  final ApiClient _apiClient;

  /// コンストラクタ
  /// 
  /// [_apiClient] API通信クライアント
  ReportDataSource(this._apiClient);

  /// 報告を作成する
  /// 
  /// [report] 報告内容
  /// 
  /// 返り値:
  /// [bool] 成功時はtrue、失敗時はfalse
  /// 
  /// 処理フロー:
  /// 1. REST API: POST /api/reports で報告を送信
  /// 2. 認証が必要（ログイン状態のみ）
  /// 3. APIエラー時は例外を上位に伝播
  Future<bool> createReport(Report report) async {
    try {
      final response = await _apiClient.post(
        endpoint: '/reports',
        body: report.toCreateJson(),
      );
      
      // 成功判定（APIレスポンスに応じて調整可能）
      return response['success'] == true;
    } catch (e) {
      // エラーを上位に伝播
      rethrow;
    }
  }
}