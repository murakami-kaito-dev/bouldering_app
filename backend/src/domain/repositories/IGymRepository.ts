import { Gym } from '../../models/types';

/**
 * ジムリポジトリインターface
 * 
 * クリーンアーキテクチャにおける位置づけ:
 * - Domain 層のインターface
 * - ジムデータアクセスの抽象化を提供
 * - インフラストラクチャの詳細に依存しない
 */

export interface IGymRepository {
  /**
   * すべてのジムを取得
   */
  findAll(): Promise<any[]>;

  /**
   * ジムIDでジムを取得
   */
  findById(gymId: number): Promise<any | null>;

  /**
   * ジムのツイートを取得（ページネーション付き）
   */
  findGymTweets(gymId: number, limit: number, cursor?: string): Promise<any[]>;

  /**
   * イキタイ数統計を取得
   */
  getIkitaiCounts(): Promise<any[]>;

  /**
   * ボル数統計を取得
   */
  getBoulCounts(): Promise<any[]>;

  /**
   * ジムが存在するかチェック
   */
  exists(gymId: number): Promise<boolean>;
}