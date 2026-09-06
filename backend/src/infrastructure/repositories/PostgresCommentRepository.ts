import { db } from '../../config/database';
import {
  ICommentRepository,
  CommentRow,
  CreatedComment,
} from '../../domain/repositories/ICommentRepository';
import { ApiError } from '../../middleware/error';
import logger from '../../utils/logger';

/**
 * PostgreSQL Comment リポジトリ実装（スレッド機能）
 *
 * クリーンアーキテクチャにおける位置づけ:
 * - Infrastructure 層の具体実装
 * - ICommentRepository インターフェースの実装
 *
 * 設計（social-spec.md「2. スレッド」）:
 * - 論理削除（is_deleted = true・content を空に）で木構造を壊さない
 * - tweets.comment_counts（非削除コメント数）を同一トランザクションで ±1
 * - ブロック関係のユーザーのコメントは一覧から除外（PostgresTweetRepository の NOT IN パターン）
 */
export class PostgresCommentRepository implements ICommentRepository {
  /** 一覧・作成レスポンスで共通の SELECT 句（ユーザー名・返信先ユーザー名を JOIN で付ける） */
  private static readonly SELECT_COMMENT = `
    SELECT
      c.comment_id,
      c.tweet_id,
      c.user_id,
      u.user_name,
      u.user_icon_url,
      c.parent_comment_id,
      c.root_comment_id,
      c.reply_to_user_id,
      ru.user_name AS reply_to_user_name,
      CASE WHEN c.is_deleted THEN '' ELSE c.content END AS content,
      c.is_deleted,
      c.created_at
    FROM tweet_comments AS c
    INNER JOIN users AS u ON c.user_id = u.user_id
    LEFT JOIN users AS ru ON c.reply_to_user_id = ru.user_id`;

  async getComments(
    tweetId: number,
    limit: number = 50,
    cursor?: string,
    requestUserId?: string
  ): Promise<CommentRow[]> {
    try {
      const params: any[] = [tweetId];
      let where = 'WHERE c.tweet_id = $1';

      // カーソル: 前ページ最後の created_at より後（昇順ページング）。
      // JSON の created_at はミリ秒精度、DB はマイクロ秒精度なので、ミリ秒に丸めて比較する
      // （そのままだと前ページ最後の行がもう一度返ってくる）
      if (cursor) {
        params.push(cursor);
        where += ` AND date_trunc('milliseconds', c.created_at) > $${params.length}::timestamptz`;
      }

      // ブロック関係（どちらが相手をブロックしていても）のコメントは見せない
      if (requestUserId) {
        params.push(requestUserId);
        const idx = params.length;
        where += `
          AND c.user_id NOT IN (
            SELECT blocked_user_id FROM user_blocks WHERE blocker_user_id = $${idx}
            UNION
            SELECT blocker_user_id FROM user_blocks WHERE blocked_user_id = $${idx}
          )`;
      }

      params.push(limit);
      const query = `${PostgresCommentRepository.SELECT_COMMENT}
        ${where}
        ORDER BY c.created_at ASC, c.comment_id ASC
        LIMIT $${params.length}`;

      return await db.query<CommentRow>(query, params);
    } catch (error) {
      logger.error('Error getting comments', { tweetId, limit, cursor, error });
      throw new ApiError(500, 'Failed to get comments');
    }
  }

