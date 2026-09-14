/**
 * ツイートいいね解除イベント
 *
 * クリーンアーキテクチャにおける位置づけ:
 * - Domain 層のイベント
 * - ツイートの「いいね」が実際に取り消されたときに発生する（元々無かった場合は発生しない）
 * - 通知機能（Issue #81）がこのイベントを購読して対応する like 通知を削除する
 */
export class TweetUnlikedEvent {
  public readonly eventType = 'TweetUnliked';
  public readonly occurredAt: Date;

  constructor(
    public readonly tweetId: number,
    public readonly likerUserId: string
  ) {
    this.occurredAt = new Date();
  }

  /**
   * イベントの概要を文字列で返す（ログ出力用）
   */
  public getSummary(): string {
    return `Tweet ${this.tweetId} unliked by user ${this.likerUserId}`;
  }
}
