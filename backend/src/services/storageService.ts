import { IStorageService } from '../domain/services/IStorageService';
import { Storage } from '@google-cloud/storage';
import logger from '../utils/logger';

/**
 * Google Cloud Storage サービス実装
 * 
 * クリーンアーキテクチャにおける位置づけ:
 * - Infrastructure 層のストレージサービス実装
 * - ドメイン層のIStorageServiceインターフェースを実装
 * - GCS固有の詳細を隠蔽
 */
export class StorageService implements IStorageService {
  private storage: Storage;
  private bucketName: string;

  constructor(bucketName: string = process.env.GCS_BUCKET_NAME || 'bouldering-app-media-dev') {
    this.storage = new Storage();
    this.bucketName = bucketName;
  }

  /**
   * プレフィックスで始まるファイルを削除
   */
  async deleteFilesByPrefix(prefix: string): Promise<{ deletedCount: number; errors: string[] }> {
    if (!prefix || typeof prefix !== 'string') {
      throw new Error('Valid prefix is required');
    }

    logger.info('Starting GCS prefix deletion', { 
      prefix, 
      bucketName: this.bucketName
    });

    const bucket = this.storage.bucket(this.bucketName);

    // プレフィックスに一致するファイルを検索
    const [files] = await bucket.getFiles({ 
      prefix,
      autoPaginate: true,
    });

    if (files.length === 0) {
      logger.info('No files found for prefix', { 
        prefix, 
        bucketName: this.bucketName
      });
      return { deletedCount: 0, errors: [] };
    }

    logger.info('Found files for deletion', { 
      prefix, 
      fileCount: files.length,
      fileNames: files.slice(0, 5).map(f => f.name)
    });

    const errors: string[] = [];
    let deletedCount = 0;

    // ファイルの並列削除実行
    const deletePromises = files.map(async (file) => {
      try {
        await file.delete();
        deletedCount++;
        logger.debug('File deleted successfully', { fileName: file.name });
      } catch (error) {
        const err = error as Error;
        
        // 404エラー（既に削除済み）は正常として扱う
        if (err.message.includes('404') || err.message.includes('Not Found')) {
          logger.debug('File already deleted', { fileName: file.name });
          deletedCount++;
          return;
        }
        
        // その他のエラーはログに記録
        const errorMsg = `Failed to delete ${file.name}: ${err.message}`;
        logger.warn('Failed to delete individual file', { 
          fileName: file.name, 
          error: err.message 
        });
        errors.push(errorMsg);
      }
    });

    await Promise.all(deletePromises);

    logger.info('GCS prefix deletion completed', { 
      prefix, 
      deletedCount,
      errorCount: errors.length,
      bucketName: this.bucketName
    });

    return { deletedCount, errors };
  }
}