/**
 * コメント作成イベント
 *
 * クリーンアーキテクチャにおける位置づけ:
 * - Domain 層のイベント
 * - ツイートへのコメント（返信を含む）が作成されたときに発生するドメインイベント
 * - 通知機能（Issue #81）がこのイベントを購読して、投稿者・返信先へ通知を作る
 *
 * 契約（social-spec.md「2. スレッド」）:
 *   CommentCreatedEvent { commentId, tweetId, tweetOwnerUserId, commenterUserId,
 *                         parentCommentId?, parentCommentOwnerUserId? }
 */

export class CommentCreatedEvent {
  public readonly eventType = 'CommentCreated';
  public readonly occurredAt: Date;

  constructor(
    public readonly commentId: number,
    public readonly tweetId: number,
    public readonly tweetOwnerUserId: string,
    public readonly commenterUserId: string,
    public readonly parentCommentId?: number,
    public readonly parentCommentOwnerUserId?: string
  ) {
    this.occurredAt = new Date();
  }

  /** 返信（親コメントあり）か */
  public isReply(): boolean {
    return this.parentCommentId !== undefined && this.parentCommentId !== null;
  }

  /** イベントの概要（ログ出力用） */
  public getSummary(): string {
    const reply = this.isReply()
      ? ` (reply to comment ${this.parentCommentId} by ${this.parentCommentOwnerUserId})`
      : '';
    return `Comment ${this.commentId} on tweet ${this.tweetId} (owner ${this.tweetOwnerUserId}) by ${this.commenterUserId}${reply}`;
  }
}
