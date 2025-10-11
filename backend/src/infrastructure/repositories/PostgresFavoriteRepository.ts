import { db } from '../../config/database';
import { IFavoriteRepository } from '../../domain/repositories/IFavoriteRepository';
import { FavoriteUserRelation, FavoriteGym } from '../../models/types';
import { ApiError } from '../../middleware/error';
import logger from '../../utils/logger';

/**
 * PostgreSQL お気に入りリポジトリ実装
 * 
 * クリーンアーキテクチャにおける位置づけ:
 * - Infrastructure 層の具体実装
 * - IFavoriteRepositoryインターフェースの実装
 * - PostgreSQLデータベースとの具体的な通信を担当
 */
export class PostgresFavoriteRepository implements IFavoriteRepository {
  async createUserFavorite(likerUserId: string, likeeUserId: string): Promise<FavoriteUserRelation> {
    try {
      const result = await db.query(
        `INSERT INTO user_favorites (liker_user_id, likee_user_id)
         VALUES ($1, $2)
         ON CONFLICT (liker_user_id, likee_user_id) DO NOTHING
         RETURNING *`,
        [likerUserId, likeeUserId]
      );

      if (result.length === 0) {
        // Already exists
        const existing = await db.query(
          `SELECT * FROM user_favorites 
           WHERE liker_user_id = $1 AND likee_user_id = $2`,
          [likerUserId, likeeUserId]
        );
        return existing[0];
      }

      logger.info('User favorite created', { likerUserId, likeeUserId });
      return result[0];
    } catch (error) {
      logger.error('Error creating user favorite', { likerUserId, likeeUserId, error });
      throw new ApiError(500, 'Failed to create user favorite');
    }
  }

  async deleteUserFavorite(likerUserId: string, likeeUserId: string): Promise<void> {
    try {
      const result = await db.query(
        `DELETE FROM user_favorites 
         WHERE liker_user_id = $1 AND likee_user_id = $2`,
        [likerUserId, likeeUserId]
      );

      // 🔥 重要：DELETEリクエストの冪等性を保つため、削除対象が存在しない場合もエラーとしない
      // お気に入りユーザー関係がすでに存在しない場合も成功として扱う（REST APIのベストプラクティス）
      // ⚠️ この部分を404エラーに戻してはいけない：ユーザーが連続で削除ボタンを押した際などに
      // 不要なエラー表示が発生してしまうため
      if (result.length === 0) {
        logger.info('User favorite relation already deleted or not found - treating as success for idempotency', { likerUserId, likeeUserId });
        return;
      }

      logger.info('User favorite deleted', { likerUserId, likeeUserId });
    } catch (error) {
      if (error instanceof ApiError) throw error;
      logger.error('Error deleting user favorite', { likerUserId, likeeUserId, error });
      throw new ApiError(500, 'Failed to delete user favorite');
    }
  }

  async checkUserFavorite(likerUserId: string, likeeUserId: string): Promise<boolean> {
    try {
      const result = await db.query(
        `SELECT 1 FROM user_favorites 
         WHERE liker_user_id = $1 AND likee_user_id = $2`,
        [likerUserId, likeeUserId]
      );
      return result.length > 0;
    } catch (error) {
      logger.error('Error checking user favorite', { likerUserId, likeeUserId, error });
      throw new ApiError(500, 'Failed to check user favorite');
    }
  }

  async getUserFavorites(userId: string): Promise<any[]> {
    try {
      const result = await db.query(
        `SELECT 
          u.user_id as likee_user_id, -- 🔥 重要：フロントエンド側でlikee_user_idフィールドを期待しているため、user_idをlikee_user_idとしてエイリアス設定
          u.user_name,
          u.user_icon_url,
          u.user_introduce,
          u.home_gym_id,
          uf.created_at as favorited_at
        FROM user_favorites uf
        INNER JOIN users u ON uf.likee_user_id = u.user_id
        WHERE uf.liker_user_id = $1
        ORDER BY uf.created_at DESC`,
        [userId]
      );
      return result;
    } catch (error) {
      logger.error('Error getting user favorites', { userId, error });
      throw new ApiError(500, 'Failed to get user favorites');
    }
  }

