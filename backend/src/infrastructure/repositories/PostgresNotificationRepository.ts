import { db } from '../../config/database';
import {
  INotificationRepository,
  NotificationRow,
} from '../../domain/repositories/INotificationRepository';
import { ApiError } from '../../middleware/error';
import logger from '../../utils/logger';

/**
 * PostgreSQL 通知リポジトリ実装（Issue #81）
 *
 * クリーンアーキテクチャにおける位置づけ:
 * - Infrastructure 層の具体実装
 * - INotificationRepository インターフェースの実装
 *
 * いいねの集約（social-spec.md「3. 通知」の『同じツイートに対する 24 時間以内のいいねを 1 行に』）:
 * - 「代表行から 24 時間」を厳密に追いかけると、ページ境界でグループが割れたり重複したりするので、
 *   **同じツイート × 日本時間の同じ日** を 1 グループとする決定的な区切りで実装する
 *   （グループ鍵がページングに依存しないため、カーソル＝代表行の created_at で重複も欠落も出ない）
 * - 代表行＝グループ内で最新の行。actors は新しい順に最大 6 人、actor_count は総数
 * - comment / reply は 1 行 = 1 グループ
 * - ブロック関係（どちら向きでも）のアクターの通知は一覧・未読数から除外する（PostgresTweetRepository の NOT IN パターン）
 */
export class PostgresNotificationRepository implements INotificationRepository {
  /**
   * 集約の元になる CTE。$1 = 受信者ユーザーID
   * group_key: like は 'like:<tweet_id>:<JST の日付>'、それ以外は 'one:<notification_id>'
   */
  private static readonly GROUPED_CTE = `
    WITH base AS (
      SELECT
        n.notification_id,
        n.actor_user_id,
        n.is_read,
        n.created_at,
        CASE
          WHEN n.type = 'like'
            THEN 'like:' || n.tweet_id::text || ':' || to_char(n.created_at AT TIME ZONE 'Asia/Tokyo', 'YYYY-MM-DD')
          ELSE 'one:' || n.notification_id::text
        END AS group_key
      FROM notifications AS n
      WHERE n.recipient_user_id = $1
        AND n.actor_user_id NOT IN (
          SELECT blocked_user_id FROM user_blocks WHERE blocker_user_id = $1
          UNION
          SELECT blocker_user_id FROM user_blocks WHERE blocked_user_id = $1
        )
    ),
    grouped AS (
      SELECT
        group_key,
        (array_agg(notification_id ORDER BY created_at DESC, notification_id DESC))[1] AS rep_id,
        max(created_at) AS rep_created_at,
        count(*)::int AS actor_count,
        bool_and(is_read) AS is_read,
        (array_agg(actor_user_id ORDER BY created_at DESC, notification_id DESC))[1:6] AS actor_ids
      FROM base
      GROUP BY group_key
    )`;

  async createLikeNotification(
    recipientUserId: string,
    actorUserId: string,
    tweetId: number
  ): Promise<boolean> {
    try {
      // 部分ユニーク索引 uq_notifications_like（type = 'like'）に対する冪等挿入
      const result = await db.query(
        `INSERT INTO notifications (recipient_user_id, actor_user_id, type, tweet_id)
         VALUES ($1, $2, 'like', $3)
         ON CONFLICT (recipient_user_id, actor_user_id, tweet_id) WHERE type = 'like' DO NOTHING
         RETURNING notification_id`,
        [recipientUserId, actorUserId, tweetId]
      );
      return result.length > 0;
    } catch (error) {
      logger.error('Error creating like notification', { recipientUserId, actorUserId, tweetId, error });
      throw new ApiError(500, 'Failed to create like notification');
    }
  }

  async deleteLikeNotification(actorUserId: string, tweetId: number): Promise<number> {
    try {
      const result = await db.query(
        `DELETE FROM notifications
         WHERE type = 'like' AND actor_user_id = $1 AND tweet_id = $2
         RETURNING notification_id`,
        [actorUserId, tweetId]
      );
      return result.length;
    } catch (error) {
      logger.error('Error deleting like notification', { actorUserId, tweetId, error });
      throw new ApiError(500, 'Failed to delete like notification');
    }
  }

  async createCommentNotification(
    recipientUserId: string,
    actorUserId: string,
    type: 'comment' | 'reply',
    tweetId: number,
    commentId: number
  ): Promise<void> {
    try {
      await db.query(
        `INSERT INTO notifications (recipient_user_id, actor_user_id, type, tweet_id, comment_id)
         VALUES ($1, $2, $3, $4, $5)`,
        [recipientUserId, actorUserId, type, tweetId, commentId]
      );
    } catch (error) {
      logger.error('Error creating comment notification', {
        recipientUserId, actorUserId, type, tweetId, commentId, error,
      });
      throw new ApiError(500, 'Failed to create comment notification');
    }
  }

