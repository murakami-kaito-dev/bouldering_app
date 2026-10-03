import {
  CompetitionInput,
  CompetitionRow,
  ICompetitionRepository,
  LeaderboardResult,
} from '../domain/repositories/ICompetitionRepository';
import { ApiError } from '../middleware/error';
import { config } from '../config/environment';
import { jstToday } from '../utils/jstTime';
import logger from '../utils/logger';

/** 完登の記録／取り消しの応答（`data` 部分） */
export interface CompletionResponse {
  problem_no: number;
  completed: boolean;
  /** 更新後の本人の完登済み課題番号（昇順） */
  completed_problems: number[];
}

/**
 * コンペティションサービス
 *
 * クリーンアーキテクチャにおける位置づけ:
 * - Application 層のサービス
 * - 開催（ジム管理者）・参加・完登記録・順位表の業務ルールを担う
 *
 * ビジネスルール:
 * - 開催できるのは users.managed_gym_id を持つユーザー（ジム管理者）だけ。開催ジムはその管理ジムに固定
 * - 編集できるのは開催者本人、または同じジムの管理者
 * - 参加・完登記録は「開催中（JST の今日が期間内）」のときだけ
 * - 完登の記録は参加者本人のみ。課題番号は範囲内のみ
 * - 参加料は保存するだけ（決済は未実装・参加は無料扱い）
 * - 時刻の基準は JST 固定（utils/jstTime）
 */
export class CompetitionService {
  constructor(private competitionRepository: ICompetitionRepository) {}

  /** 開催中のコンペ一覧（ログイン時はホームジムのコンペを先頭に） */
  async listActive(viewerUserId: string | null): Promise<CompetitionRow[]> {
    const homeGymId = viewerUserId ? await this.competitionRepository.findHomeGymId(viewerUserId) : null;
    return this.competitionRepository.findActive(jstToday(), viewerUserId, homeGymId);
  }

  /** 開催者として関わるコンペ一覧（管理者でないユーザーには空） */
  async listHosted(userId: string): Promise<CompetitionRow[]> {
    const managedGymId = await this.competitionRepository.findManagedGymId(userId);
    return this.competitionRepository.findHosted(jstToday(), userId, managedGymId);
  }

  /** 参加中のコンペ一覧 */
  async listJoined(userId: string): Promise<CompetitionRow[]> {
    return this.competitionRepository.findJoined(jstToday(), userId);
  }

  /** 1 件取得 */
  async getById(competitionId: number, viewerUserId: string | null): Promise<CompetitionRow> {
    const row = await this.competitionRepository.findById(competitionId, jstToday(), viewerUserId);
    if (!row) throw new ApiError(404, 'Competition not found', 'COMPETITION_NOT_FOUND');
    return row;
  }

  /** 開催（ジム管理者のみ。開催ジムは管理ジム） */
  async create(hostUserId: string, input: CompetitionInput): Promise<CompetitionRow> {
    const managedGymId = await this.competitionRepository.findManagedGymId(hostUserId);
    if (managedGymId == null) {
      throw new ApiError(403, 'Only gym managers can host a competition', 'NOT_GYM_MANAGER');
    }
    this.validateInput(input);

    const today = jstToday();
    if (input.end_date < today) {
      throw new ApiError(400, 'end_date must be today or later (JST)', 'PERIOD_ALREADY_ENDED');
    }

    const row = await this.competitionRepository.create(managedGymId, hostUserId, input, today);
    logger.info('Competition hosted via service', { competitionId: row.competition_id, hostUserId, gymId: managedGymId });
    return row;
  }

  /** 編集（開催者本人 または 同じジムの管理者） */
  async update(competitionId: number, userId: string, input: CompetitionInput): Promise<CompetitionRow> {
    const existing = await this.getById(competitionId, userId);
    if (!existing.is_host) {
      throw new ApiError(403, 'Only the host can edit this competition', 'NOT_HOST');
    }
    this.validateInput(input);
    const row = await this.competitionRepository.update(competitionId, input, jstToday(), userId);
    logger.info('Competition updated via service', { competitionId, userId });
    return row;
  }

