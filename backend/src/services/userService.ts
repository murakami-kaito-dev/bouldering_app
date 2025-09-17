import { User } from '../models/types';
import { IUserRepository } from '../domain/repositories/IUserRepository';
import { IEventBus } from '../domain/services/IEventBus';
import logger from '../utils/logger';

/**
 * ユーザーサービス
 * 
 * クリーンアーキテクチャにおける位置づけ:
 * - Application 層のサービス
 * - ビジネスロジックの実装
 * - リポジトリとイベントバスを通じた処理の調整
 */
export class UserService {
  constructor(
    private userRepository: IUserRepository,
    private eventBus: IEventBus
  ) {}

  /**
   * ユーザー取得
   */
  async getUserById(userId: string): Promise<User | null> {
    return await this.userRepository.findById(userId);
  }

  /**
   * ユーザープロフィール取得
   */
  async getUserProfile(userId: string): Promise<Partial<User> | null> {
    return await this.userRepository.findProfileById(userId);
  }

  /**
   * ユーザー作成
   */
  async createUser(userData: {
    user_id: string;
    user_name: string;
    user_icon_url?: string;
    email: string;
    home_gym_id?: number;
    user_introduce?: string;
    favorite_gym?: string;
    gender?: number;
    boul_start_date?: Date;
    birthday?: Date;
  }): Promise<User> {
    const user = await this.userRepository.create(userData);
    
    logger.info('User created successfully via service', {
      userId: userData.user_id,
      userName: userData.user_name
    });
    
    return user;
  }

  /**
   * ユーザー名更新
   */
  async updateUserName(userId: string, userName: string): Promise<User> {
    const user = await this.userRepository.updateUserName(userId, userName);
    
    logger.info('User name updated successfully', {
      userId,
      userName
    });
    
    return user;
  }

  /**
   * ユーザー紹介文更新
   */
  async updateUserProfileText(userId: string, description: string, type: string): Promise<User> {
    const user = await this.userRepository.updateUserProfileText(userId, description, type);
    
    logger.info('User profile text updated successfully', {
      userId,
      type: type === "true" ? "user_introduce" : "favorite_gym"
    });
    
    return user;
  }

  /**
   * ユーザー性別更新
   */
  async updateUserGender(userId: string, gender: number): Promise<User> {
    const user = await this.userRepository.updateUserGender(userId, gender);
    
    logger.info('User gender updated successfully', {
      userId,
      gender
    });
    
    return user;
  }

  /**
   * ユーザー日付情報更新
   */
  async updateUserDates(
    userId: string,
    boulStartDate?: Date,
    birthday?: Date
  ): Promise<User> {
    const user = await this.userRepository.updateUserDates(userId, boulStartDate, birthday);
    
    logger.info('User dates updated successfully', {
      userId,
      hasBoulStartDate: !!boulStartDate,
      hasBirthday: !!birthday
    });
    
    return user;
  }

  /**
   * ユーザーホームジム更新
   */
  async updateUserHomeGym(userId: string, homeGymId: number): Promise<User> {
    const user = await this.userRepository.updateUserHomeGym(userId, homeGymId);
    
    logger.info('User home gym updated successfully', {
      userId,
      homeGymId
    });
    
    return user;
  }

  /**
   * ユーザーアイコンURL更新
   */
  async updateUserIconUrl(userId: string, iconUrl: string): Promise<User> {
    const user = await this.userRepository.updateUserIconUrl(userId, iconUrl);
    
    logger.info('User icon URL updated successfully', {
      userId
    });
    
    return user;
  }

  /**
   * ユーザーメールアドレス更新
   */
  async updateUserEmail(userId: string, email: string): Promise<User> {
    const user = await this.userRepository.updateUserEmail(userId, email);
    
    logger.info('User email updated successfully', {
      userId
    });
    
    return user;
  }

  /**
   * 月別統計取得
   */
  async getMonthlyStats(userId: string, monthsAgo: number = 0): Promise<any> {
    const stats = await this.userRepository.getMonthlyStats(userId, monthsAgo);
    
    logger.info('Monthly stats retrieved successfully', {
      userId,
      monthsAgo
    });
    
    return stats;
  }

  /**
   * ユーザー削除
   */
  async deleteUser(userId: string): Promise<boolean> {
    const deleted = await this.userRepository.deleteUser(userId);
    
    if (deleted) {
      logger.info('User deleted successfully', {
        userId
      });
    } else {
      logger.warn('User deletion failed - user not found', {
        userId
      });
    }
    
    return deleted;
  }
}