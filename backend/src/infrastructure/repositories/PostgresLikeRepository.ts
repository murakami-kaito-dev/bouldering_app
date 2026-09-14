import { db } from '../../config/database';
import { ILikeRepository, LikeResult, UnlikeResult } from '../../domain/repositories/ILikeRepository';
import { ApiError } from '../../middleware/error';
import logger from '../../utils/logger';

/**
 * PostgreSQL いいねリポジトリ実装
 *
 * クリーンアーキテクチャにおける位置づけ:
 * - Infrastructure 層の具体実装
 * - ILikeRepository インターフェースの実装
 * - tweet_likes と tweets.liked_counts（非正規化カウンタ）を同一トランザクションで更新する
 *
 * 同時実行対策:
 * - 先に対象ツイート行を FOR UPDATE でロックし、同じツイートへの同時いいねでカウンタが
 *   ずれないようにする（ロックはトランザクション終了で解放される）
 */
export class PostgresLikeRepository implements ILikeRepository {
  async like(tweetId: number, userId: string): Promise<LikeResult> {
    const client = await db.getClient();

    try {
      await client.query('BEGIN');

      const tweetRows = await client.query(
        'SELECT user_id, liked_counts FROM tweets WHERE tweet_id = $1 FOR UPDATE',
        [tweetId]
      );

      if (tweetRows.rows.length === 0) {
        throw new ApiError(404, 'Tweet not found');
      }

      const tweetOwnerUserId: string = tweetRows.rows[0].user_id;
      let likedCount: number = tweetRows.rows[0].liked_counts ?? 0;

      // 冪等: 既にいいね済みなら何も挿入されない（rowCount = 0）
      const insertResult = await client.query(
        `INSERT INTO tweet_likes (user_id, tweet_id)
         VALUES ($1, $2)
         ON CONFLICT (user_id, tweet_id) DO NOTHING`,
        [userId, tweetId]
      );
      const inserted = (insertResult.rowCount ?? 0) > 0;

      if (inserted) {
        const updated = await client.query(
          `UPDATE tweets
           SET liked_counts = liked_counts + 1
           WHERE tweet_id = $1
           RETURNING liked_counts`,
          [tweetId]
        );
        likedCount = updated.rows[0].liked_counts;
      }

      await client.query('COMMIT');

      return { inserted, likedCount, tweetOwnerUserId };
    } catch (error) {
      await client.query('ROLLBACK');
      if (error instanceof ApiError) throw error;
      logger.error('Error liking tweet', { tweetId, userId, error });
      throw new ApiError(500, 'Failed to like tweet');
    } finally {
      client.release();
    }
  }

  async unlike(tweetId: number, userId: string): Promise<UnlikeResult> {
    const client = await db.getClient();

    try {
      await client.query('BEGIN');

      const tweetRows = await client.query(
        'SELECT liked_counts FROM tweets WHERE tweet_id = $1 FOR UPDATE',
        [tweetId]
      );

      if (tweetRows.rows.length === 0) {
        throw new ApiError(404, 'Tweet not found');
      }

      let likedCount: number = tweetRows.rows[0].liked_counts ?? 0;

      // 冪等: 元々いいねが無ければ何も削除されない（rowCount = 0）
      const deleteResult = await client.query(
        'DELETE FROM tweet_likes WHERE user_id = $1 AND tweet_id = $2',
        [userId, tweetId]
      );
      const deleted = (deleteResult.rowCount ?? 0) > 0;

      if (deleted) {
        // 過去データとの整合が崩れていても 0 未満にはしない
        const updated = await client.query(
          `UPDATE tweets
           SET liked_counts = GREATEST(liked_counts - 1, 0)
           WHERE tweet_id = $1
           RETURNING liked_counts`,
          [tweetId]
        );
        likedCount = updated.rows[0].liked_counts;
      }

      await client.query('COMMIT');

      return { deleted, likedCount };
    } catch (error) {
      await client.query('ROLLBACK');
      if (error instanceof ApiError) throw error;
      logger.error('Error unliking tweet', { tweetId, userId, error });
      throw new ApiError(500, 'Failed to unlike tweet');
    } finally {
      client.release();
    }
  }
}
