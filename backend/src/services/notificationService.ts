import {
  INotificationRepository,
  NotificationRow,
} from '../domain/repositories/INotificationRepository';
import { IEventBus } from '../domain/services/IEventBus';
import { TweetLikedEvent } from '../domain/events/TweetLikedEvent';
import { TweetUnlikedEvent } from '../domain/events/TweetUnlikedEvent';
import { CommentCreatedEvent } from '../domain/events/CommentCreatedEvent';
import logger from '../utils/logger';

/**
 * 通知サービス（Issue #81）
 *
 * クリーンアーキテクチャにおける位置づけ:
 * - Application 層のサービス
 * - いいね／コメントのドメインイベントを購読して通知行を作り、一覧・未読数・既読化を提供する
 *
 * 生成ルール（social-spec.md「3. 通知」）:
 * - TweetLiked   → 投稿者へ like（自分の投稿への自分のいいねは作らない）
 * - TweetUnliked → 対応する like 通知を削除
 * - CommentCreated → 投稿者へ comment（自分なら作らない）。親コメントがあれば親の投稿者へ reply
 *   （自分なら作らない。投稿者＝親コメント主なら reply の 1 件だけ）
 * - ブロック関係（どちら向きでも）の相手には作らない（読み出し側でも除外するが、行自体を残さない）
 *
 * ハンドラー内の失敗はログのみ（いいね／コメント自体は既に確定しているため、発行元へは伝播させない）
 */
export class NotificationService {
  constructor(private notificationRepository: INotificationRepository) {}

  /** イベントバスへ購読を登録する（dependencies.ts の setupEventSystem から呼ぶ） */
  registerHandlers(eventBus: IEventBus): void {
    eventBus.subscribe('TweetLiked', (event) => this.handleTweetLiked(event));
    eventBus.subscribe('TweetUnliked', (event) => this.handleTweetUnliked(event));
    eventBus.subscribe('CommentCreated', (event) => this.handleCommentCreated(event));
  }

  async handleTweetLiked(event: TweetLikedEvent): Promise<void> {
    try {
      if (event.tweetOwnerUserId === event.likerUserId) {
        return; // 自分の投稿への自分のいいね
      }
      if (await this.notificationRepository.hasBlockRelation(event.tweetOwnerUserId, event.likerUserId)) {
        return;
      }
      const inserted = await this.notificationRepository.createLikeNotification(
        event.tweetOwnerUserId,
        event.likerUserId,
        event.tweetId
      );
      logger.info('Like notification handled', { summary: event.getSummary(), inserted });
    } catch (error) {
      logger.error('Failed to handle TweetLikedEvent for notification', {
        summary: event.getSummary(),
        error: error instanceof Error ? error.message : 'Unknown error',
      });
    }
  }

  async handleTweetUnliked(event: TweetUnlikedEvent): Promise<void> {
    try {
      const deleted = await this.notificationRepository.deleteLikeNotification(
        event.likerUserId,
        event.tweetId
      );
      logger.info('Unlike notification handled', { summary: event.getSummary(), deleted });
    } catch (error) {
      logger.error('Failed to handle TweetUnlikedEvent for notification', {
        summary: event.getSummary(),
        error: error instanceof Error ? error.message : 'Unknown error',
      });
    }
  }

  async handleCommentCreated(event: CommentCreatedEvent): Promise<void> {
    try {
      const commenter = event.commenterUserId;
      const tweetOwner = event.tweetOwnerUserId;
      const parentOwner = event.isReply() ? event.parentCommentOwnerUserId : undefined;

      // 返信先（親コメント主）への reply。投稿者＝親コメント主ならこの 1 件だけにする
      if (parentOwner && parentOwner !== commenter) {
        if (!(await this.notificationRepository.hasBlockRelation(parentOwner, commenter))) {
          await this.notificationRepository.createCommentNotification(
            parentOwner, commenter, 'reply', event.tweetId, event.commentId
          );
        }
      }

      // 投稿者への comment（親コメント主と同一人物なら上の reply で済んでいる）
      if (tweetOwner !== commenter && tweetOwner !== parentOwner) {
        if (!(await this.notificationRepository.hasBlockRelation(tweetOwner, commenter))) {
          await this.notificationRepository.createCommentNotification(
            tweetOwner, commenter, 'comment', event.tweetId, event.commentId
          );
        }
      }

      logger.info('Comment notification handled', { summary: event.getSummary() });
    } catch (error) {
      logger.error('Failed to handle CommentCreatedEvent for notification', {
        summary: event.getSummary(),
        error: error instanceof Error ? error.message : 'Unknown error',
      });
    }
  }

  /** 通知一覧（新しい順・いいね集約済み） */
  async getNotifications(userId: string, limit: number = 30, cursor?: string): Promise<NotificationRow[]> {
    return await this.notificationRepository.listNotifications(userId, limit, cursor);
  }

  /** 未読数 */
  async getUnreadCount(userId: string): Promise<number> {
    return await this.notificationRepository.countUnread(userId);
  }

  /** 既読化（upToId 以下 or 全部） */
  async markRead(userId: string, upToId?: number): Promise<number> {
    const updated = await this.notificationRepository.markRead(userId, upToId);
    logger.info('Notifications marked read', { userId, upToId: upToId ?? null, updated });
    return updated;
  }
}
