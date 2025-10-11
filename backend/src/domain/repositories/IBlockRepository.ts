import { UserBlock, BlockedUserDetail } from '../../models/types';

/**
 * ブロックリポジトリインターフェース
 * 
 * クリーンアーキテクチャにおける位置づけ:
 * - Domain層のインターフェース
 * - ブロックデータアクセスの抽象化を提供
 * - インフラストラクチャの詳細に依存しない
 */
export interface IBlockRepository {
  /**
   * ユーザーをブロック
   * @param blockerUserId ブロックする側のユーザーID
   * @param blockedUserId ブロックされる側のユーザーID
   * @returns 作成されたブロック情報
   */
  createBlock(blockerUserId: string, blockedUserId: string): Promise<UserBlock>;

  /**
   * ブロックを解除
   * @param blockerUserId ブロックした側のユーザーID
   * @param blockedUserId ブロックされた側のユーザーID
   * @returns 削除成功の可否
   */
  deleteBlock(blockerUserId: string, blockedUserId: string): Promise<boolean>;

  /**
   * ブロックしているユーザー一覧を取得
   * @param blockerUserId ブロックしている側のユーザーID
   * @returns ブロックしているユーザーの詳細情報リスト
   */
  getBlockedUsers(blockerUserId: string): Promise<BlockedUserDetail[]>;

  /**
   * 特定のユーザーをブロックしているか確認
   * @param blockerUserId ブロックする側のユーザーID
   * @param targetUserId 確認対象のユーザーID
   * @returns ブロックしているかどうか
   */
  isBlocked(blockerUserId: string, targetUserId: string): Promise<boolean>;

  /**
   * 相互ブロック状態を確認
   * （自分がブロックしている、または相手にブロックされている）
   * @param userId1 ユーザーID1
   * @param userId2 ユーザーID2
   * @returns 相互にブロック関係があるかどうか
   */
  isMutuallyBlocked(userId1: string, userId2: string): Promise<boolean>;

  /**
   * ブロック関係にあるユーザーIDのリストを取得
   * （ツイート取得時のフィルタリング用）
   * @param userId ユーザーID
   * @returns ブロック関係にあるユーザーIDのリスト
   */
  getBlockedUserIds(userId: string): Promise<string[]>;
}