import { FavoriteUserRelation, FavoriteGym } from '../models/types';
import { IFavoriteRepository } from '../domain/repositories/IFavoriteRepository';
import { IEventBus } from '../domain/services/IEventBus';
import logger from '../utils/logger';

/**
 * お気に入りサービス
 * 
 * クリーンアーキテクチャにおける位置づけ:
 * - Application 層のサービス
 * - ビジネスロジックの実装
 * - リポジトリとイベントバスを通じた処理の調整
 */
export class FavoriteService {
  constructor(
    private favoriteRepository: IFavoriteRepository,
    private eventBus: IEventBus
  ) {}

  /**
   * ユーザーお気に入り追加
   */
  async addUserToFavorites(likerUserId: string, likeeUserId: string): Promise<FavoriteUserRelation> {
    const favorite = await this.favoriteRepository.createUserFavorite(likerUserId, likeeUserId);
    
    logger.info('User added to favorites successfully', {
      likerUserId,
      likeeUserId
    });
    
    return favorite;
  }

  /**
   * ユーザーお気に入り削除
   */
  async removeUserFromFavorites(likerUserId: string, likeeUserId: string): Promise<void> {
    await this.favoriteRepository.deleteUserFavorite(likerUserId, likeeUserId);
    
    logger.info('User removed from favorites successfully', {
      likerUserId,
      likeeUserId
    });
  }

  /**
   * ユーザーお気に入り状態チェック
   */
  async checkUserFavorite(likerUserId: string, likeeUserId: string): Promise<boolean> {
    return await this.favoriteRepository.checkUserFavorite(likerUserId, likeeUserId);
  }

  /**
   * ユーザーのお気に入りユーザー一覧取得
   */
  async getUserFavorites(userId: string): Promise<any[]> {
    return await this.favoriteRepository.getUserFavorites(userId);
  }

  /**
   * ユーザーをお気に入りにしているユーザー一覧取得
   */
  async getUserFavoriteBy(userId: string): Promise<any[]> {
    return await this.favoriteRepository.getUserFavoriteBy(userId);
  }

  /**
   * ジムお気に入り追加
   */
  async addGymToFavorites(userId: string, gymId: number): Promise<FavoriteGym> {
    const favorite = await this.favoriteRepository.createGymFavorite(userId, gymId);
    
    logger.info('Gym added to favorites successfully', {
      userId,
      gymId
    });
    
    return favorite;
  }

  /**
   * ジムお気に入り削除
   */
  async removeGymFromFavorites(userId: string, gymId: number): Promise<void> {
    await this.favoriteRepository.deleteGymFavorite(userId, gymId);
    
    logger.info('Gym removed from favorites successfully', {
      userId,
      gymId
    });
  }

  /**
   * ジムお気に入り状態チェック
   */
  async checkGymFavorite(userId: string, gymId: number): Promise<boolean> {
    return await this.favoriteRepository.checkGymFavorite(userId, gymId);
  }

  /**
   * ユーザーのお気に入りジム一覧取得
   */
  async getUserFavoriteGyms(userId: string): Promise<any[]> {
    return await this.favoriteRepository.getUserFavoriteGyms(userId);
  }

  /**
   * ジムをお気に入りにしているユーザー一覧取得
   */
  async getGymFavoriteBy(gymId: number): Promise<any[]> {
    return await this.favoriteRepository.getGymFavoriteBy(gymId);
  }

  /**
   * お気に入りユーザーのツイート一覧取得
   */
  async getFavoriteUsersTweets(userId: string, limit: number, cursor?: string): Promise<any[]> {
    return await this.favoriteRepository.getFavoriteUsersTweets(userId, limit, cursor);
  }
}