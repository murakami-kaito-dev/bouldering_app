import '../../domain/entities/report.dart';
import '../../domain/repositories/report_repository.dart';
import '../datasources/report_datasource.dart';

/// 報告リポジトリ実装クラス
/// 
/// 役割:
/// - Domainレイヤーで定義されたReportRepositoryインタフェースの実装
/// - データソースとDomainレイヤー間の橋渡し
/// - 報告作成に関するビジネスロジック実装
/// 
/// クリーンアーキテクチャにおける位置づけ:
/// - Infrastructure層のRepository実装
/// - Domain層のRepository抽象クラスに依存（依存関係逆転の原則）
/// - UseCase層から使用される
class ReportRepositoryImpl implements ReportRepository {
  final ReportDataSource _dataSource;

  /// コンストラクタ
  /// 
  /// [_dataSource] 報告データソース
  ReportRepositoryImpl(this._dataSource);

  /// 報告を作成する
  /// 
  /// [report] 報告内容
  /// 
  /// 返り値:
  /// [bool] 成功時はtrue、失敗時はfalse
  /// 
  /// ビジネスルール:
  /// - ログイン済みユーザーのみ報告可能
  /// - 自分のツイートは報告不可（UI側でも制御）
  @override
  Future<bool> createReport(Report report) async {
    try {
      return await _dataSource.createReport(report);
    } catch (e) {
      throw Exception('報告の送信に失敗しました: $e');
    }
  }
}