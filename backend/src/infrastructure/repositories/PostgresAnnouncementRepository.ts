import { db } from '../../config/database';
import {
  IAnnouncementRepository,
  AnnouncementRow,
} from '../../domain/repositories/IAnnouncementRepository';
import { ApiError } from '../../middleware/error';
import logger from '../../utils/logger';

/**
 * PostgreSQL お知らせリポジトリ実装（Issue #81）
 *
 * クリーンアーキテクチャにおける位置づけ:
 * - Infrastructure 層の具体実装
 * - IAnnouncementRepository インターフェースの実装
 *
 * 対象: 公式（gym_id NULL）＋ 認証時は本人のホームジム（users.home_gym_id）と
 * イキタイジム（gym_favorites）のお知らせ。published_at が未来のもの（予約）は出さない
 */
export class PostgresAnnouncementRepository implements IAnnouncementRepository {
  async listAnnouncements(
    limit: number,
    cursor?: string,
    userId?: string
  ): Promise<AnnouncementRow[]> {
    try {
      const rows = await db.query<AnnouncementRow>(
        `SELECT
           a.announcement_id,
           a.gym_id,
           g.gym_name,
           a.title,
           a.body,
           a.image_url,
           a.link_url,
           a.published_at
         FROM announcements AS a
         LEFT JOIN gyms AS g ON g.gym_id = a.gym_id
         WHERE a.published_at <= now()
           AND (
             a.gym_id IS NULL
             OR (
               $1::text IS NOT NULL
               AND (
                 a.gym_id = (SELECT home_gym_id FROM users WHERE user_id = $1::text)
                 OR a.gym_id IN (SELECT gym_id FROM gym_favorites WHERE user_id = $1::text)
               )
             )
           )
           AND ($2::timestamptz IS NULL OR date_trunc('milliseconds', a.published_at) < $2::timestamptz)
         ORDER BY a.published_at DESC, a.announcement_id DESC
         LIMIT $3`,
        [userId ?? null, cursor ?? null, limit]
      );
      return rows;
    } catch (error) {
      logger.error('Error listing announcements', { limit, cursor, userId, error });
      throw new ApiError(500, 'Failed to get announcements');
    }
  }
}