  /** 参加（開催中のみ・冪等） */
  async join(competitionId: number, userId: string): Promise<CompetitionRow> {
    const competition = await this.getById(competitionId, userId);
    if (competition.status !== 'active') {
      throw new ApiError(409, 'Competition is not active', 'COMPETITION_NOT_ACTIVE');
    }
    const inserted = await this.competitionRepository.join(competitionId, userId);
    logger.info('Competition joined via service', { competitionId, userId, inserted });
    // 参加後の最新状態（is_joined / participant_count を含む）
    return this.getById(competitionId, userId);
  }

  /** 順位表 */
  async getLeaderboard(competitionId: number, viewerUserId: string | null): Promise<LeaderboardResult> {
    const result = await this.competitionRepository.getLeaderboard(competitionId, jstToday(), viewerUserId);
    if (!result) throw new ApiError(404, 'Competition not found', 'COMPETITION_NOT_FOUND');
    return result;
  }

  /** 完登を記録する／取り消す（参加者本人・開催中・範囲内の課題のみ） */
  async setCompleted(competitionId: number, userId: string, problemNo: number, completed: boolean): Promise<CompletionResponse> {
    const competition = await this.getById(competitionId, userId);
    if (!competition.is_joined) {
      throw new ApiError(403, 'Join the competition before recording', 'NOT_PARTICIPANT');
    }
    if (competition.status !== 'active') {
      throw new ApiError(409, 'Competition is not active', 'COMPETITION_NOT_ACTIVE');
    }
    if (problemNo < competition.problem_from || problemNo > competition.problem_to) {
      throw new ApiError(400, 'problem_no is out of range', 'PROBLEM_OUT_OF_RANGE');
    }

    if (completed) {
      await this.competitionRepository.markCompleted(competitionId, userId, problemNo);
    } else {
      await this.competitionRepository.unmarkCompleted(competitionId, userId, problemNo);
    }
    const completedProblems = await this.competitionRepository.findMyCompletedProblems(competitionId, userId);
    logger.info('Competition result updated via service', { competitionId, userId, problemNo, completed });
    return { problem_no: problemNo, completed, completed_problems: completedProblems };
  }

  /**
   * 【開発用】コンペを物理削除する（2026-10-03 ユーザー指示）
   *
   * - 仕様の「中止」機能ではない。開発中にテストデータを消すためのデバッグ用
   * - COMPETITION_DEBUG_DELETE_ENABLED=true の環境（dev Cloud Run）でだけ動く。prod では常に 403
   * - 削除できるのは開催者（本人 or 同じジムの管理者）のみ。参加・完登記録も一緒に消える（復元不可）
   */
  async debugDelete(competitionId: number, userId: string): Promise<void> {
    if (!config.competition.debugDeleteEnabled) {
      throw new ApiError(403, 'Competition delete is disabled in this environment', 'DEBUG_DELETE_DISABLED');
    }
    const existing = await this.getById(competitionId, userId);
    if (!existing.is_host) {
      throw new ApiError(403, 'Only the host can delete this competition', 'NOT_HOST');
    }
    const deleted = await this.competitionRepository.deleteById(competitionId);
    if (!deleted) throw new ApiError(404, 'Competition not found', 'COMPETITION_NOT_FOUND');
    logger.warn('[DEV ONLY] Competition deleted via service', { competitionId, userId });
  }

  /** 入力の整合性（express-validator で形式は見ているので、ここは組み合わせの検査） */
  private validateInput(input: CompetitionInput): void {
    if (input.end_date < input.start_date) {
      throw new ApiError(400, 'end_date must be on or after start_date', 'INVALID_PERIOD');
    }
    if (input.problem_to < input.problem_from) {
      throw new ApiError(400, 'problem_to must be >= problem_from', 'INVALID_PROBLEM_RANGE');
    }
    if (input.problem_to - input.problem_from + 1 > 300) {
      throw new ApiError(400, 'Too many problems (max 300)', 'INVALID_PROBLEM_RANGE');
    }
  }
}
