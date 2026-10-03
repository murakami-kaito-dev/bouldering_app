import { db } from '../../config/database';
import {
  CompetitionInput,
  CompetitionRow,
  ICompetitionRepository,
  LeaderboardEntryRow,
  LeaderboardResult,
} from '../../domain/repositories/ICompetitionRepository';
import { ApiError } from '../../middleware/error';
import logger from '../../utils/logger';

/**
 * PostgreSQL コンペティションリポジトリ実装
 *
 * クリーンアーキテクチャにおける位置づけ:
 * - Infrastructure 層の具体実装
 * - ICompetitionRepository インターフェースの実装
 * - competitions / competition_entries / competition_results と users.managed_gym_id を扱う
 *
 * 時刻の扱い:
 * - 開催状態（upcoming / active / ended）は、呼び出し側から受け取る JST の今日（'YYYY-MM-DD'）と
 *   DATE 列を比べて SQL 内で決める。DB サーバーの now() や端末時刻は使わない
 * - DATE 列は 'YYYY-MM-DD' 文字列のまま返る（config/database-supabase.ts の型パーサ設定）
 */
export class PostgresCompetitionRepository implements ICompetitionRepository {
  /**
   * コンペ 1 件分の SELECT（共通）。
   * $1 = today, $2 = viewerUserId（null 可）。呼び出し側は $3 以降を使う
   */
  private static readonly SELECT_ROW = `
    SELECT
      c.competition_id, c.gym_id, g.gym_name, g.prefecture,
      c.host_user_id, c.title, c.start_date, c.end_date,
      c.problem_from, c.problem_to, c.entry_fee_yen, c.created_at, c.updated_at,
      CASE
        WHEN c.start_date > $1::date THEN 'upcoming'
        WHEN c.end_date   < $1::date THEN 'ended'
        ELSE 'active'
      END AS status,
      (SELECT COUNT(*)::int FROM competition_entries e WHERE e.competition_id = c.competition_id) AS participant_count,
      ($2::text IS NOT NULL AND EXISTS (
        SELECT 1 FROM competition_entries e WHERE e.competition_id = c.competition_id AND e.user_id = $2::text
      )) AS is_joined,
      ($2::text IS NOT NULL AND (
        c.host_user_id = $2::text
        OR EXISTS (SELECT 1 FROM users u WHERE u.user_id = $2::text AND u.managed_gym_id = c.gym_id)
      )) AS is_host
    FROM competitions c
    JOIN gyms g ON g.gym_id = c.gym_id`;

  async findManagedGymId(userId: string): Promise<number | null> {
    try {
      const rows = await db.query<{ managed_gym_id: number | null }>(
        'SELECT managed_gym_id FROM users WHERE user_id = $1',
        [userId]
      );
      return rows[0]?.managed_gym_id ?? null;
    } catch (error) {
      logger.error('Error finding managed gym', { userId, error });
      throw new ApiError(500, 'Failed to find managed gym');
    }
  }

  async findHomeGymId(userId: string): Promise<number | null> {
    try {
      const rows = await db.query<{ home_gym_id: number | null }>(
        'SELECT home_gym_id FROM users WHERE user_id = $1',
        [userId]
      );
      return rows[0]?.home_gym_id ?? null;
    } catch (error) {
      logger.error('Error finding home gym', { userId, error });
      throw new ApiError(500, 'Failed to find home gym');
    }
  }

  async findActive(today: string, viewerUserId: string | null, homeGymId: number | null): Promise<CompetitionRow[]> {
    try {
      return await db.query<CompetitionRow>(
        `${PostgresCompetitionRepository.SELECT_ROW}
         WHERE c.start_date <= $1::date AND c.end_date >= $1::date
         ORDER BY (c.gym_id = $3::int) DESC NULLS LAST, c.end_date ASC, c.competition_id ASC`,
        [today, viewerUserId, homeGymId]
      );
    } catch (error) {
      logger.error('Error listing active competitions', { error });
      throw new ApiError(500, 'Failed to list competitions');
    }
  }

