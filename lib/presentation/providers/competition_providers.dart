import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/competition.dart';
import '../../domain/exceptions/app_exceptions.dart';
import '../../domain/usecases/competition_usecases.dart';
import '../../infrastructure/datasources/competition_datasource.dart';
import 'dependency_injection.dart';

/// コンペティションの状態管理（デモ機能）
///
/// 役割:
/// - 一覧・詳細・順位表は FutureProvider（autoDispose）で取得し、画面は AsyncValue を表示する
/// - 参加・開催・編集・完登記録は [CompetitionActions] が UseCase を呼び、関係する Provider を
///   invalidate して画面を最新にする
///
/// クリーンアーキテクチャにおける位置づけ:
/// - Presentation 層の状態管理。UseCase 経由でのみデータに触る

/// 開催中のコンペ一覧（ログイン時はホームジムのコンペが先頭）
final activeCompetitionsProvider =
    FutureProvider.autoDispose<List<Competition>>((ref) {
  return ref.read(getCompetitionsUseCaseProvider).execute(CompetitionListKind.active);
});

/// 自分が開催者のコンペ一覧
final hostedCompetitionsProvider =
    FutureProvider.autoDispose<List<Competition>>((ref) {
  return ref.read(getCompetitionsUseCaseProvider).execute(CompetitionListKind.hosted);
});

/// 自分が参加中のコンペ一覧
final joinedCompetitionsProvider =
    FutureProvider.autoDispose<List<Competition>>((ref) {
  return ref.read(getCompetitionsUseCaseProvider).execute(CompetitionListKind.joined);
});

/// コンペ 1 件
final competitionDetailProvider =
    FutureProvider.autoDispose.family<Competition, int>((ref, competitionId) {
  return ref.read(getCompetitionUseCaseProvider).execute(competitionId);
});

/// 順位表
final competitionLeaderboardProvider =
    FutureProvider.autoDispose.family<CompetitionLeaderboard, int>((ref, competitionId) {
  return ref.read(getLeaderboardUseCaseProvider).execute(competitionId);
});

/// 更新系の操作（成功後に関係する Provider を取り直す）
class CompetitionActions {
  CompetitionActions(this._ref);

  final Ref _ref;

  /// 参加する
  Future<Competition> join(int competitionId) async {
    final result = await _ref.read(joinCompetitionUseCaseProvider).execute(competitionId);
    _ref.invalidate(activeCompetitionsProvider);
    _ref.invalidate(joinedCompetitionsProvider);
    _ref.invalidate(competitionDetailProvider(competitionId));
    _ref.invalidate(competitionLeaderboardProvider(competitionId));
    return result;
  }

  /// 開催する（ジム管理者のみ）
  Future<Competition> create(CompetitionInput input) async {
    final result = await _ref.read(createCompetitionUseCaseProvider).execute(input);
    _ref.invalidate(hostedCompetitionsProvider);
    _ref.invalidate(activeCompetitionsProvider);
    return result;
  }

  /// 編集する（開催者のみ）
  Future<Competition> update(int competitionId, CompetitionInput input) async {
    final result =
        await _ref.read(updateCompetitionUseCaseProvider).execute(competitionId, input);
    _ref.invalidate(hostedCompetitionsProvider);
    _ref.invalidate(activeCompetitionsProvider);
    _ref.invalidate(joinedCompetitionsProvider);
    _ref.invalidate(competitionDetailProvider(competitionId));
    _ref.invalidate(competitionLeaderboardProvider(competitionId));
    return result;
  }

  /// 完登を記録する／取り消す。更新後の完登済み課題番号を返す
  Future<Set<int>> setCompleted(int competitionId, int problemNo, bool completed) async {
    final result = await _ref
        .read(setProblemCompletedUseCaseProvider)
        .execute(competitionId, problemNo, completed);
    _ref.invalidate(competitionLeaderboardProvider(competitionId));
    return result;
  }
}

final competitionActionsProvider = Provider<CompetitionActions>((ref) {
  return CompetitionActions(ref);
});

/// 例外を利用者向けの文言にする（UseCase の例外 → API のステータス → 既定文）
String competitionErrorMessage(Object error) {
  if (error is ValidationException) {
    return error.errors.values.isNotEmpty ? error.errors.values.first : error.message;
  }
  if (error is AppException) {
    final origin = error.originalError;
    if (origin is CompetitionApiException) return origin.displayMessage;
    return error.message;
  }
  if (error is CompetitionApiException) return error.displayMessage;
  return '通信に失敗しました。時間をおいて再度お試しください';
}
