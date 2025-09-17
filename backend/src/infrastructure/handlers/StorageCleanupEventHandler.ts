import { TweetDeletedEvent } from '../../domain/events/TweetDeletedEvent';
import { enqueueDeletePrefixes } from '../../services/storageCleanupPublisher';
import logger from '../../utils/logger';

/**
 * ストレージクリーンアップイベントハンドラー
 * 
 * クリーンアーキテクチャにおける位置づけ:
 * - Infrastructure 層のイベントハンドラー
 * - ドメインイベント（TweetDeletedEvent）を受け取り、外部システム（GCS）との連携を実行
 * - ドメインロジックとインフラロジックの分離を実現
 * 
 * 責務:
 * - TweetDeletedEventを受信
 * - Cloud Tasks経由でGCS削除処理をスケジュール
 * - エラー処理とログ出力
 */
export class StorageCleanupEventHandler {
  /**
   * ツイート削除イベントを処理してGCS削除をスケジュール
   * 
   * 処理の流れ:
   * 1. TweetDeletedEventからストレージプレフィックスを取得
   * 2. プレフィックスが存在する場合、Cloud Tasksでの削除をスケジュール
   * 3. 成功/失敗をログに記録
   * 
   * @param event ツイート削除イベント
   */
  async handle(event: TweetDeletedEvent): Promise<void> {
    try {
      logger.info('Processing TweetDeletedEvent for storage cleanup', {
        tweetId: event.tweetId,
        userId: event.userId,
        prefixCount: event.storagePrefixes.length,
        eventType: event.eventType,
        occurredAt: event.occurredAt
      });

      // ストレージプレフィックスが存在する場合のみ削除処理を実行
      if (event.hasStoragePrefixes()) {
        await enqueueDeletePrefixes(event.storagePrefixes);
        
        logger.info('Storage cleanup tasks enqueued successfully', {
          tweetId: event.tweetId,
          userId: event.userId,
          prefixCount: event.storagePrefixes.length,
          summary: event.getSummary()
        });
      } else {
        logger.info('No storage prefixes to clean up', {
          tweetId: event.tweetId,
          userId: event.userId,
          summary: event.getSummary()
        });
      }

    } catch (error) {
      logger.error('Failed to process storage cleanup for tweet deletion', {
        tweetId: event.tweetId,
        userId: event.userId,
        prefixCount: event.storagePrefixes.length,
        error: error instanceof Error ? error.message : 'Unknown error',
        stack: error instanceof Error ? error.stack : undefined,
        summary: event.getSummary()
      });

      // エラーを再スローして上位レイヤーでの適切な処理を促す
      // ただし、ストレージ削除の失敗はツイート削除自体の失敗とはしない設計も考えられる
      throw error;
    }
  }
}