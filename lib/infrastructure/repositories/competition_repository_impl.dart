import '../../domain/entities/competition.dart';
import '../../domain/repositories/competition_repository.dart';
import '../datasources/competition_datasource.dart';

/// コンペティションリポジトリ実装
class CompetitionRepositoryImpl implements CompetitionRepository {
  final CompetitionDataSource _dataSource;

  CompetitionRepositoryImpl(this._dataSource);

  @override
  Future<List<Competition>> getActiveCompetitions() =>
      _dataSource.getActiveCompetitions();

  @override
  Future<List<Competition>> getHostedCompetitions() =>
      _dataSource.getHostedCompetitions();

  @override
  Future<List<Competition>> getJoinedCompetitions() =>
      _dataSource.getJoinedCompetitions();

  @override
  Future<Competition> getCompetition(int competitionId) =>
      _dataSource.getCompetition(competitionId);

  @override
  Future<Competition> createCompetition(CompetitionInput input) =>
      _dataSource.createCompetition(input);

  @override
  Future<Competition> updateCompetition(int competitionId, CompetitionInput input) =>
      _dataSource.updateCompetition(competitionId, input);

  @override
  Future<Competition> joinCompetition(int competitionId) =>
      _dataSource.joinCompetition(competitionId);

  @override
  Future<CompetitionLeaderboard> getLeaderboard(int competitionId) =>
      _dataSource.getLeaderboard(competitionId);

  @override
  Future<Set<int>> setProblemCompleted(int competitionId, int problemNo, bool completed) =>
      _dataSource.setProblemCompleted(competitionId, problemNo, completed);

  /// 【開発用】テストデータ掃除用の削除（dev 環境でのみ有効）
  @override
  Future<void> deleteCompetition(int competitionId) =>
      _dataSource.deleteCompetition(competitionId);
}