  async getUserFavoriteBy(userId: string): Promise<any[]> {
    try {
      const result = await db.query(
        `SELECT 
          u.user_id as liker_user_id, -- 🔥 重要：フロントエンド側でliker_user_idフィールドを期待しているため、user_idをliker_user_idとしてエイリアス設定（このエイリアスを削除してはならない）
          u.user_name,
          u.user_icon_url,
          u.user_introduce,
          u.home_gym_id,
          uf.created_at as favorited_at
        FROM user_favorites uf
        INNER JOIN users u ON uf.liker_user_id = u.user_id
        WHERE uf.likee_user_id = $1
        ORDER BY uf.created_at DESC`,
        [userId]
      );
      return result;
    } catch (error) {
      logger.error('Error getting user favorite by', { userId, error });
      throw new ApiError(500, 'Failed to get user favorite by');
    }
  }

  async createGymFavorite(userId: string, gymId: number): Promise<FavoriteGym> {
    try {
      const result = await db.query(
        `INSERT INTO gym_favorites (user_id, gym_id)
         VALUES ($1, $2)
         ON CONFLICT (user_id, gym_id) DO NOTHING
         RETURNING *`,
        [userId, gymId]
      );

      if (result.length === 0) {
        // Already exists
        const existing = await db.query(
          `SELECT * FROM gym_favorites 
           WHERE user_id = $1 AND gym_id = $2`,
          [userId, gymId]
        );
        return existing[0];
      }

      logger.info('Gym favorite created', { userId, gymId });
      return result[0];
    } catch (error) {
      logger.error('Error creating gym favorite', { userId, gymId, error });
      throw new ApiError(500, 'Failed to create gym favorite');
    }
  }

  async deleteGymFavorite(userId: string, gymId: number): Promise<void> {
    try {
      const result = await db.query(
        `DELETE FROM gym_favorites 
         WHERE user_id = $1 AND gym_id = $2`,
        [userId, gymId]
      );

      // 🔥 重要：DELETEリクエストの冪等性を保つため、削除対象が存在しない場合もエラーとしない
      // フロントエンドでは「削除済み」と「削除に失敗」を区別する必要がないため、
      // すでに削除されている場合も成功として扱う（REST APIのベストプラクティス）
      // ⚠️ この部分を404エラーに戻してはいけない：ユーザーが連続で削除ボタンを押した際などに
      // 不要なエラー表示が発生してしまうため
      if (result.length === 0) {
        logger.info('Gym favorite already deleted or not found - treating as success for idempotency', { userId, gymId });
        return;
      }

      logger.info('Gym favorite deleted', { userId, gymId });
    } catch (error) {
      if (error instanceof ApiError) throw error;
      logger.error('Error deleting gym favorite', { userId, gymId, error });
      throw new ApiError(500, 'Failed to delete gym favorite');
    }
  }

  async checkGymFavorite(userId: string, gymId: number): Promise<boolean> {
    try {
      const result = await db.query(
        `SELECT 1 FROM gym_favorites 
         WHERE user_id = $1 AND gym_id = $2`,
        [userId, gymId]
      );
      return result.length > 0;
    } catch (error) {
      logger.error('Error checking gym favorite', { userId, gymId, error });
      throw new ApiError(500, 'Failed to check gym favorite');
    }
  }

  async getUserFavoriteGyms(userId: string): Promise<any[]> {
    try {
      const result = await db.query(
        `SELECT 
          g.gym_id,
          g.gym_name,
          g.hp_link,
          g.prefecture,
          g.city,
          g.address_line,
          g.latitude,
          g.longitude,
          g.tel_no,
          g.fee,
          g.minimum_fee,
          g.equipment_rental_fee,
          COALESCE(COUNT(DISTINCT gf2.user_id), 0) as ikitai_count,
          COALESCE(COUNT(t.tweet_id), 0) as boul_count,
          g.is_bouldering_gym,
          g.is_lead_gym,
          g.is_speed_gym,
          gh.sun_open,
          gh.sun_close,
          gh.mon_open,
          gh.mon_close,
          gh.tue_open,
          gh.tue_close,
          gh.wed_open,
          gh.wed_close,
          gh.thu_open,
          gh.thu_close,
          gh.fri_open,
          gh.fri_close,
          gh.sat_open,
          gh.sat_close,
          gf.created_at as favorited_at
        FROM gym_favorites gf
        INNER JOIN gyms g ON gf.gym_id = g.gym_id
        LEFT JOIN gym_hours gh ON gh.gym_id = g.gym_id
        LEFT JOIN gym_favorites gf2 ON gf2.gym_id = g.gym_id
        LEFT JOIN tweets t ON g.gym_id = t.gym_id
        WHERE gf.user_id = $1
        GROUP BY g.gym_id, g.gym_name, g.hp_link, g.prefecture, g.city, g.address_line, 
                 g.latitude, g.longitude, g.tel_no, g.fee, g.minimum_fee, g.equipment_rental_fee,
                 g.is_bouldering_gym, g.is_lead_gym, g.is_speed_gym,
                 gh.sun_open, gh.sun_close, gh.mon_open, gh.mon_close,
                 gh.tue_open, gh.tue_close, gh.wed_open, gh.wed_close,
                 gh.thu_open, gh.thu_close, gh.fri_open, gh.fri_close,
                 gh.sat_open, gh.sat_close, gf.created_at
        ORDER BY gf.created_at DESC`,
        [userId]
      );
      return result;
    } catch (error) {
      logger.error('Error getting user favorite gyms', { userId, error });
      throw new ApiError(500, 'Failed to get user favorite gyms');
    }
  }

