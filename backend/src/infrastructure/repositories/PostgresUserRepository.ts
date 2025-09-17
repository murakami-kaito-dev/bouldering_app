import { db } from '../../config/database';
import { IUserRepository } from '../../domain/repositories/IUserRepository';
import { User } from '../../models/types';
import { ApiError } from '../../middleware/error';
import logger from '../../utils/logger';

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
    email: string;
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
          userData.email,
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

  async updateUserEmail(userId: string, email: string): Promise<User> {
    return this.update(userId, { email });
  }

  async getMonthlyStats(userId: string, monthsAgo: number): Promise<any> {
    try {
      // JavaScript側で日付計算（過去の実装を参考）
      const startDate = new Date();
      startDate.setMonth(startDate.getMonth() - monthsAgo);
      startDate.setDate(1); // その月の1日
      startDate.setHours(0, 0, 0, 0); // 時刻をリセット

      const endDate = new Date(startDate);
      endDate.setMonth(endDate.getMonth() + 1); // 翌月の1日

      // 1. ボル活回数の計算
      const totalVisitsResult = await db.query(
        `SELECT COALESCE(SUM(daily_gym_count), 0) AS total_visits
         FROM (
           SELECT DATE(t.visited_date) AS visit_day, COUNT(DISTINCT t.gym_id) AS daily_gym_count
           FROM tweets t
           WHERE t.user_id = $1
             AND t.visited_date >= $2
             AND t.visited_date < $3
           GROUP BY visit_day
         ) AS daily_counts`,
        [userId, startDate.toISOString(), endDate.toISOString()]
      );

      // 2. 訪問施設数の計算
      const totalGymCountResult = await db.query(
        `SELECT COUNT(DISTINCT t.gym_id) AS unique_gyms
         FROM tweets t
         WHERE t.user_id = $1
           AND t.visited_date >= $2
           AND t.visited_date < $3`,
        [userId, startDate.toISOString(), endDate.toISOString()]
      );

      // 3. 週平均回数の計算
      const weeklyVisitRateResult = await db.query(
        `SELECT TRUNC(COALESCE(SUM(daily_gym_count), 0)::numeric / (EXTRACT(DAY FROM CURRENT_DATE)::numeric / 7), 1) AS weekly_average
         FROM (
           SELECT t.visited_date, COUNT(DISTINCT t.gym_id) AS daily_gym_count
           FROM tweets t
           WHERE t.user_id = $1
             AND t.visited_date >= $2
             AND t.visited_date < $3
           GROUP BY t.visited_date
         ) AS daily_counts`,
        [userId, startDate.toISOString(), endDate.toISOString()]
      );

      // 4. TOP5 訪問ジムの計算
      const topGymsResult = await db.query(
        `SELECT g.gym_name, t.gym_id, COUNT(*) AS visit_count, MAX(t.visited_date) AS latest_visit
         FROM tweets t
         INNER JOIN gyms g ON t.gym_id = g.gym_id
         WHERE t.user_id = $1
           AND t.visited_date >= $2
           AND t.visited_date < $3
         GROUP BY t.gym_id, g.gym_name
         ORDER BY visit_count DESC, latest_visit DESC
         LIMIT 5`,
        [userId, startDate.toISOString(), endDate.toISOString()]
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
      const result = await db.query('DELETE FROM users WHERE user_id = $1', [userId]);
      
      const deleted = result.length > 0;
      if (deleted) {
        logger.info('User deleted successfully', { userId });
      }
      
      return deleted;
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