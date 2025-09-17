import { User } from '../../models/types';

/**
 * ユーザーリポジトリインターface
 * 
 * クリーンアーキテクチャにおける位置づけ:
 * - Domain 層のインターface
 * - ユーザーデータアクセスの抽象化を提供
 * - インフラストラクチャの詳細に依存しない
 */

export interface IUserRepository {
  /**
   * ユーザーIDでユーザーを取得
   */
  findById(userId: string): Promise<User | null>;

  /**
   * ユーザープロフィール情報を取得
   */
  findProfileById(userId: string): Promise<Partial<User> | null>;

  /**
   * 新規ユーザーを作成
   */
  create(userData: {
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
  }): Promise<User>;

  /**
   * ユーザー情報を更新
   */
  update(userId: string, updateData: Partial<User>): Promise<User>;

  /**
   * ユーザー名を更新
   */
  updateUserName(userId: string, userName: string): Promise<User>;

  /**
   * ユーザープロフィールテキストを更新（紹介文または好きなジム）
   */
  updateUserProfileText(userId: string, description: string, type: string): Promise<User>;

  /**
   * ユーザーの性別を更新
   */
  updateUserGender(userId: string, gender: number): Promise<User>;

  /**
   * ユーザーの日付情報（開始日、誕生日）を更新
   */
  updateUserDates(userId: string, boulStartDate?: Date, birthday?: Date): Promise<User>;

  /**
   * ユーザーのホームジムを更新
   */
  updateUserHomeGym(userId: string, homeGymId: number): Promise<User>;

  /**
   * ユーザーのアイコンURLを更新
   */
  updateUserIconUrl(userId: string, iconUrl: string): Promise<User>;

  /**
   * ユーザーのメールアドレスを更新
   */
  updateUserEmail(userId: string, email: string): Promise<User>;

  /**
   * 月別統計データを取得
   */
  getMonthlyStats(userId: string, monthsAgo: number): Promise<any>;

  /**
   * ユーザーを削除
   */
  deleteUser(userId: string): Promise<boolean>;

  /**
   * ユーザーが存在するかチェック
   */
  exists(userId: string): Promise<boolean>;
}