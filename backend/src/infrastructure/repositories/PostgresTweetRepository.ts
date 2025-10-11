import { db } from '../../config/database';
import { ITweetRepository } from '../../domain/repositories/ITweetRepository';
import { Tweet, TweetMedia } from '../../models/types';
import { ApiError } from '../../middleware/error';
// import { StoragePathService } from '../../domain/services/StoragePathService'; // 2025.09.15 リファクタリング予定
import logger from '../../utils/logger';

/**
 * PostgreSQL Tweet リポジトリ実装
 *
 * クリーンアーキテクチャにおける位置づけ:
 * - Infrastructure 層の具体実装
 * - ITweetRepositoryインターフェースの実装
 * - PostgreSQLデータベースとの具体的な通信を担当
 */
export class PostgresTweetRepository implements ITweetRepository {
  async getAllTweets(limit: number = 20, cursor?: string, requestUserId?: string): Promise<any[]> {
    try {
      let query: string;
      let params: any[];

      // ブロックフィルタ条件を構築
      let blockFilterCondition = '';
      
      if (requestUserId) {
        const paramIndex = cursor ? 3 : 2; // cursor有:$3, cursor無:$2
        blockFilterCondition = `
          AND t.user_id NOT IN (
            SELECT blocked_user_id FROM user_blocks WHERE blocker_user_id = $${paramIndex}
            UNION
            SELECT blocker_user_id FROM user_blocks WHERE blocked_user_id = $${paramIndex}
          )`;
      }

      if (cursor) {
        query = `
          SELECT
            t.tweet_id,
            t.tweet_contents,
            t.visited_date,
            t.tweeted_date,
            t.liked_counts,
            t.movie_url,
            u.user_id,
            u.user_name,
            u.user_icon_url,
            g.gym_id,
            g.gym_name,
            g.prefecture,
            COALESCE(
              (SELECT json_agg(media_url)
               FROM tweet_media
               WHERE tweet_id = t.tweet_id), '[]'
            ) AS media_urls
          FROM tweets AS t
          INNER JOIN users AS u ON t.user_id = u.user_id
          INNER JOIN gyms AS g ON t.gym_id = g.gym_id
          WHERE t.tweeted_date < $1 ${blockFilterCondition}
          ORDER BY t.tweeted_date DESC
          LIMIT $2`;
        params = requestUserId ? [cursor, limit, requestUserId] : [cursor, limit];
      } else {
        query = `
          SELECT
            t.tweet_id,
            t.tweet_contents,
            t.visited_date,
            t.tweeted_date,
            t.liked_counts,
            t.movie_url,
            u.user_id,
            u.user_name,
            u.user_icon_url,
            g.gym_id,
            g.gym_name,
            g.prefecture,
            COALESCE(
              (SELECT json_agg(media_url)
               FROM tweet_media
               WHERE tweet_id = t.tweet_id), '[]'
            ) AS media_urls
          FROM tweets AS t
          INNER JOIN users AS u ON t.user_id = u.user_id
          INNER JOIN gyms AS g ON t.gym_id = g.gym_id
          WHERE 1 = 1 ${blockFilterCondition}
          ORDER BY t.tweeted_date DESC
          LIMIT $1`;
        params = requestUserId ? [limit, requestUserId] : [limit];
      }

      const result = await db.query(query, params);
      return result;
    } catch (error) {
      logger.error('Error getting all tweets', { limit, cursor, error });
      throw new ApiError(500, 'Failed to get tweets');
    }
  }

