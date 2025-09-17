import { db } from '../../config/database';
import { IGymRepository } from '../../domain/repositories/IGymRepository';
import { ApiError } from '../../middleware/error';
import logger from '../../utils/logger';

/**
 * PostgreSQL Gym リポジトリ実装
 * 
 * クリーンアーキテクチャにおける位置づけ:
 * - Infrastructure 層の具体実装
 * - IGymRepositoryインターフェースの実装
 * - PostgreSQLデータベースとの具体的な通信を担当
 */
export class PostgresGymRepository implements IGymRepository {
  /**
   * 全ジム情報を取得
   * 
   * @returns {Promise<any[]>} 全ジムの配列を返す
   * 
   * 取得内容:
   * - ジム基本情報（名前、住所、料金等）
   * - 営業時間情報（gym_hoursテーブルから）
   * - イキタイ数（gym_favoritesテーブルから集計）
   * - ボル活投稿数（tweetsテーブルから集計）
   */
  async findAll(): Promise<any[]> {
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
          g.is_bouldering_gym,
          g.is_lead_gym,
          g.is_speed_gym,
          COALESCE(COUNT(DISTINCT gf.user_id), 0) as ikitai_count,
          COALESCE(COUNT(t.tweet_id), 0) as boul_count,
          gh.sun_open, gh.sun_close,
          gh.mon_open, gh.mon_close,
          gh.tue_open, gh.tue_close,
          gh.wed_open, gh.wed_close,
          gh.thu_open, gh.thu_close,
          gh.fri_open, gh.fri_close,
          gh.sat_open, gh.sat_close
        FROM gyms AS g
        LEFT JOIN gym_hours AS gh ON gh.gym_id = g.gym_id
        LEFT JOIN gym_favorites AS gf ON gf.gym_id = g.gym_id
        LEFT JOIN tweets AS t ON t.gym_id = g.gym_id
        GROUP BY g.gym_id, g.gym_name, g.hp_link, g.prefecture, g.city, g.address_line,
                 g.latitude, g.longitude, g.tel_no, g.fee, g.minimum_fee, g.equipment_rental_fee,
                 g.is_bouldering_gym, g.is_lead_gym, g.is_speed_gym,
                 gh.sun_open, gh.sun_close, gh.mon_open, gh.mon_close,
                 gh.tue_open, gh.tue_close, gh.wed_open, gh.wed_close,
                 gh.thu_open, gh.thu_close, gh.fri_open, gh.fri_close,
                 gh.sat_open, gh.sat_close
        ORDER BY g.gym_name`
      );

      return result;
    } catch (error) {
      logger.error('Error finding all gyms', { error });
      throw new ApiError(500, 'Failed to find gyms');
    }
  }

  /**
   * 指定IDのジム詳細情報を取得
   * 
   * @param {number} gymId - 取得対象のジムID
   * @returns {Promise<any | null>} ジム情報、存在しない場合はnull
   * 
   * 取得内容:
   * - ジム基本情報（名前、住所、料金等）
   * - 営業時間情報（gym_hoursテーブルから）
   * - イキタイ数（gym_favoritesテーブルから集計）
   * - ボル活投稿数（tweetsテーブルから集計）
   */
  async findById(gymId: number): Promise<any | null> {
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
          g.is_bouldering_gym,
          g.is_lead_gym,
          g.is_speed_gym,
          COALESCE(COUNT(DISTINCT gf.user_id), 0) as ikitai_count,
          COALESCE(COUNT(t.tweet_id), 0) as boul_count,
          gh.sun_open, gh.sun_close,
          gh.mon_open, gh.mon_close,
          gh.tue_open, gh.tue_close,
          gh.wed_open, gh.wed_close,
          gh.thu_open, gh.thu_close,
          gh.fri_open, gh.fri_close,
          gh.sat_open, gh.sat_close
        FROM gyms AS g
        LEFT JOIN gym_hours AS gh ON gh.gym_id = g.gym_id
        LEFT JOIN gym_favorites AS gf ON gf.gym_id = g.gym_id
        LEFT JOIN tweets AS t ON t.gym_id = g.gym_id
        WHERE g.gym_id = $1
        GROUP BY g.gym_id, g.gym_name, g.hp_link, g.prefecture, g.city, g.address_line,
                 g.latitude, g.longitude, g.tel_no, g.fee, g.minimum_fee, g.equipment_rental_fee,
                 g.is_bouldering_gym, g.is_lead_gym, g.is_speed_gym,
                 gh.sun_open, gh.sun_close, gh.mon_open, gh.mon_close,
                 gh.tue_open, gh.tue_close, gh.wed_open, gh.wed_close,
                 gh.thu_open, gh.thu_close, gh.fri_open, gh.fri_close,
                 gh.sat_open, gh.sat_close`,
        [gymId]
      );

