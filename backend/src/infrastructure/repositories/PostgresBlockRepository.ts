import { db } from '../../config/database';
import { IBlockRepository } from '../../domain/repositories/IBlockRepository';
import { UserBlock, BlockedUserDetail } from '../../models/types';
import { ApiError } from '../../middleware/error';
import logger from '../../utils/logger';

/**
 * PostgreSQL ブロックリポジトリ実装
 * 
 * クリーンアーキテクチャにおける位置づけ:
 * - Infrastructure層の具体実装
 * - IBlockRepositoryインターフェースの実装
 * - PostgreSQLデータベースとの具体的な通信を担当
 */
export class PostgresBlockRepository implements IBlockRepository {
  
  async createBlock(blockerUserId: string, blockedUserId: string): Promise<UserBlock> {
    try {
      const result = await db.query(
        `INSERT INTO user_blocks (blocker_user_id, blocked_user_id)
         VALUES ($1, $2)
         ON CONFLICT (blocker_user_id, blocked_user_id) DO UPDATE
         SET created_at = CURRENT_TIMESTAMP
         RETURNING *`,
        [blockerUserId, blockedUserId]
      );

      return result[0];
    } catch (error) {
      logger.error('Error creating block', { blockerUserId, blockedUserId, error });
      throw new ApiError(500, 'Failed to create block');
    }
  }

  async deleteBlock(blockerUserId: string, blockedUserId: string): Promise<boolean> {
    try {
      const result = await db.query(
        `DELETE FROM user_blocks
         WHERE blocker_user_id = $1 AND blocked_user_id = $2`,
        [blockerUserId, blockedUserId]
      );

      return result.length > 0;
    } catch (error) {
      logger.error('Error deleting block', { blockerUserId, blockedUserId, error });
      throw new ApiError(500, 'Failed to delete block');
    }
  }

  async getBlockedUsers(blockerUserId: string): Promise<BlockedUserDetail[]> {
    try {
      const result = await db.query(
        `SELECT 
          ub.blocked_user_id,
          u.user_name,
          u.user_icon_url,
          u.user_introduce as user_bio,
          ub.created_at as blocked_at
         FROM user_blocks ub
         JOIN users u ON ub.blocked_user_id = u.user_id
         WHERE ub.blocker_user_id = $1
         ORDER BY ub.created_at DESC`,
        [blockerUserId]
      );

      return result;
    } catch (error) {
      logger.error('Error getting blocked users', { blockerUserId, error });
      throw new ApiError(500, 'Failed to get blocked users');
    }
  }

  async isBlocked(blockerUserId: string, targetUserId: string): Promise<boolean> {
    try {
      const result = await db.query(
        `SELECT EXISTS(
          SELECT 1 FROM user_blocks
          WHERE blocker_user_id = $1 AND blocked_user_id = $2
        ) as is_blocked`,
        [blockerUserId, targetUserId]
      );

      return result[0]?.is_blocked || false;
    } catch (error) {
      logger.error('Error checking block status', { blockerUserId, targetUserId, error });
      throw new ApiError(500, 'Failed to check block status');
    }
  }

  async isMutuallyBlocked(userId1: string, userId2: string): Promise<boolean> {
    try {
      const result = await db.query(
        `SELECT EXISTS(
          SELECT 1 FROM user_blocks
          WHERE (blocker_user_id = $1 AND blocked_user_id = $2)
             OR (blocker_user_id = $2 AND blocked_user_id = $1)
        ) as is_blocked`,
        [userId1, userId2]
      );

      return result[0]?.is_blocked || false;
    } catch (error) {
      logger.error('Error checking mutual block status', { userId1, userId2, error });
      throw new ApiError(500, 'Failed to check mutual block status');
    }
  }

  async getBlockedUserIds(userId: string): Promise<string[]> {
    try {
      const result = await db.query(
        `SELECT blocked_user_id as user_id FROM user_blocks WHERE blocker_user_id = $1
         UNION
         SELECT blocker_user_id as user_id FROM user_blocks WHERE blocked_user_id = $1`,
        [userId]
      );

      return result.map((row: any) => row.user_id);
    } catch (error) {
      logger.error('Error getting blocked user IDs', { userId, error });
      throw new ApiError(500, 'Failed to get blocked user IDs');
    }
  }
}