  async getUserTweets(userId: string, limit: number = 20, cursor?: string): Promise<any[]> {
    try {
      let query: string;
      let params: any[];

      if (cursor) {
        query = `
          SELECT
            t.tweet_id,
            t.tweet_contents,
            t.visited_date,
            t.tweeted_date,
            t.liked_counts,
            t.movie_url,
            u.user_id,
            u.user_name,
            u.user_icon_url,
            g.gym_id,
            g.gym_name,
            g.prefecture,
            COALESCE(
              (SELECT json_agg(media_url)
               FROM tweet_media
               WHERE tweet_id = t.tweet_id), '[]'
            ) AS media_urls
          FROM tweets AS t
          INNER JOIN users AS u ON t.user_id = u.user_id
          INNER JOIN gyms AS g ON t.gym_id = g.gym_id
          WHERE t.user_id = $1 AND t.tweeted_date < $2
          ORDER BY t.tweeted_date DESC
          LIMIT $3`;
        params = [userId, cursor, limit];
      } else {
        query = `
          SELECT
            t.tweet_id,
            t.tweet_contents,
            t.visited_date,
            t.tweeted_date,
            t.liked_counts,
            t.movie_url,
            u.user_id,
            u.user_name,
            u.user_icon_url,
            g.gym_id,
            g.gym_name,
            g.prefecture,
            COALESCE(
              (SELECT json_agg(media_url)
               FROM tweet_media
               WHERE tweet_id = t.tweet_id), '[]'
            ) AS media_urls
          FROM tweets AS t
          INNER JOIN users AS u ON t.user_id = u.user_id
          INNER JOIN gyms AS g ON t.gym_id = g.gym_id
          WHERE t.user_id = $1
          ORDER BY t.tweeted_date DESC
          LIMIT $2`;
        params = [userId, limit];
      }

      const result = await db.query(query, params);
      return result;
    } catch (error) {
      logger.error('Error getting user tweets', { userId, limit, cursor, error });
      throw new ApiError(500, 'Failed to get user tweets');
    }
  }

  async getTweetById(tweetId: number): Promise<any | null> {
    try {
      const result = await db.query(
        `SELECT
          t.tweet_id,
          t.tweet_contents,
          t.visited_date,
          t.tweeted_date,
          t.liked_counts,
          t.movie_url,
          u.user_id,
          u.user_name,
          u.user_icon_url,
          g.gym_id,
          g.gym_name,
          g.prefecture,
          COALESCE(
            (SELECT json_agg(media_url)
             FROM tweet_media
             WHERE tweet_id = t.tweet_id), '[]'
          ) AS media_urls
        FROM tweets AS t
        INNER JOIN users AS u ON t.user_id = u.user_id
        INNER JOIN gyms AS g ON t.gym_id = g.gym_id
        WHERE t.tweet_id = $1`,
        [tweetId]
      );

      return result.length > 0 ? result[0] : null;
    } catch (error) {
      logger.error('Error getting tweet by ID', { tweetId, error });
      throw new ApiError(500, 'Failed to get tweet');
    }
  }

  async createTweet(tweetData: {
    user_id: string;
    gym_id: number;
    tweet_contents: string;
    visited_date?: Date;
    movie_url?: string;
    media_urls?: string[];
    media_metadata?: any[];
    post_uuid?: string;
  }): Promise<Tweet> {
    const client = await db.getClient();

    try {
      await client.query('BEGIN');

      // Create tweet
      const tweetResult = await client.query(
        `INSERT INTO tweets (user_id, gym_id, tweet_contents, visited_date, movie_url)
         VALUES ($1, $2, $3, $4, $5)
         RETURNING *`,
        [
          tweetData.user_id,
          tweetData.gym_id,
          tweetData.tweet_contents,
          tweetData.visited_date || null,
          tweetData.movie_url || null,
        ]
      );

      const newTweet = tweetResult.rows[0];

      // Add media if provided
      if (tweetData.media_urls && tweetData.media_urls.length > 0) {
        for (let i = 0; i < tweetData.media_urls.length; i++) {
          const mediaUrl = tweetData.media_urls[i];
          const metadata = tweetData.media_metadata?.[i];
          const storagePrefix = this.deriveStoragePrefixFromMediaUrl(mediaUrl);

          await client.query(
            `INSERT INTO tweet_media (tweet_id, media_url, media_type, storage_prefix, asset_uuid, mime_type)
             VALUES ($1, $2, $3, $4, $5, $6)`,
            [
              newTweet.tweet_id,
              mediaUrl,
              'image',
              storagePrefix,
              metadata?.asset_uuid || null,
              metadata?.mime_type || null,
            ]
          );
        }
      }

      await client.query('COMMIT');

      logger.info('Tweet created successfully', {
        tweetId: newTweet.tweet_id,
        userId: tweetData.user_id
      });

      return newTweet;
    } catch (error) {
      await client.query('ROLLBACK');
      logger.error('Error creating tweet', { tweetData, error });
      throw new ApiError(500, 'Failed to create tweet');
    } finally {
      client.release();
    }
  }

