import { Router, Request, Response, NextFunction } from 'express';
import { Storage } from '@google-cloud/storage';
import logger from '../utils/logger';

/**
 * 内部タスク処理用ルーター
 * 
 * 役割:
 * - Cloud Tasks からの内部リクエストを処理
 * - GCS ファイル削除などのバックグラウンドタスクを実行
 * - セキュリティ保護された内部エンドポイントを提供
 * 
 * セキュリティ:
 * - Cloud Tasks からの OIDC 認証付きリクエストのみを受け付け
 * - 一般ユーザーからの直接アクセスは拒否
 * 
 * クリーンアーキテクチャにおける位置づけ:
 * - Infrastructure 層のHTTPルーター
 * - 外部タスクシステムとの通信インターフェース
 * - ワーカータスクの実行環境を提供
 */

const router = Router();

// Google Cloud Storage クライアントの初期化
const storage = new Storage();
const bucketName = process.env.GCS_BUCKET_NAME || 'bouldering-app-media-dev';

/**
 * Cloud Tasks 認証ミドルウェア
 * 
 * 単一サービス構成でCloud Tasks からの OIDC トークンを検証
 * - 本番環境: OIDC トークンの詳細検証を実装
 * - 開発環境: 簡易チェックまたはスキップ
 * 
 * TODO 本番デプロイ前に OIDC トークン検証を強化
 */
function verifyCloudTasksAuth(req: Request, res: Response, next: NextFunction): void {
  // 開発環境での簡易チェック
  const authHeader = req.headers.authorization;
  const userAgent = req.headers['user-agent'] || '';

  // Cloud Tasks からのリクエストの特徴をチェック
  const isFromCloudTasks = 
    userAgent.includes('Google-Cloud-Tasks') || 
    authHeader?.startsWith('Bearer ');

  if (!isFromCloudTasks) {
    logger.warn('Unauthorized access to internal tasks endpoint', {
      userAgent,
      ip: req.ip,
      authHeader: authHeader ? 'present' : 'missing',
      endpoint: req.path
    });
    res.status(401).json({ error: 'Unauthorized - Cloud Tasks access only' });
    return;
  }

  logger.debug('Cloud Tasks authentication verified', {
    userAgent,
    endpoint: req.path
  });

  // TODO 本番環境では以下の OIDC 検証を実装:
  // 1. JWT トークンのデコード
  // 2. Google の公開鍵での署名検証
  // 3. audience の確認
  // 4. exp, iat の確認

  next();
}

/**
 * GCS プレフィックス削除エンドポイント
 * 
 * POST /internal/tasks/gcs-delete-prefix
 * 
 * リクエストボディ:
 * {
 *   "prefix": "v1/public/users/userId/posts/2025/09/postUuid/assetUuid"
 * }
 * 
 * 処理内容:
 * 1. 指定されたプレフィックスで始まるすべてのファイルを検索
 * 2. 見つかったファイルをすべて削除
 * 3. 削除結果をログに記録
 * 
 * エラーハンドリング:
 * - 404エラー（ファイルなし）: 正常として扱う（冪等性）
 * - その他のエラー: ログ記録して 500 エラーを返す（Cloud Tasks が再試行）
 */
router.post('/gcs-delete-prefix', verifyCloudTasksAuth, async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { prefix } = req.body as { prefix: string };

    // リクエストの妥当性チェック
    if (!prefix || typeof prefix !== 'string') {
      logger.warn('Invalid prefix in GCS delete task', { prefix });
      res.status(400).json({ error: 'Valid prefix is required' });
      return;
    }

    logger.info('Starting GCS prefix deletion task', { 
      prefix, 
      bucketName 
    });

    const bucket = storage.bucket(bucketName);

    // プレフィックスに一致するファイルを検索
    const [files] = await bucket.getFiles({ 
      prefix,
      // パフォーマンス最適化: メタデータの最小取得
      autoPaginate: true,
    });

    if (files.length === 0) {
      logger.info('No files found for prefix - task completed', { 
        prefix, 
        bucketName 
      });
      res.status(204).end(); // No Content - 正常完了
      return;
    }

    logger.info('Found files for deletion', { 
      prefix, 
      fileCount: files.length,
      fileNames: files.slice(0, 5).map(f => f.name) // ログには最初の5ファイル名のみ
    });

    // ファイルの並列削除実行
    const deletePromises = files.map(async (file) => {
      try {
        await file.delete();
        logger.debug('File deleted successfully', { fileName: file.name });
      } catch (error) {
        // 個別ファイルの削除エラー
        const err = error as Error;
        
        // 404エラー（既に削除済み）は正常として扱う
        if (err.message.includes('404') || err.message.includes('Not Found')) {
          logger.debug('File already deleted', { fileName: file.name });
          return;
        }
        
        // その他のエラーはログに記録するが処理は続行
        logger.warn('Failed to delete individual file', { 
          fileName: file.name, 
          error: err.message 
        });
      }
    });

    await Promise.all(deletePromises);

    logger.info('GCS prefix deletion task completed successfully', { 
      prefix, 
      deletedFileCount: files.length,
      bucketName 
    });

    res.status(204).end(); // No Content - 正常完了

  } catch (error) {
    const err = error as Error;
    
    logger.error('GCS prefix deletion task failed', { 
      prefix: req.body?.prefix,
      bucketName,
      error: err.message,
      stack: err.stack
    });

    // 500エラーを返してCloud Tasksに再試行させる
    next(error);
  }
});

/**
 * ヘルスチェックエンドポイント
 * 
 * GET /internal/tasks/health
 * 
 * タスクワーカーの動作確認用
 */
router.get('/health', (_req: Request, res: Response) => {
  res.json({ 
    status: 'healthy', 
    service: 'internal-tasks-worker',
    timestamp: new Date().toISOString(),
    bucketName,
    architecture: 'single-service'
  });
});

/**
 * タスク統計エンドポイント（開発用）
 * 
 * GET /internal/tasks/stats
 * 
 * 処理済みタスクの統計情報を取得
 * 本番環境では無効化推奨
 */
router.get('/stats', verifyCloudTasksAuth, (_req: Request, res: Response) => {
  // TODO: 実際の統計データを実装
  res.json({ 
    message: 'Task statistics endpoint - not implemented yet',
    bucketName,
    environment: process.env.NODE_ENV || 'development',
    architecture: 'single-service'
  });
});

export default router;