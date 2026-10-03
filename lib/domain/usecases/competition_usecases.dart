import '../entities/competition.dart';
import '../exceptions/app_exceptions.dart';
import '../repositories/competition_repository.dart';

/// コンペ一覧の種類
enum CompetitionListKind { active, hosted, joined }

/// コンペ一覧取得（開催中／自分が開催／参加中）
class GetCompetitionsUseCase {
  final CompetitionRepository _repository;

  GetCompetitionsUseCase(this._repository);

  Future<List<Competition>> execute(CompetitionListKind kind) async {
    try {
      switch (kind) {
        case CompetitionListKind.active:
          return await _repository.getActiveCompetitions();
        case CompetitionListKind.hosted:
          return await _repository.getHostedCompetitions();
        case CompetitionListKind.joined:
          return await _repository.getJoinedCompetitions();
      }
    } catch (e) {
      throw DataFetchException(
        message: 'コンペの取得に失敗しました',
        originalError: e,
      );
    }
  }
}

/// コンペ 1 件取得
class GetCompetitionUseCase {
  final CompetitionRepository _repository;

  GetCompetitionUseCase(this._repository);

  Future<Competition> execute(int competitionId) async {
    try {
      return await _repository.getCompetition(competitionId);
    } catch (e) {
      throw DataFetchException(
        message: 'コンペの取得に失敗しました',
        originalError: e,
      );
    }
  }
}

/// 開催（ジム管理者のみ）
///
/// 期間・課題範囲の整合性はここで先に確かめる（サーバーでも同じ検査をする）
class CreateCompetitionUseCase {
  final CompetitionRepository _repository;

  CreateCompetitionUseCase(this._repository);

  Future<Competition> execute(CompetitionInput input) async {
    _validate(input);
    try {
      return await _repository.createCompetition(input);
    } catch (e) {
      throw DataSaveException(
        message: 'コンペの開催に失敗しました',
        originalError: e,
      );
    }
  }
}

/// 編集（開催者のみ）
class UpdateCompetitionUseCase {
  final CompetitionRepository _repository;

  UpdateCompetitionUseCase(this._repository);

  Future<Competition> execute(int competitionId, CompetitionInput input) async {
    _validate(input);
    try {
      return await _repository.updateCompetition(competitionId, input);
    } catch (e) {
      throw DataSaveException(
        message: 'コンペの更新に失敗しました',
        originalError: e,
      );
    }
  }
}

/// 参加（開催中のみ）
class JoinCompetitionUseCase {
  final CompetitionRepository _repository;

  JoinCompetitionUseCase(this._repository);

  Future<Competition> execute(int competitionId) async {
    try {
      return await _repository.joinCompetition(competitionId);
    } catch (e) {
      throw DataSaveException(
        message: 'コンペへの参加に失敗しました',
        originalError: e,
      );
    }
  }
}

/// 順位表取得
class GetLeaderboardUseCase {
  final CompetitionRepository _repository;

  GetLeaderboardUseCase(this._repository);

  Future<CompetitionLeaderboard> execute(int competitionId) async {
    try {
      return await _repository.getLeaderboard(competitionId);
    } catch (e) {
      throw DataFetchException(
        message: '順位表の取得に失敗しました',
        originalError: e,
      );
    }
  }
}

/// 完登の記録／取り消し（参加者のみ・開催中のみ）
class SetProblemCompletedUseCase {
  final CompetitionRepository _repository;

  SetProblemCompletedUseCase(this._repository);

  Future<Set<int>> execute(int competitionId, int problemNo, bool completed) async {
    try {
      return await _repository.setProblemCompleted(competitionId, problemNo, completed);
    } catch (e) {
      throw DataSaveException(
        message: '完登の記録に失敗しました',
        originalError: e,
      );
    }
  }
}

/// 開催・編集の入力検査（画面でも同じ条件で案内する）
void _validate(CompetitionInput input) {
  final errors = <String, String>{};
  if (input.endDate.isBefore(input.startDate)) {
    errors['period'] = '終了日は開始日以降にしてください';
  }
  if (input.problemFrom < 1) {
    errors['problemFrom'] = '課題番号は 1 以上にしてください';
  }
  if (input.problemTo < input.problemFrom) {
    errors['problemTo'] = '終わりの課題番号は始まりの番号以上にしてください';
  }
  if (input.problemCount > 300) {
    errors['problemTo'] = '課題数は 300 までにしてください';
  }
  if (input.entryFeeYen < 0) {
    errors['fee'] = '参加料は 0 円以上にしてください';
  }
  if (errors.isNotEmpty) {
    throw ValidationException(message: '入力内容を確認してください', errors: errors);
  }
}