  async updateTweet(
    tweetId: number,
    userId: string,
    updateData: {
      tweet_contents?: string;
      visited_date?: Date;
      gym_id?: number;
      media_urls?: string[];
    }
  ): Promise<Tweet> {
    const client = await db.getClient();

    try {
      await client.query('BEGIN');

      // Check ownership
      const existingTweet = await client.query(
        'SELECT * FROM tweets WHERE tweet_id = $1',
        [tweetId]
      );

      if (existingTweet.rows.length === 0) {
        throw new ApiError(404, 'Tweet not found');
      }

      if (existingTweet.rows[0].user_id !== userId) {
        throw new ApiError(403, 'You can only update your own tweets');
      }

      // Update tweet basic fields
      const setParts: string[] = [];
      const values: any[] = [];
      let paramIndex = 1;

      if (updateData.tweet_contents !== undefined) {
        setParts.push(`tweet_contents = $${paramIndex}`);
        values.push(updateData.tweet_contents);
        paramIndex++;
      }

      if (updateData.visited_date !== undefined) {
        setParts.push(`visited_date = $${paramIndex}`);
        values.push(updateData.visited_date);
        paramIndex++;
      }

      if (updateData.gym_id !== undefined) {
        setParts.push(`gym_id = $${paramIndex}`);
        values.push(updateData.gym_id);
        paramIndex++;
      }

      // Update basic fields if there are changes
      if (setParts.length > 0) {
        values.push(tweetId);
        const updateQuery = `
          UPDATE tweets
          SET ${setParts.join(', ')}, updated_at = CURRENT_TIMESTAMP
          WHERE tweet_id = $${paramIndex}
        `;

        await client.query(updateQuery, values);
      }

      // Update media_urls if provided
      if (updateData.media_urls !== undefined) {
        // 既存メディアを削除
        await client.query('DELETE FROM tweet_media WHERE tweet_id = $1', [tweetId]);

        // 新しいメディアを追加
        if (updateData.media_urls.length > 0) {
          for (const mediaUrl of updateData.media_urls) {
            const storagePrefix = this.deriveStoragePrefixFromMediaUrl(mediaUrl);

            await client.query(
              `INSERT INTO tweet_media (tweet_id, media_url, media_type, storage_prefix)
               VALUES ($1, $2, $3, $4)`,
              [tweetId, mediaUrl, 'image', storagePrefix]
            );
          }
        }

        // Update timestamp when media is changed
        await client.query(
          'UPDATE tweets SET updated_at = CURRENT_TIMESTAMP WHERE tweet_id = $1',
          [tweetId]
        );
      }

      // Always return the latest complete record
      const latestTweet = await client.query('SELECT * FROM tweets WHERE tweet_id = $1', [tweetId]);
      await client.query('COMMIT');

      logger.info('Tweet updated successfully', { tweetId, userId });
      return latestTweet.rows[0];
    } catch (error) {
      await client.query('ROLLBACK');
      if (error instanceof ApiError) throw error;
      logger.error('Error updating tweet', { tweetId, userId, updateData, error });
      throw new ApiError(500, 'Failed to update tweet');
    } finally {
      client.release();
    }
  }

  async addTweetMedia(
    tweetId: number,
    userId: string,
    mediaData: {
      media_url: string;
      media_type: string;
    }
  ): Promise<void> {
    try {
      // Check ownership
      const existingTweet = await db.query(
        'SELECT user_id FROM tweets WHERE tweet_id = $1',
        [tweetId]
      );

      if (existingTweet.length === 0) {
        throw new ApiError(404, 'Tweet not found');
      }

      if (existingTweet[0].user_id !== userId) {
        throw new ApiError(403, 'You can only add media to your own tweets');
      }

      // Get current max display order
      const maxOrderResult = await db.query(
        'SELECT COALESCE(MAX(display_order), -1) as max_order FROM tweet_media WHERE tweet_id = $1',
        [tweetId]
      );

      const nextOrder = maxOrderResult[0].max_order + 1;
      const storagePrefix = this.deriveStoragePrefixFromMediaUrl(mediaData.media_url);

      // Add media
      await db.query(
        `INSERT INTO tweet_media (tweet_id, media_url, media_type, display_order, storage_prefix)
         VALUES ($1, $2, $3, $4, $5)`,
        [tweetId, mediaData.media_url, mediaData.media_type, nextOrder, storagePrefix]
      );

      logger.info('Media added to tweet successfully', { tweetId, userId, mediaUrl: mediaData.media_url });
    } catch (error) {
      if (error instanceof ApiError) throw error;
      logger.error('Error adding media to tweet', { tweetId, userId, mediaData, error });
      throw new ApiError(500, 'Failed to add media to tweet');
    }
  }