      return result.length > 0 ? result[0] : null;
    } catch (error) {
      logger.error('Error finding gym by ID', { gymId, error });
      throw new ApiError(500, 'Failed to find gym');
    }
  }

  /**
   * 指定ジムのツイート一覧を取得
   * 
   * @param {number} gymId - 対象ジムのID
   * @param {number} limit - 取得件数の上限
   * @param {string} cursor - ページネーション用カーソル（オプション）
   * @returns {Promise<any[]>} ツイート一覧
   * 
   * 取得内容:
   * - ツイート情報（内容、日時、いいね数等）
   * - 投稿ユーザー情報
   * - メディア（画像・動画）のURL一覧
   */
  async findGymTweets(gymId: number, limit: number, cursor?: string): Promise<any[]> {
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
          WHERE t.gym_id = $1 AND t.tweeted_date < $2
          ORDER BY t.tweeted_date DESC
          LIMIT $3`;
        params = [gymId, cursor, limit];
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
          WHERE t.gym_id = $1
          ORDER BY t.tweeted_date DESC
          LIMIT $2`;
        params = [gymId, limit];
      }

      const result = await db.query(query, params);
      return result;
    } catch (error) {
      logger.error('Error finding gym tweets', { gymId, limit, cursor, error });
      throw new ApiError(500, 'Failed to find gym tweets');
    }
  }

  /**
   * イキタイ数ランキングを取得
   * 
   * @returns {Promise<any[]>} イキタイ数上位20件のジム一覧
   * 
   * 集計内容:
   * - ジムごとのユニークユーザー数（イキタイ数）
   * - 総ツイート数
   * - イキタイ数の降順でソート
   */
  async getIkitaiCounts(): Promise<any[]> {
    try {
      const result = await db.query(`
        SELECT 
          g.gym_id,
          g.gym_name,
          g.prefecture,
          COUNT(DISTINCT t.user_id) as ikitai_count,
          COUNT(t.tweet_id) as total_tweets
        FROM gyms g
        LEFT JOIN tweets t ON g.gym_id = t.gym_id
        GROUP BY g.gym_id, g.gym_name, g.prefecture
        HAVING COUNT(DISTINCT t.user_id) > 0
        ORDER BY ikitai_count DESC, total_tweets DESC
        LIMIT 20`
      );

      return result;
    } catch (error) {
      logger.error('Error getting ikitai counts', { error });
      throw new ApiError(500, 'Failed to get ikitai counts');
    }
  }

  /**
   * ボル活投稿数ランキングを取得
   * 
   * @returns {Promise<any[]>} ボル活投稿数上位20件のジム一覧
   * 
   * 集計内容:
   * - ジムごとの総ツイート数（ボル活数）
   * - ボル活数の降順でソート
   */
  async getBoulCounts(): Promise<any[]> {
    try {
      const result = await db.query(`
        SELECT 
          g.gym_id,
          g.gym_name,
          g.prefecture,
          COUNT(t.tweet_id) as boul_count
        FROM gyms g
        LEFT JOIN tweets t ON g.gym_id = t.gym_id
        GROUP BY g.gym_id, g.gym_name, g.prefecture
        HAVING COUNT(t.tweet_id) > 0
        ORDER BY boul_count DESC
        LIMIT 20`
      );

      return result;
    } catch (error) {
      logger.error('Error getting boul counts', { error });
      throw new ApiError(500, 'Failed to get boul counts');
    }
  }

  /**
   * 指定IDのジムが存在するか確認
   * 
   * @param {number} gymId - 確認対象のジムID
   * @returns {Promise<boolean>} 存在する場合true、しない場合false
   */
  async exists(gymId: number): Promise<boolean> {
    try {
      const result = await db.query('SELECT 1 FROM gyms WHERE gym_id = $1', [gymId]);
      return result.length > 0;
    } catch (error) {
      logger.error('Error checking gym existence', { gymId, error });
      throw new ApiError(500, 'Failed to check gym existence');
    }
  }
}