  async findHosted(today: string, userId: string, managedGymId: number | null): Promise<CompetitionRow[]> {
    try {
      return await db.query<CompetitionRow>(
        `${PostgresCompetitionRepository.SELECT_ROW}
         WHERE c.host_user_id = $2::text OR ($3::int IS NOT NULL AND c.gym_id = $3::int)
         ORDER BY
           CASE WHEN c.start_date <= $1::date AND c.end_date >= $1::date THEN 0
                WHEN c.start_date > $1::date THEN 1
                ELSE 2 END,
           c.start_date DESC, c.competition_id DESC`,
        [today, userId, managedGymId]
      );
    } catch (error) {
      logger.error('Error listing hosted competitions', { userId, error });
      throw new ApiError(500, 'Failed to list hosted competitions');
    }
  }

  async findJoined(today: string, userId: string): Promise<CompetitionRow[]> {
    try {
      return await db.query<CompetitionRow>(
        `${PostgresCompetitionRepository.SELECT_ROW}
         JOIN competition_entries me ON me.competition_id = c.competition_id AND me.user_id = $2::text
         ORDER BY
           CASE WHEN c.start_date <= $1::date AND c.end_date >= $1::date THEN 0
                WHEN c.start_date > $1::date THEN 1
                ELSE 2 END,
           c.end_date ASC, c.competition_id DESC`,
        [today, userId]
      );
    } catch (error) {
      logger.error('Error listing joined competitions', { userId, error });
      throw new ApiError(500, 'Failed to list joined competitions');
    }
  }

  async findById(competitionId: number, today: string, viewerUserId: string | null): Promise<CompetitionRow | null> {
    try {
      const rows = await db.query<CompetitionRow>(
        `${PostgresCompetitionRepository.SELECT_ROW} WHERE c.competition_id = $3`,
        [today, viewerUserId, competitionId]
      );
      return rows[0] ?? null;
    } catch (error) {
      logger.error('Error finding competition', { competitionId, error });
      throw new ApiError(500, 'Failed to find competition');
    }
  }

  async create(gymId: number, hostUserId: string, input: CompetitionInput, today: string): Promise<CompetitionRow> {
    try {
      const inserted = await db.query<{ competition_id: number }>(
        `INSERT INTO competitions (gym_id, host_user_id, title, start_date, end_date, problem_from, problem_to, entry_fee_yen)
         VALUES ($1, $2, $3, $4::date, $5::date, $6, $7, $8)
         RETURNING competition_id`,
        [gymId, hostUserId, input.title, input.start_date, input.end_date, input.problem_from, input.problem_to, input.entry_fee_yen]
      );
      const row = await this.findById(inserted[0].competition_id, today, hostUserId);
      if (!row) throw new ApiError(500, 'Failed to read created competition');
      logger.info('Competition created', { competitionId: row.competition_id, gymId, hostUserId });
      return row;
    } catch (error) {
      if (error instanceof ApiError) throw error;
      logger.error('Error creating competition', { gymId, hostUserId, input, error });
      throw new ApiError(500, 'Failed to create competition');
    }
  }

  async update(competitionId: number, input: CompetitionInput, today: string, viewerUserId: string): Promise<CompetitionRow> {
    try {
      const updated = await db.query<{ competition_id: number }>(
        `UPDATE competitions
         SET title = $2, start_date = $3::date, end_date = $4::date,
             problem_from = $5, problem_to = $6, entry_fee_yen = $7, updated_at = now()
         WHERE competition_id = $1
         RETURNING competition_id`,
        [competitionId, input.title, input.start_date, input.end_date, input.problem_from, input.problem_to, input.entry_fee_yen]
      );
      if (updated.length === 0) throw new ApiError(404, 'Competition not found');
      const row = await this.findById(competitionId, today, viewerUserId);
      if (!row) throw new ApiError(404, 'Competition not found');
      logger.info('Competition updated', { competitionId, viewerUserId });
      return row;
    } catch (error) {
      if (error instanceof ApiError) throw error;
      logger.error('Error updating competition', { competitionId, input, error });
      throw new ApiError(500, 'Failed to update competition');
    }
  }

  async join(competitionId: number, userId: string): Promise<boolean> {
    try {
      const rows = await db.query(
        `INSERT INTO competition_entries (competition_id, user_id)
         VALUES ($1, $2)
         ON CONFLICT (competition_id, user_id) DO NOTHING
         RETURNING competition_id`,
        [competitionId, userId]
      );
      return rows.length > 0;
    } catch (error) {
      logger.error('Error joining competition', { competitionId, userId, error });
      throw new ApiError(500, 'Failed to join competition');
    }
  }