  async createComment(data: {
    tweetId: number;
    userId: string;
    content: string;
    parentCommentId?: number;
  }): Promise<CreatedComment> {
    const client = await db.getClient();

    try {
      await client.query('BEGIN');

      // 対象ツイートの存在確認（投稿者はイベント用）。行ロックでカウンタ更新を直列化
      const tweetResult = await client.query(
        'SELECT user_id FROM tweets WHERE tweet_id = $1 FOR UPDATE',
        [data.tweetId]
      );
      if (tweetResult.rows.length === 0) {
        throw new ApiError(404, 'Tweet not found');
      }
      const tweetOwnerUserId: string = tweetResult.rows[0].user_id;

      // 親コメントがあれば root / reply_to を導出（親は同じツイートのものに限る）
      let rootCommentId: number | null = null;
      let replyToUserId: string | null = null;
      let parentCommentOwnerUserId: string | undefined;

      if (data.parentCommentId !== undefined && data.parentCommentId !== null) {
        const parentResult = await client.query(
          `SELECT comment_id, user_id, root_comment_id, is_deleted
           FROM tweet_comments
           WHERE comment_id = $1 AND tweet_id = $2`,
          [data.parentCommentId, data.tweetId]
        );
        if (parentResult.rows.length === 0) {
          throw new ApiError(404, 'Parent comment not found');
        }
        const parent = parentResult.rows[0];
        if (parent.is_deleted) {
          throw new ApiError(400, 'Parent comment has been deleted');
        }
        rootCommentId = parent.root_comment_id ?? parent.comment_id;
        replyToUserId = parent.user_id;
        parentCommentOwnerUserId = parent.user_id;
      }

      const insertResult = await client.query(
        `INSERT INTO tweet_comments
           (tweet_id, user_id, parent_comment_id, root_comment_id, reply_to_user_id, content)
         VALUES ($1, $2, $3, $4, $5, $6)
         RETURNING comment_id`,
        [
          data.tweetId,
          data.userId,
          data.parentCommentId ?? null,
          rootCommentId,
          replyToUserId,
          data.content,
        ]
      );
      const commentId: number = insertResult.rows[0].comment_id;

      // 非正規化カウンタ +1（同一トランザクション）
      await client.query(
        'UPDATE tweets SET comment_counts = comment_counts + 1 WHERE tweet_id = $1',
        [data.tweetId]
      );

      // レスポンス用にユーザー名等を JOIN した形で読み直す
      const rowResult = await client.query(
        `${PostgresCommentRepository.SELECT_COMMENT} WHERE c.comment_id = $1`,
        [commentId]
      );

      await client.query('COMMIT');

      logger.info('Comment created successfully', {
        commentId,
        tweetId: data.tweetId,
        userId: data.userId,
        parentCommentId: data.parentCommentId ?? null,
      });

      return {
        comment: rowResult.rows[0] as CommentRow,
        tweetOwnerUserId,
        parentCommentOwnerUserId,
      };
    } catch (error) {
      await client.query('ROLLBACK');
      if (error instanceof ApiError) throw error;
      logger.error('Error creating comment', { data, error });
      throw new ApiError(500, 'Failed to create comment');
    } finally {
      client.release();
    }
  }

  async softDeleteComment(
    commentId: number,
    requestUserId: string
  ): Promise<{ comment_id: number; is_deleted: true }> {
    const client = await db.getClient();

    try {
      await client.query('BEGIN');

      const existing = await client.query(
        `SELECT c.user_id, c.tweet_id, c.is_deleted, t.user_id AS tweet_owner_user_id
         FROM tweet_comments AS c
         INNER JOIN tweets AS t ON t.tweet_id = c.tweet_id
         WHERE c.comment_id = $1
         FOR UPDATE OF c`,
        [commentId]
      );
      if (existing.rows.length === 0) {
        throw new ApiError(404, 'Comment not found');
      }
      const row = existing.rows[0];

      // コメント本人 または そのツイートの投稿者だけが削除できる
      if (row.user_id !== requestUserId && row.tweet_owner_user_id !== requestUserId) {
        throw new ApiError(403, 'You can only delete your own comments or comments on your own tweets');
      }

      // 既に削除済みなら何もしない（カウンタも動かさない）
      if (!row.is_deleted) {
        await client.query(
          `UPDATE tweet_comments
           SET is_deleted = true, content = '', deleted_at = now(), updated_at = now()
           WHERE comment_id = $1`,
          [commentId]
        );
        await client.query(
          'UPDATE tweets SET comment_counts = GREATEST(comment_counts - 1, 0) WHERE tweet_id = $1',
          [row.tweet_id]
        );
      }

      await client.query('COMMIT');

      logger.info('Comment soft-deleted', {
        commentId,
        tweetId: row.tweet_id,
        requestUserId,
        alreadyDeleted: row.is_deleted,
      });

      return { comment_id: commentId, is_deleted: true };
    } catch (error) {
      await client.query('ROLLBACK');
      if (error instanceof ApiError) throw error;
      logger.error('Error deleting comment', { commentId, requestUserId, error });
      throw new ApiError(500, 'Failed to delete comment');
    } finally {
      client.release();
    }
  }
}