  async hasBlockRelation(userIdA: string, userIdB: string): Promise<boolean> {
    try {
      const rows = await db.query(
        `SELECT 1 FROM user_blocks
         WHERE (blocker_user_id = $1 AND blocked_user_id = $2)
            OR (blocker_user_id = $2 AND blocked_user_id = $1)
         LIMIT 1`,
        [userIdA, userIdB]
      );
      return rows.length > 0;
    } catch (error) {
      logger.error('Error checking block relation', { userIdA, userIdB, error });
      throw new ApiError(500, 'Failed to check block relation');
    }
  }

  async listNotifications(
    recipientUserId: string,
    limit: number,
    cursor?: string
  ): Promise<NotificationRow[]> {
    try {
      // カーソルは JSON（ミリ秒精度）で返した created_at なので、DB 側もミリ秒に丸めて比較する
      const query = `${PostgresNotificationRepository.GROUPED_CTE}
        SELECT
          g.rep_id AS notification_id,
          n.type,
          g.actor_count,
          g.is_read,
          g.rep_created_at AS created_at,
          t.tweet_id,
          gy.gym_name,
          LEFT(COALESCE(t.tweet_contents, ''), 40) AS tweet_content_head,
          c.comment_id,
          CASE WHEN c.is_deleted THEN '' ELSE LEFT(COALESCE(c.content, ''), 40) END AS comment_content_head,
          COALESCE((
            SELECT json_agg(
              json_build_object(
                'user_id', u.user_id,
                'user_name', u.user_name,
                'user_icon_url', u.user_icon_url
              ) ORDER BY a.ord
            )
            FROM unnest(g.actor_ids) WITH ORDINALITY AS a(user_id, ord)
            INNER JOIN users AS u ON u.user_id = a.user_id
          ), '[]'::json) AS actors
        FROM grouped AS g
        INNER JOIN notifications AS n ON n.notification_id = g.rep_id
        LEFT JOIN tweets AS t ON t.tweet_id = n.tweet_id
        LEFT JOIN gyms AS gy ON gy.gym_id = t.gym_id
        LEFT JOIN tweet_comments AS c ON c.comment_id = n.comment_id
        WHERE ($2::timestamptz IS NULL OR date_trunc('milliseconds', g.rep_created_at) < $2::timestamptz)
        ORDER BY g.rep_created_at DESC, g.rep_id DESC
        LIMIT $3`;

      const rows = await db.query(query, [recipientUserId, cursor ?? null, limit]);

      return rows.map((r: any): NotificationRow => ({
        notification_id: Number(r.notification_id),
        type: r.type,
        actors: r.actors ?? [],
        actor_count: r.actor_count,
        tweet: r.tweet_id
          ? { tweet_id: r.tweet_id, gym_name: r.gym_name ?? null, content_head: r.tweet_content_head ?? '' }
          : null,
        comment: r.comment_id
          ? { comment_id: r.comment_id, content_head: r.comment_content_head ?? '' }
          : null,
        is_read: r.is_read,
        created_at: r.created_at,
      }));
    } catch (error) {
      logger.error('Error listing notifications', { recipientUserId, limit, cursor, error });
      throw new ApiError(500, 'Failed to get notifications');
    }
  }

  async countUnread(recipientUserId: string): Promise<number> {
    try {
      const rows = await db.query(
        `${PostgresNotificationRepository.GROUPED_CTE}
         SELECT count(*)::int AS count FROM grouped WHERE NOT is_read`,
        [recipientUserId]
      );
      return rows[0]?.count ?? 0;
    } catch (error) {
      logger.error('Error counting unread notifications', { recipientUserId, error });
      throw new ApiError(500, 'Failed to count unread notifications');
    }
  }

  async markRead(recipientUserId: string, upToId?: number): Promise<number> {
    try {
      const result = await db.query(
        `UPDATE notifications
         SET is_read = true
         WHERE recipient_user_id = $1
           AND is_read = false
           AND ($2::bigint IS NULL OR notification_id <= $2::bigint)
         RETURNING notification_id`,
        [recipientUserId, upToId ?? null]
      );
      return result.length;
    } catch (error) {
      logger.error('Error marking notifications read', { recipientUserId, upToId, error });
      throw new ApiError(500, 'Failed to mark notifications read');
    }
  }
}
