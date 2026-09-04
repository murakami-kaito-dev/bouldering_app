import { db } from '../../config/database';
import { IUserRepository } from '../../domain/repositories/IUserRepository';
import { User } from '../../models/types';
import { ApiError } from '../../middleware/error';
import logger from '../../utils/logger';
import { jstMonthRange } from '../../utils/jstTime';

/** PostgreSQL の UNIQUE 制約違反（SQLSTATE 23505）か */
function isUniqueViolation(error: unknown): boolean {
  return typeof error === 'object' && error !== null && (error as { code?: string }).code === '23505';
}

/**
 * PostgreSQL User リポジトリ実装
 * 
 * クリーンアーキテクチャにおける位置づけ:
 * - Infrastructure 層の具体実装
 * - IUserRepositoryインターフェースの実装
 * - PostgreSQLデータベースとの具体的な通信を担当
 */
export class PostgresUserRepository implements IUserRepository {
  async findById(userId: string): Promise<User | null> {
    try {
      const result = await db.query(
        `SELECT
          user_id, user_name, user_icon_url, email, home_gym_id,
          user_introduce, favorite_gym, gender, boul_start_date, birthday,
          created_at, updated_at
        FROM users
        WHERE user_id = $1`,
        [userId]
      );

      return result.length > 0 ? result[0] : null;
    } catch (error) {
      logger.error('Error finding user by ID', { userId, error });
      throw new ApiError(500, 'Failed to find user');
    }
  }

  async findProfileById(userId: string): Promise<Partial<User> | null> {
    try {
      const result = await db.query(
        `SELECT
          user_id, user_name, user_icon_url, user_introduce,
          gender, boul_start_date, birthday, home_gym_id
        FROM users
        WHERE user_id = $1`,
        [userId]
      );

      return result.length > 0 ? result[0] : null;
    } catch (error) {
      logger.error('Error finding user profile by ID', { userId, error });
      throw new ApiError(500, 'Failed to find user profile');
    }
  }

  async create(userData: {
    user_id: string;
    user_name: string;
    user_icon_url?: string;
    email?: string | null;
    home_gym_id?: number;
    user_introduce?: string;
    gender?: number;
    boul_start_date?: Date;
    birthday?: Date;
  }): Promise<User> {
    try {
      const result = await db.query(
        `INSERT INTO users (
          user_id, user_name, user_icon_url, email, home_gym_id,
          user_introduce, gender, boul_start_date, birthday
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
        RETURNING *`,
        [
          userData.user_id,
          userData.user_name,
          userData.user_icon_url || null,
          userData.email ?? null,
          userData.home_gym_id || null,
          userData.user_introduce || null,
          userData.gender || null,
          userData.boul_start_date || null,
          userData.birthday || null,
        ]
      );

      logger.info('User created successfully', { userId: userData.user_id });
      return result[0];
    } catch (error) {
      logger.error('Error creating user', { userData: { ...userData, email: '[REDACTED]' }, error });
      throw new ApiError(500, 'Failed to create user');
    }
  }

  async update(userId: string, updateData: Partial<User>): Promise<User> {
    try {
      const setParts: string[] = [];
      const values: any[] = [];
      let paramIndex = 1;

      // 動的にSET句を構築
      Object.keys(updateData).forEach((key) => {
        if (updateData[key as keyof User] !== undefined && key !== 'user_id') {
          setParts.push(`${key} = $${paramIndex}`);
          values.push(updateData[key as keyof User]);
          paramIndex++;
        }
      });

      if (setParts.length === 0) {
        throw new ApiError(400, 'No valid fields to update');
      }

      values.push(userId); // WHERE条件用

      const query = `
        UPDATE users 
        SET ${setParts.join(', ')}, updated_at = CURRENT_TIMESTAMP
        WHERE user_id = $${paramIndex}
        RETURNING *
      `;

      const result = await db.query(query, values);

      if (result.length === 0) {
        throw new ApiError(404, 'User not found');
      }

      logger.info('User updated successfully', { userId, updatedFields: Object.keys(updateData) });
      return result[0];
    } catch (error) {
      if (error instanceof ApiError) throw error;
      // 1アカウント:1メール（users.email の UNIQUE）に当たった → 409 で返し、アプリが案内する
      if (isUniqueViolation(error)) {
        logger.warn('Unique violation on user update', { userId, fields: Object.keys(updateData) });
        throw new ApiError(409, 'Email is already registered by another account', 'EMAIL_ALREADY_REGISTERED');
      }
      logger.error('Error updating user', { userId, updateData, error });
      throw new ApiError(500, 'Failed to update user');
    }
  }

  async updateUserName(userId: string, userName: string): Promise<User> {
    return this.update(userId, { user_name: userName });
  }

  async updateUserProfileText(userId: string, description: string, type: string): Promise<User> {
    if (type === 'true') {
      // 自己紹介を更新
      return this.update(userId, { user_introduce: description });
    } else {
      // 好きなジムを更新
      return this.update(userId, { favorite_gym: description });
    }
  }

  async updateUserGender(userId: string, gender: number): Promise<User> {
    return this.update(userId, { gender });
  }

  async updateUserDates(userId: string, boulStartDate?: Date, birthday?: Date): Promise<User> {
    const updateData: Partial<User> = {};
    if (boulStartDate !== undefined) updateData.boul_start_date = boulStartDate;
    if (birthday !== undefined) updateData.birthday = birthday;
    
    return this.update(userId, updateData);
  }

