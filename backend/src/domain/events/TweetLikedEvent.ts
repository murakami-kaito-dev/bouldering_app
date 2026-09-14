/**
 * ツイートいいねイベント
 *
 * クリーンアーキテクチャにおける位置づけ:
 * - Domain 層のイベント
 * - ツイートに「いいね」が新規に付いたときに発生する（冪等な再送では発生しない）
 * - 通知機能（Issue #81）がこのイベントを購読して投稿者へ通知を作る
 */
export class TweetLikedEvent {
  public readonly eventType = 'TweetLiked';
  public readonly occurredAt: Date;

  constructor(
    public readonly tweetId: number,
    public readonly tweetOwnerUserId: string,
    public readonly likerUserId: string
  ) {
    this.occurredAt = new Date();
  }

  /**
   * イベントの概要を文字列で返す（ログ出力用）
   */
  public getSummary(): string {
    return `Tweet ${this.tweetId} (owner ${this.tweetOwnerUserId}) liked by user ${this.likerUserId}`;
  }
}
