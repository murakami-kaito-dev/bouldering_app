/**
 * ストレージパス管理サービス
 *
 * クリーンアーキテクチャにおける位置づけ:
 * - Domain 層のサービス
 * - ストレージパスに関するビジネスロジックを集約
 * - インフラストラクチャの詳細に依存しない純粋なドメインロジック
 *
 * 責務:
 * - メディアURLからストレージプレフィックスの導出
 * - ストレージパス構造の知識の集約
 * - 重複ロジックの排除
 */
export class StoragePathService {
  /**
   * メディアURLからストレージプレフィックスを導出
   *
   * URL構造: https://storage.googleapis.com/{bucket}/{prefix...}/{filename}
   *
   * @param mediaUrl GCSメディアURL
   * @returns ストレージプレフィックス（バケット名とファイル名を除く）
   *
   * 例:
   * 入力: "https://storage.googleapis.com/bucket/v1/public/users/user123/posts/2025/09/uuid/asset/original.jpeg"
   * 出力: "v1/public/users/user123/posts/2025/09/uuid/asset"
   */
  static deriveStoragePrefix(mediaUrl: string, logger?: any): string | null {
    try {
      // 既存実装と同じバリデーション
      if (!mediaUrl || !mediaUrl.includes('storage.googleapis.com')) {
        return null;
      }

      const urlObj = new URL(mediaUrl);
      const pathParts = urlObj.pathname.split('/').filter(part => part.length > 0);

      if (pathParts.length < 3) {
        return null;
      }

      // Remove bucket name (first) and filename (last)
      const prefixParts = pathParts.slice(1, -1);
      return prefixParts.join('/');
    } catch (error) {
      // 既存実装と同じエラーログ出力
      if (logger) {
        logger.warn('Failed to derive storage prefix from media URL', { mediaUrl, error });
      }
      return null;
    }
  }

  /**
   * ストレージプレフィックスの妥当性チェック
   *
   * @param prefix ストレージプレフィックス
   * @returns 妥当性の真偽値
   */
  static isValidPrefix(prefix: string | null): boolean {
    if (!prefix || typeof prefix !== 'string') {
      return false;
    }

    // 基本的なパス構造チェック
    // v1/public/users/{userId}/posts/{year}/{month}/{postUuid}/{assetUuid} の形式
    const parts = prefix.split('/');
    return parts.length >= 4 && parts[0] === 'v1' && parts[1] === 'public';
  }
}

/* 2025.09.15 リファクタリング予定.削除しない */