  async deleteTweetMedia(tweetId: number, userId: string, mediaUrl: string): Promise<void> {
    try {
      // Check ownership
      const existingTweet = await db.query(
        'SELECT user_id FROM tweets WHERE tweet_id = $1',
        [tweetId]
      );

      if (existingTweet.length === 0) {
        throw new ApiError(404, 'Tweet not found');
      }

      if (existingTweet[0].user_id !== userId) {
        throw new ApiError(403, 'You can only delete media from your own tweets');
      }

      // Delete media
      const result = await db.query(
        'DELETE FROM tweet_media WHERE tweet_id = $1 AND media_url = $2',
        [tweetId, mediaUrl]
      );

      if (result.length === 0) {
        throw new ApiError(404, 'Media not found in tweet');
      }

      logger.info('Media deleted from tweet successfully', { tweetId, userId, mediaUrl });
    } catch (error) {
      if (error instanceof ApiError) throw error;
      logger.error('Error deleting media from tweet', { tweetId, userId, mediaUrl, error });
      throw new ApiError(500, 'Failed to delete media from tweet');
    }
  }

  private deriveStoragePrefixFromMediaUrl(mediaUrl: string): string | null {
    try {
      if (!mediaUrl || !mediaUrl.includes('storage.googleapis.com')) {
        return null;
      }

      const urlObj = new URL(mediaUrl);
      const pathParts = urlObj.pathname.split('/').filter(part => part.length > 0);

      if (pathParts.length < 3) {
        return null;
      }

      // Remove bucket name (first) and filename (last)
      const prefixParts = pathParts.slice(1, -1);
      return prefixParts.join('/');
    } catch (error) {
      logger.warn('Failed to derive storage prefix from media URL', { mediaUrl, error });
      return null;
    }
  }


  async deleteTweet(tweetId: number, userId: string): Promise<void> {
    try {
      // 権限チェックと削除を同時に実行（競合状態を防ぐため）
      const result = await db.query(
        'DELETE FROM tweets WHERE tweet_id = $1 AND user_id = $2 RETURNING *',
        [tweetId, userId]
      );

      if (result.length === 0) {
        // ツイートが存在しないか、権限がない場合
        // より詳細なエラー判定のため、存在確認
        const existingTweet = await db.query(
          'SELECT user_id FROM tweets WHERE tweet_id = $1',
          [tweetId]
        );

        if (existingTweet.length === 0) {
          throw new ApiError(404, 'Tweet not found');
        } else {
          throw new ApiError(403, 'You can only delete your own tweets');
        }
      }

      logger.info('Tweet deleted from database', { tweetId, userId });
    } catch (error) {
      if (error instanceof ApiError) throw error;
      logger.error('Error deleting tweet from database', { tweetId, userId, error });
      throw new ApiError(500, 'Failed to delete tweet');
    }
  }

  async getTweetMediaUrls(tweetId: number): Promise<string[]> {
    try {
      const mediaRows = await db.query(
        `SELECT storage_prefix, media_url
         FROM tweet_media
         WHERE tweet_id = $1`,
        [tweetId]
      );

      // storage_prefixを収集（nullの場合はURLから導出）
      const prefixes: string[] = [];
      for (const row of mediaRows) {
        if (row.storage_prefix) {
          // 既存のstorage_prefixを使用
          prefixes.push(row.storage_prefix);
        } else if (row.media_url) {
          // 後方互換性: URLからプレフィックスを導出
          const derivedPrefix = this.derivePrefixFromUrl(row.media_url);
          if (derivedPrefix) {
            prefixes.push(derivedPrefix);
          }
        }
      }

      // 重複削除
      return Array.from(new Set(prefixes)).filter(Boolean);
    } catch (error) {
      logger.error('Error getting tweet media URLs', { tweetId, error });
      throw new ApiError(500, 'Failed to get tweet media URLs');
    }
  }


  /**
   * メディアURLからストレージプレフィックスを導出
   * TweetServiceから移動してきたメソッド
   */
  private derivePrefixFromUrl(url: string): string | null {
    try {
      const urlObj = new URL(url);
      const pathParts = urlObj.pathname.split('/').filter(part => part.length > 0);

      // pathParts: [bucket, v1, public, users, userId, posts, yyyy, mm, postUuid, assetUuid, original.jpeg]
      // バケット名を除外し、ファイル名も除外してプレフィックスを構成
      if (pathParts.length < 3) {
        return null;
      }

      // バケット名（最初）とファイル名（最後）を除外
      const prefixParts = pathParts.slice(1, -1);
      return prefixParts.join('/');

    } catch (error) {
      logger.warn('Failed to derive prefix from URL', { url, error });
      return null;
    }
  }

}