  async getGymFavoriteBy(gymId: number): Promise<any[]> {
    try {
      const result = await db.query(
        `SELECT 
          u.user_id,
          u.user_name,
          u.user_icon_url,
          gf.created_at as favorited_at
        FROM gym_favorites gf
        INNER JOIN users u ON gf.user_id = u.user_id
        WHERE gf.gym_id = $1
        ORDER BY gf.created_at DESC`,
        [gymId]
      );
      return result;
    } catch (error) {
      logger.error('Error getting gym favorite by', { gymId, error });
      throw new ApiError(500, 'Failed to get gym favorite by');
    }
  }

  async getFavoriteUsersTweets(userId: string, limit: number, cursor?: string): Promise<any[]> {
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
            u.user_name,
            u.user_icon_url,
            uf.likee_user_id AS user_id,
            g.gym_id,
            g.gym_name,
            g.prefecture,
            COALESCE(
              (SELECT json_agg(media_url)
               FROM tweet_media
               WHERE tweet_id = t.tweet_id), '[]'
            ) AS media_urls
          FROM
            tweets t
          INNER JOIN
            users u ON t.user_id = u.user_id
          INNER JOIN
            gyms g ON t.gym_id = g.gym_id
          INNER JOIN
            user_favorites uf ON uf.likee_user_id = t.user_id
          WHERE uf.liker_user_id = $1
            AND t.tweeted_date < $2
            AND t.user_id NOT IN (
              SELECT blocked_user_id FROM user_blocks WHERE blocker_user_id = $1
              UNION
              SELECT blocker_user_id FROM user_blocks WHERE blocked_user_id = $1
            )
          ORDER BY
            t.tweeted_date DESC
          LIMIT $3
        `;
        params = [userId, cursor, limit];
      } else {
        query = `
          SELECT
            t.tweet_id,
            u.user_name,
            u.user_icon_url,
            uf.likee_user_id AS user_id,
            t.visited_date,
            t.tweeted_date,
            t.tweet_contents,
            t.liked_counts,
            t.movie_url,
            g.gym_id,
            g.gym_name,
            g.prefecture,
            COALESCE(
              (SELECT json_agg(media_url)
               FROM tweet_media
               WHERE tweet_id = t.tweet_id), '[]'
            ) AS media_urls
          FROM
            tweets t
          INNER JOIN
            users u ON t.user_id = u.user_id
          INNER JOIN
            gyms g ON t.gym_id = g.gym_id
          INNER JOIN
            user_favorites uf ON uf.likee_user_id = t.user_id
          WHERE
            uf.liker_user_id = $1
            AND t.user_id NOT IN (
              SELECT blocked_user_id FROM user_blocks WHERE blocker_user_id = $1
              UNION
              SELECT blocker_user_id FROM user_blocks WHERE blocked_user_id = $1
            )
          ORDER BY
            t.tweeted_date DESC
          LIMIT $2
        `;
        params = [userId, limit];
      }

      const result = await db.query(query, params);
      return result;
    } catch (error) {
      logger.error('Error getting favorite users tweets', { userId, error });
      throw new ApiError(500, 'Failed to get favorite users tweets');
    }
  }
}