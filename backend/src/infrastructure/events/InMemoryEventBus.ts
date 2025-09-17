import { IEventBus } from '../../domain/services/IEventBus';
import logger from '../../utils/logger';

/**
 * インメモリイベントバス実装
 * 
 * クリーンアーキテクチャにおける位置づけ:
 * - Infrastructure 層の具体実装
 * - IEventBusインターフェースの実装
 * - シンプルなインメモリでのイベント配信を提供
 * 
 * 特徴:
 * - 同期的なイベント配信（リクエスト内で完結）
 * - Map構造でイベントタイプ別ハンドラー管理
 * - エラーハンドリングとログ出力
 * - 複数ハンドラーの並列実行サポート
 */
export class InMemoryEventBus implements IEventBus {
  private handlers: Map<string, Array<(event: any) => Promise<void>>> = new Map();

  /**
   * イベントハンドラーを登録
   * 
   * @param eventType イベントタイプ（例: 'TweetDeleted'）
   * @param handler イベント処理関数
   */
  subscribe(eventType: string, handler: (event: any) => Promise<void>): void {
    if (!this.handlers.has(eventType)) {
      this.handlers.set(eventType, []);
    }

    const eventHandlers = this.handlers.get(eventType)!;
    eventHandlers.push(handler);

    logger.debug('Event handler registered', {
      eventType,
      handlerCount: eventHandlers.length
    });
  }

  /**
   * イベントを発行し、登録されたハンドラーを実行
   * 
   * 処理の流れ:
   * 1. イベントタイプに対応するハンドラーを取得
   * 2. 全ハンドラーを並列実行
   * 3. エラー発生時はログに記録し、例外を再スロー
   * 
   * @param event 発行するドメインイベント
   */
  async publish(event: any): Promise<void> {
    const eventType = event.eventType;
    const eventHandlers = this.handlers.get(eventType) || [];

    if (eventHandlers.length === 0) {
      logger.debug('No handlers registered for event type', {
        eventType,
        event: this.getEventSummary(event)
      });
      return;
    }

    logger.info('Publishing event to handlers', {
      eventType,
      handlerCount: eventHandlers.length,
      event: this.getEventSummary(event)
    });

    try {
      // 全ハンドラーを並列実行
      await Promise.all(
        eventHandlers.map(async (handler, index) => {
          try {
            await handler(event);
            logger.debug('Event handler executed successfully', {
              eventType,
              handlerIndex: index,
              event: this.getEventSummary(event)
            });
          } catch (error) {
            logger.error('Event handler execution failed', {
              eventType,
              handlerIndex: index,
              error: error instanceof Error ? error.message : 'Unknown error',
              stack: error instanceof Error ? error.stack : undefined,
              event: this.getEventSummary(event)
            });
            throw error; // 個別ハンドラーのエラーを上位に伝播
          }
        })
      );

      logger.info('All event handlers executed successfully', {
        eventType,
        handlerCount: eventHandlers.length,
        event: this.getEventSummary(event)
      });

    } catch (error) {
      logger.error('Event publication failed', {
        eventType,
        handlerCount: eventHandlers.length,
        error: error instanceof Error ? error.message : 'Unknown error',
        event: this.getEventSummary(event)
      });
      throw error;
    }
  }

  /**
   * ログ出力用のイベント概要を取得
   * 
   * @param event イベントオブジェクト
   * @returns イベント概要文字列またはオブジェクト
   */
  private getEventSummary(event: any): string | object {
    // getSummaryメソッドがある場合はそれを使用
    if (typeof event.getSummary === 'function') {
      return event.getSummary();
    }

    // それ以外の場合は基本プロパティを返す
    return {
      eventType: event.eventType,
      occurredAt: event.occurredAt,
      ...Object.keys(event).reduce((acc, key) => {
        // 関数以外のプロパティのみ抽出
        if (typeof event[key] !== 'function') {
          acc[key] = event[key];
        }
        return acc;
      }, {} as any)
    };
  }

  /**
   * 登録されているハンドラー情報を取得（デバッグ用）
   */
  getHandlerInfo(): Record<string, number> {
    const info: Record<string, number> = {};
    this.handlers.forEach((handlers, eventType) => {
      info[eventType] = handlers.length;
    });
    return info;
  }
}