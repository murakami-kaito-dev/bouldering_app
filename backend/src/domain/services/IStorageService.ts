/**
 * ストレージサービスインターフェース
 * 
 * クリーンアーキテクチャにおける位置づけ:
 * - Domain 層のサービスインターフェース
 * - ファイルストレージ操作の抽象化
 * - インフラストラクチャの詳細に依存しない
 */
export interface IStorageService {
  /**
   * プレフィックスで始まるファイルを削除
   */
  deleteFilesByPrefix(prefix: string): Promise<{
    deletedCount: number;
    errors: string[];
  }>;
}