  async isJoined(competitionId: number, userId: string): Promise<boolean> {
    try {
      const rows = await db.query(
        'SELECT 1 FROM competition_entries WHERE competition_id = $1 AND user_id = $2',
        [competitionId, userId]
      );
      return rows.length > 0;
    } catch (error) {
      logger.error('Error checking entry', { competitionId, userId, error });
      throw new ApiError(500, 'Failed to check entry');
    }
  }

  async getLeaderboard(competitionId: number, today: string, viewerUserId: string | null): Promise<LeaderboardResult | null> {
    const competition = await this.findById(competitionId, today, viewerUserId);
    if (!competition) return null;

    try {
      // 順位 = 完登数（期間中の課題範囲内の記録だけを数える）が多い順。同数は同順位（RANK）
      // 表示順は同順位内で「最後に完登した時刻が早い人」→「先に参加した人」
      const entries = await db.query<LeaderboardEntryRow & { last_completed_at: Date | null }>(
        `WITH counts AS (
           SELECT e.user_id, e.joined_at,
                  COUNT(r.problem_no)::int AS completed_count,
                  MAX(r.completed_at)      AS last_completed_at
           FROM competition_entries e
           JOIN competitions c ON c.competition_id = e.competition_id
           LEFT JOIN competition_results r
             ON r.competition_id = e.competition_id AND r.user_id = e.user_id
            AND r.problem_no BETWEEN c.problem_from AND c.problem_to
           WHERE e.competition_id = $1
           GROUP BY e.user_id, e.joined_at
         )
         SELECT
           RANK() OVER (ORDER BY cnt.completed_count DESC)::int AS rank,
           u.user_id, u.user_name, u.user_icon_url,
           cnt.completed_count,
           (u.user_id = $2::text) AS is_me,
           cnt.last_completed_at
         FROM counts cnt
         JOIN users u ON u.user_id = cnt.user_id
         ORDER BY cnt.completed_count DESC, cnt.last_completed_at ASC NULLS LAST, cnt.joined_at ASC, u.user_id ASC`,
        [competitionId, viewerUserId]
      );

      const me = entries.find((e) => e.is_me);
      const myCompleted = viewerUserId && me ? await this.findMyCompletedProblems(competitionId, viewerUserId) : [];

      return {
        competition,
        entries: entries.map(({ last_completed_at: _ignored, ...rest }) => rest),
        my_rank: me ? me.rank : null,
        my_completed_problems: myCompleted,
      };
    } catch (error) {
      logger.error('Error building leaderboard', { competitionId, error });
      throw new ApiError(500, 'Failed to build leaderboard');
    }
  }

  async markCompleted(competitionId: number, userId: string, problemNo: number): Promise<void> {
    try {
      await db.query(
        `INSERT INTO competition_results (competition_id, user_id, problem_no)
         VALUES ($1, $2, $3)
         ON CONFLICT (competition_id, user_id, problem_no) DO NOTHING`,
        [competitionId, userId, problemNo]
      );
    } catch (error) {
      logger.error('Error marking problem completed', { competitionId, userId, problemNo, error });
      throw new ApiError(500, 'Failed to record completion');
    }
  }

  async unmarkCompleted(competitionId: number, userId: string, problemNo: number): Promise<void> {
    try {
      await db.query(
        'DELETE FROM competition_results WHERE competition_id = $1 AND user_id = $2 AND problem_no = $3',
        [competitionId, userId, problemNo]
      );
    } catch (error) {
      logger.error('Error unmarking problem', { competitionId, userId, problemNo, error });
      throw new ApiError(500, 'Failed to remove completion');
    }
  }

  async findMyCompletedProblems(competitionId: number, userId: string): Promise<number[]> {
    try {
      const rows = await db.query<{ problem_no: number }>(
        `SELECT problem_no FROM competition_results
         WHERE competition_id = $1 AND user_id = $2
         ORDER BY problem_no ASC`,
        [competitionId, userId]
      );
      return rows.map((r) => r.problem_no);
    } catch (error) {
      logger.error('Error listing my completions', { competitionId, userId, error });
      throw new ApiError(500, 'Failed to list completions');
    }
  }
}
