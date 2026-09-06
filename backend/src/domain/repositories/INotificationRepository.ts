/**
 * 通知リポジトリインターフェース（Issue #81）
 *
 * クリーンアーキテクチャにおける位置づけ:
 * - Domain 層のインターフェース
 * - 通知データアクセスの抽象化を提供
 */

export type NotificationType = 'like' | 'comment' | 'reply';

/** 通知一覧の 1 要素のアクター（いいねの集約時は最大 6 人） */
export interface NotificationActor {
  user_id: string;
  user_name: string;
  user_icon_url: string | null;
}

/** 通知一覧の 1 要素（いいねは同じツイートへのものを 1 行に集約済み） */
export interface NotificationRow {
  /** 代表行（集約グループの最新行）の ID */
  notification_id: number;
  type: NotificationType;
  actors: NotificationActor[];
  /** 集約されたアクターの総数（actors は先頭 6 人まで） */
  actor_count: number;
  tweet: {
    tweet_id: number;
    gym_name: string | null;
    /** 本文の冒頭 40 字 */
    content_head: string;
  } | null;
  comment: {
    comment_id: number;
    /** コメント本文の冒頭 40 字（削除済みは ""） */
    content_head: string;
  } | null;
  /** グループ内の全行が既読なら true */
  is_read: boolean;
  /** 代表行の作成日時（次ページのカーソルに使う） */
  created_at: Date;
}

export interface INotificationRepository {
  /**
   * like 通知を作る（同じ (受信者, アクター, ツイート) が既にあれば何もしない）
   * @returns 挿入されたか
   */
  createLikeNotification(recipientUserId: string, actorUserId: string, tweetId: number): Promise<boolean>;

  /** いいね解除に対応する like 通知を消す */
  deleteLikeNotification(actorUserId: string, tweetId: number): Promise<number>;

  /** comment / reply 通知を作る */
  createCommentNotification(
    recipientUserId: string,
    actorUserId: string,
    type: 'comment' | 'reply',
    tweetId: number,
    commentId: number
  ): Promise<void>;

  /** 2 人の間にブロック関係（どちら向きでも）があるか */
  hasBlockRelation(userIdA: string, userIdB: string): Promise<boolean>;

  /**
   * 通知一覧（新しい順・いいねは集約済み・ブロック関係のアクターは除外）
   * @param cursor 前ページ最後の created_at（これより古いものを返す）
   */
  listNotifications(recipientUserId: string, limit: number, cursor?: string): Promise<NotificationRow[]>;

  /** 未読の件数（一覧と同じ集約単位で数える） */
  countUnread(recipientUserId: string): Promise<number>;

  /**
   * 既読にする
   * @param upToId 指定があればその ID 以下だけ。無ければ全部
   * @returns 更新した行数
   */
  markRead(recipientUserId: string, upToId?: number): Promise<number>;
}