  async updateUserHomeGym(userId: string, homeGymId: number): Promise<User> {
    return this.update(userId, { home_gym_id: homeGymId });
  }

  async updateUserIconUrl(userId: string, iconUrl: string): Promise<User> {
    return this.update(userId, { user_icon_url: iconUrl });
  }

  /** [email] が null なら未登録に戻す。重複は update() が 409 にする */
  async updateUserEmail(userId: string, email: string | null): Promise<User> {
    return this.update(userId, { email });
  }

  async getMonthlyStats(userId: string, monthsAgo: number): Promise<any> {
    try {
      // 「今月」「N か月前」の範囲は日本時間で決める（サーバーは UTC なので new Date() の
      // 月をそのまま使うと、毎月 1 日の 0〜9 時（JST）に先月扱いになっていた）。
      // 範囲は 'YYYY-MM-DD' の半開区間 [start, end) で DATE 列と比較する
      const range = jstMonthRange(monthsAgo);
      const startDate = range.start;
      const endDate = range.end;

      // 週平均の分母に使う「週数」の元になる日数
      // - 今月: 日本時間での経過日数（月初ほど値が大きくなるのは仕様として許容）
      // - 過去の月: その月の日数（例: 8月なら31日）
      //   ※ 従来は CURRENT_DATE（UTC）を使っており、JST 0〜9 時は 1 日ずれていた
      const denominatorDays = range.elapsedDays;

      // 1. ボル活回数の計算
      const totalVisitsResult = await db.query(
        `SELECT COALESCE(SUM(daily_gym_count), 0) AS total_visits
         FROM (
           SELECT DATE(t.visited_date) AS visit_day, COUNT(DISTINCT t.gym_id) AS daily_gym_count
           FROM tweets t
           WHERE t.user_id = $1
             AND t.visited_date >= $2::date
             AND t.visited_date < $3::date
           GROUP BY visit_day
         ) AS daily_counts`,
        [userId, startDate, endDate]
      );

      // 2. 訪問施設数の計算
      const totalGymCountResult = await db.query(
        `SELECT COUNT(DISTINCT t.gym_id) AS unique_gyms
         FROM tweets t
         WHERE t.user_id = $1
           AND t.visited_date >= $2::date
           AND t.visited_date < $3::date`,
        [userId, startDate, endDate]
      );

      // 3. 週平均回数の計算
      // 「ボル活回数 ÷ 対象月の週数」。分子は 1.（total_visits）と同じ集計に揃える
      const weeklyVisitRateResult = await db.query(
        `SELECT TRUNC(COALESCE(SUM(daily_gym_count), 0)::numeric / ($4::numeric / 7), 1) AS weekly_average
         FROM (
           SELECT DATE(t.visited_date) AS visit_day, COUNT(DISTINCT t.gym_id) AS daily_gym_count
           FROM tweets t
           WHERE t.user_id = $1
             AND t.visited_date >= $2::date
             AND t.visited_date < $3::date
           GROUP BY visit_day
         ) AS daily_counts`,
        [userId, startDate, endDate, denominatorDays]
      );

      // 4. TOP5 訪問ジムの計算
      const topGymsResult = await db.query(
        `SELECT g.gym_name, t.gym_id, COUNT(*) AS visit_count, MAX(t.visited_date) AS latest_visit
         FROM tweets t
         INNER JOIN gyms g ON t.gym_id = g.gym_id
         WHERE t.user_id = $1
           AND t.visited_date >= $2::date
           AND t.visited_date < $3::date
         GROUP BY t.gym_id, g.gym_name
         ORDER BY visit_count DESC, latest_visit DESC
         LIMIT 5`,
        [userId, startDate, endDate]
      );

      const topGyms = topGymsResult.map(row => ({
        gym_id: row.gym_id,
        gym_name: row.gym_name,
        visit_count: row.visit_count
      }));

      // TOP5に満たない場合、空データで埋める
      while (topGyms.length < 5) {
        topGyms.push({ gym_id: "0", gym_name: "-", visit_count: "-" });
      }

      return {
        total_visits: totalVisitsResult[0]?.total_visits || 0,
        unique_gyms: totalGymCountResult[0]?.unique_gyms || 0,
        weekly_average: weeklyVisitRateResult[0]?.weekly_average || 0,
        top_gyms: topGyms
      };
    } catch (error) {
      logger.error('Error getting monthly stats', { userId, monthsAgo, error });
      throw new ApiError(500, 'Failed to get monthly stats');
    }
  }

  async deleteUser(userId: string): Promise<boolean> {
    try {
      // 削除前に存在チェック
      const checkResult = await db.query('SELECT 1 FROM users WHERE user_id = $1', [userId]);
      
      if (checkResult.length === 0) {
        // ユーザーが既に削除済み、あるいは存在しない
        logger.info('User not found or already deleted', { userId });
        // 冪等性を担保するためtrueを返す
        return true;
      }
      
      // 存在しているなら削除実行
      await db.query('DELETE FROM users WHERE user_id = $1', [userId]);
      
      // 例外が発生しなければ削除成功
      logger.info('User deleted successfully', { userId });
      return true;
    } catch (error) {
      logger.error('Error deleting user', { userId, error });
      throw new ApiError(500, 'Failed to delete user');
    }
  }

  async exists(userId: string): Promise<boolean> {
    try {
      const result = await db.query('SELECT 1 FROM users WHERE user_id = $1', [userId]);
      return result.length > 0;
    } catch (error) {
      logger.error('Error checking user existence', { userId, error });
      throw new ApiError(500, 'Failed to check user existence');
    }
  }
}