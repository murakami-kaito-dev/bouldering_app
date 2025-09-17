import { IGymRepository } from '../domain/repositories/IGymRepository';
import { IEventBus } from '../domain/services/IEventBus';
import logger from '../utils/logger';

/**
 * ジムサービス
 * 
 * クリーンアーキテクチャにおける位置づけ:
 * - Application 層のサービス
 * - ビジネスロジックの実装
 * - リポジトリとイベントバスを通じた処理の調整
 */
export class GymService {
  constructor(
    private gymRepository: IGymRepository,
    private eventBus: IEventBus
  ) {}

  /**
   * 全ジム取得
   */
  async getAllGyms(): Promise<any[]> {
    return await this.gymRepository.findAll();
  }

  /**
   * ジムID別取得
   */
  async getGymById(gymId: number): Promise<any | null> {
    return await this.gymRepository.findById(gymId);
  }

  /**
   * ジムのツイート取得
   */
  async getGymTweets(gymId: number, limit: number = 20, cursor?: string): Promise<any[]> {
    return await this.gymRepository.findGymTweets(gymId, limit, cursor);
  }

  /**
   * イキタイ数統計取得
   */
  async getIkitaiCounts(): Promise<any[]> {
    return await this.gymRepository.getIkitaiCounts();
  }

  /**
   * ボル数統計取得
   */
  async getBoulCounts(): Promise<any[]> {
    return await this.gymRepository.getBoulCounts();
  }
}