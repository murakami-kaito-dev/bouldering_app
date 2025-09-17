import { CloudTasksClient } from '@google-cloud/tasks';
// import { StoragePathService } from '../domain/services/StoragePathService';  // 2025.09.15 リファクタリング予定
import logger from '../utils/logger';

/**
 * ストレージクリーンアップ管理サービス (Cloud Tasks版)
 *
 * 役割:
 * - GCS からのメディアファイル削除を Cloud Tasks で管理
 * - 失敗時の自動再試行機能を提供
 * - UIをブロックしない非同期削除を実現
 *
 * 実装方針:
 * - Cloud Tasks の HTTP タスクでGCS削除を実行
 * - 各プレフィックス削除を独立したタスクとして処理（再試行単位を細かく）
 * - OIDC認証でセキュアなタスク実行
 *
 * クリーンアーキテクチャにおける位置づけ:
 * - Infrastructure 層のサービス
 * - 外部タスクキューシステム（Cloud Tasks）との通信を担当
 * - TweetService から呼び出される
 */

export class StorageCleanupPublisher {
  private client: CloudTasksClient;
  private project: string;
  private location: string;
  private queue: string;
  private handlerUrl: string;
  private serviceAccountEmail: string;

  constructor() {
    this.client = new CloudTasksClient();

    // 環境変数から設定を読み込み
    this.project = process.env.GCP_PROJECT || '';
    this.location = process.env.TASKS_LOCATION || 'asia-northeast1';
    this.queue = process.env.TASKS_QUEUE_ID || 'gcs-delete-queue';
    this.handlerUrl = process.env.TASKS_HANDLER_URL || '';
    this.serviceAccountEmail = process.env.TASKS_SA_EMAIL || '';

    // 必須環境変数のチェック
    this.validateConfiguration();
  }

  /**
   * GCS プレフィックス削除タスクをキューに登録
   *
   * 処理の流れ:
   * 1. 各プレフィックスを独立したタスクとして作成
   * 2. Cloud Tasks キューに HTTP タスクとして登録
   * 3. 指定した内部エンドポイント (/internal/tasks/gcs-delete-prefix) に POST リクエスト
   * 4. ワーカーが実際のGCS削除を実行
   *
   * @param prefixes 削除対象のストレージプレフィックス配列
   * @example
   * // 使用例
   * await enqueueDeletePrefixes([
   *   'v1/public/users/user123/posts/2025/09/post456/asset789',
   *   'v1/public/users/user123/posts/2025/09/post456/asset101'
   * ]);
   */
  async enqueueDeletePrefixes(prefixes: string[]): Promise<void> {
    if (prefixes.length === 0) {
      logger.info('No prefixes to delete');
      return;
    }

    const uniquePrefixes = Array.from(new Set(prefixes)).filter(Boolean);

    logger.info('Enqueueing GCS prefix deletion tasks', {
      prefixes: uniquePrefixes,
      count: uniquePrefixes.length,
      queue: this.queue,
      location: this.location
    });

    const parent = this.client.queuePath(this.project, this.location, this.queue);

    // 各プレフィックスを独立したタスクとして処理
    const taskPromises = uniquePrefixes.map(async (prefix) => {
      try {
        const payload = { prefix };
        const body = Buffer.from(JSON.stringify(payload)).toString('base64');

        const task = {
          httpRequest: {
            httpMethod: 'POST' as const,
            url: this.handlerUrl,
            headers: {
              'Content-Type': 'application/json'
            },
            body,
            // OIDC認証でセキュアにタスクを実行
            oidcToken: {
              serviceAccountEmail: this.serviceAccountEmail
            },
          },
          // タスクの設定
          scheduleTime: {
            seconds: Math.floor(Date.now() / 1000) + 1, // 1秒後に実行
          },
        };

        await this.client.createTask({ parent, task });

        logger.debug('GCS deletion task created successfully', { prefix });

      } catch (error) {
        logger.error('Failed to create GCS deletion task', {
          prefix,
          error: error instanceof Error ? error.message : 'Unknown error',
          stack: error instanceof Error ? error.stack : undefined
        });
        throw error; // タスク作成失敗は上位で適切に処理
      }
    });

    // すべてのタスク作成を並列実行
    await Promise.all(taskPromises);

    logger.info('All GCS deletion tasks enqueued successfully', {
      count: uniquePrefixes.length
    });
  }

