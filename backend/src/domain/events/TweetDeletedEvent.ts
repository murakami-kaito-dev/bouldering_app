/**
 * ツイート削除イベント
 * 
 * クリーンアーキテクチャにおける位置づけ:
 * - Domain 層のイベント
 * - ツイート削除時に発生するドメインイベント
 * - インフラストラクチャの詳細を含まない純粋なドメインロジック
 */

export class TweetDeletedEvent {
  public readonly eventType = 'TweetDeleted';
  public readonly occurredAt: Date;

  constructor(
    public readonly tweetId: number,
    public readonly userId: string,
    public readonly storagePrefixes: string[]
  ) {
    this.occurredAt = new Date();
  }

  /**
   * イベントに削除対象のプレフィックスが含まれているかチェック
   */
  public hasStoragePrefixes(): boolean {
    return this.storagePrefixes.length > 0;
  }

  /**
   * イベントの概要を文字列で返す（ログ出力用）
   */
  public getSummary(): string {
    return `Tweet ${this.tweetId} deleted by user ${this.userId} with ${this.storagePrefixes.length} storage prefixes`;
  }
}