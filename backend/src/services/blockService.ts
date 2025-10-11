import { IBlockRepository } from '../domain/repositories/IBlockRepository';
import { UserBlock, BlockedUserDetail } from '../models/types';
import { ApiError } from '../middleware/error';
import logger from '../utils/logger';

/**
 * ブロック機能のビジネスロジック
 * 
 * 役割:
 * - ブロック機能のビジネスルールを実装
 * - リポジトリを使用してデータアクセス
 * - バリデーションとエラーハンドリング
 */
export class BlockService {
  constructor(private blockRepository: IBlockRepository) {}

  /**
   * ユーザーをブロック
   */
  async blockUser(blockerUserId: string, blockedUserId: string): Promise<UserBlock> {
    // ビジネスルール: 自分自身をブロックできない
    if (blockerUserId === blockedUserId) {
      throw new ApiError(400, '自分自身をブロックすることはできません');
    }

    try {
      const block = await this.blockRepository.createBlock(blockerUserId, blockedUserId);
      
      logger.info('User blocked successfully', { 
        blockerUserId, 
        blockedUserId,
        blockId: block.block_id 
      });
      
      return block;
    } catch (error) {
      logger.error('Failed to block user', { blockerUserId, blockedUserId, error });
      throw error;
    }
  }

  /**
   * ブロックを解除
   */
  async unblockUser(blockerUserId: string, blockedUserId: string): Promise<void> {
    try {
      const success = await this.blockRepository.deleteBlock(blockerUserId, blockedUserId);
      
      if (!success) {
        throw new ApiError(404, 'ブロック情報が見つかりません');
      }

      logger.info('User unblocked successfully', { blockerUserId, blockedUserId });
    } catch (error) {
      logger.error('Failed to unblock user', { blockerUserId, blockedUserId, error });
      throw error;
    }
  }

  /**
   * ブロックしているユーザー一覧を取得
   */
  async getBlockedUsers(blockerUserId: string): Promise<BlockedUserDetail[]> {
    try {
      const blockedUsers = await this.blockRepository.getBlockedUsers(blockerUserId);
      
      logger.info('Retrieved blocked users', { 
        blockerUserId, 
        count: blockedUsers.length 
      });
      
      return blockedUsers;
    } catch (error) {
      logger.error('Failed to get blocked users', { blockerUserId, error });
      throw error;
    }
  }

  /**
   * ブロック状態を確認
   */
  async checkBlockStatus(blockerUserId: string, targetUserId: string): Promise<{ isBlocked: boolean }> {
    try {
      const isBlocked = await this.blockRepository.isBlocked(blockerUserId, targetUserId);
      return { isBlocked };
    } catch (error) {
      logger.error('Failed to check block status', { blockerUserId, targetUserId, error });
      throw error;
    }
  }

  /**
   * 相互ブロック状態を確認
   */
  async checkMutualBlockStatus(userId1: string, userId2: string): Promise<{ isMutuallyBlocked: boolean }> {
    try {
      const isMutuallyBlocked = await this.blockRepository.isMutuallyBlocked(userId1, userId2);
      return { isMutuallyBlocked };
    } catch (error) {
      logger.error('Failed to check mutual block status', { userId1, userId2, error });
      throw error;
    }
  }

  /**
   * ブロック関係にあるユーザーIDを取得（ツイートフィルタリング用）
   */
  async getBlockedUserIds(userId: string): Promise<string[]> {
    try {
      return await this.blockRepository.getBlockedUserIds(userId);
    } catch (error) {
      logger.error('Failed to get blocked user IDs', { userId, error });
      throw error;
    }
  }
}