  /**
   * 単一メディアURLの削除タスクをスケジュール
   *
   * URLからプレフィックスを導出してタスクをキューに登録
   *
   * @param mediaUrl 削除対象のメディアURL
   * @example
   * await enqueueMediaDeletion('https://storage.googleapis.com/bucket/v1/public/users/.../original.jpeg');
   */
  async enqueueMediaDeletion(mediaUrl: string): Promise<void> {
    const prefix = this.derivePrefixFromUrl(mediaUrl);
    if (prefix) {
      await this.enqueueDeletePrefixes([prefix]);
    } else {
      logger.warn('Could not derive prefix from URL, skipping deletion', { mediaUrl });
    }
  }

  /**
   * メディアURLからストレージプレフィックスを導出
   *
   * URL構造: https://storage.googleapis.com/{bucket}/{prefix}/original.{ext}
   * 例: https://storage.googleapis.com/bucket/v1/public/users/user123/posts/2025/09/post456/asset789/original.jpeg
   * 結果: v1/public/users/user123/posts/2025/09/post456/asset789
   *
   * @param url メディアURL
   * @returns ストレージプレフィックス（失敗時はnull）
   */
  private derivePrefixFromUrl(url: string): string | null {
    try {
      const urlObj = new URL(url);
      const pathParts = urlObj.pathname.split('/').filter(part => part.length > 0);

      // pathParts: [bucket, v1, public, users, userId, posts, yyyy, mm, postUuid, assetUuid, original.jpeg]
      // バケット名を除外し、ファイル名も除外してプレフィックスを構成
      if (pathParts.length < 3) {
        return null;
      }

      // バケット名（最初）とファイル名（最後）を除外
      const prefixParts = pathParts.slice(1, -1);
      return prefixParts.join('/');

    } catch (error) {
      logger.warn('Failed to derive prefix from URL', { url, error });
      return null;
    }
  }

  /**
   * Cloud Tasks 設定の妥当性チェック
   */
  private validateConfiguration(): void {
    const requiredVars = [
      { name: 'GCP_PROJECT', value: this.project },
      { name: 'TASKS_HANDLER_URL', value: this.handlerUrl },
      { name: 'TASKS_SA_EMAIL', value: this.serviceAccountEmail },
    ];

    const missingVars = requiredVars.filter(v => !v.value);

    if (missingVars.length > 0) {
      const missing = missingVars.map(v => v.name).join(', ');
      logger.error('Missing required environment variables for Cloud Tasks', {
        missingVariables: missing
      });
      throw new Error(`Missing required environment variables: ${missing}`);
    }

    logger.info('Cloud Tasks configuration validated', {
      project: this.project,
      location: this.location,
      queue: this.queue,
      handlerUrl: this.handlerUrl,
      serviceAccountEmail: this.serviceAccountEmail,
    });
  }
}

/**
 * シングルトンインスタンス
 * 単一サービス構成用
 */
function createStorageCleanupPublisher(): StorageCleanupPublisher | null {
  const requiredEnvVars = ['GCP_PROJECT', 'TASKS_HANDLER_URL', 'TASKS_SA_EMAIL'];
  const missingVars = requiredEnvVars.filter(varName => !process.env[varName]);

  if (missingVars.length > 0) {
    console.warn(`Storage cleanup publisher disabled - missing env vars: ${missingVars.join(', ')}`);
    console.warn('GCS deletion tasks will be skipped');
    return null;
  }

  console.info('Storage cleanup publisher initialized for single service architecture');
  return new StorageCleanupPublisher();
}

export const storageCleanupPublisher = createStorageCleanupPublisher();

/**
 * 便利関数: プレフィックス削除タスクのスケジュール
 *
 * @param prefixes 削除対象のプレフィックス配列
 */
export async function enqueueDeletePrefixes(prefixes: string[]): Promise<void> {
  if (!storageCleanupPublisher) {
    console.warn('Storage cleanup publisher not available - skipping deletion task');
    return;
  }
  await storageCleanupPublisher.enqueueDeletePrefixes(prefixes);
}

/**
 * 便利関数: メディアURL削除タスクのスケジュール
 *
 * @param mediaUrl 削除対象のメディアURL
 */
export async function enqueueDeleteMediaUrl(mediaUrl: string): Promise<void> {
  if (!storageCleanupPublisher) {
    console.warn('Storage cleanup publisher not available - skipping deletion task');
    return;
  }
  await storageCleanupPublisher.enqueueMediaDeletion(mediaUrl);
}
