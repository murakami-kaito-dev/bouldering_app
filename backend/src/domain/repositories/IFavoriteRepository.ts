import { FavoriteUserRelation, FavoriteGym } from '../../models/types';

/**
 * お気に入りリポジトリインターフェース
 * 
 * クリーンアーキテクチャにおける位置づけ:
 * - Domain 層のインターフェース
 * - お気に入り機能のデータアクセス抽象化
 * - インフラストラクチャの詳細に依存しない
 */
export interface IFavoriteRepository {
  /**
   * ユーザーお気に入り関係を作成
   */
  createUserFavorite(likerUserId: string, likeeUserId: string): Promise<FavoriteUserRelation>;

  /**
   * ユーザーお気に入り関係を削除
   */
  deleteUserFavorite(likerUserId: string, likeeUserId: string): Promise<void>;

  /**
   * ユーザーお気に入り関係の存在確認
   */
  checkUserFavorite(likerUserId: string, likeeUserId: string): Promise<boolean>;

  /**
   * ユーザーのお気に入りユーザー一覧取得
   */
  getUserFavorites(userId: string): Promise<any[]>;

  /**
   * ユーザーをお気に入りにしているユーザー一覧取得
   */
  getUserFavoriteBy(userId: string): Promise<any[]>;

  /**
   * お気に入りユーザーのツイート一覧取得
   */
  getFavoriteUsersTweets(userId: string, limit: number, cursor?: string): Promise<any[]>;

  /**
   * ジムお気に入り関係を作成
   */
  createGymFavorite(userId: string, gymId: number): Promise<FavoriteGym>;

  /**
   * ジムお気に入り関係を削除
   */
  deleteGymFavorite(userId: string, gymId: number): Promise<void>;

  /**
   * ジムお気に入り関係の存在確認
   */
  checkGymFavorite(userId: string, gymId: number): Promise<boolean>;

  /**
   * ユーザーのお気に入りジム一覧取得
   */
  getUserFavoriteGyms(userId: string): Promise<any[]>;

  /**
   * ジムをお気に入りにしているユーザー一覧取得
   */
  getGymFavoriteBy(gymId: number): Promise<any[]>;
}