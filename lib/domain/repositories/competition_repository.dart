import '../entities/competition.dart';

/// コンペティションリポジトリ（Domain 層の約束）
///
/// 実装は infrastructure/repositories/competition_repository_impl.dart
abstract class CompetitionRepository {
  /// 開催中のコンペ一覧（ログイン時はホームジムのコンペが先頭）
  Future<List<Competition>> getActiveCompetitions();

  /// 自分が開催者のコンペ一覧（管理者でなければ空）
  Future<List<Competition>> getHostedCompetitions();

  /// 自分が参加中のコンペ一覧
  Future<List<Competition>> getJoinedCompetitions();

  /// 1 件取得
  Future<Competition> getCompetition(int competitionId);

  /// 開催（ジム管理者のみ）
  Future<Competition> createCompetition(CompetitionInput input);

  /// 編集（開催者のみ）
  Future<Competition> updateCompetition(int competitionId, CompetitionInput input);

  /// 参加（開催中のみ・冪等）
  Future<Competition> joinCompetition(int competitionId);

  /// 順位表
  Future<CompetitionLeaderboard> getLeaderboard(int competitionId);

  /// 完登を記録（completed=true）／取り消す（false）。更新後の完登済み課題番号を返す
  Future<Set<int>> setProblemCompleted(int competitionId, int problemNo, bool completed);
}
