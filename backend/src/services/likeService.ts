import { ILikeRepository } from '../domain/repositories/ILikeRepository';
import { IEventBus } from '../domain/services/IEventBus';
import { TweetLikedEvent } from '../domain/events/TweetLikedEvent';
import { TweetUnlikedEvent } from '../domain/events/TweetUnlikedEvent';
import logger from '../utils/logger';

/** いいね API の応答（`{ success: true, data: LikeResponse }` の data 部分） */
export interface LikeResponse {
  liked: boolean;
  liked_count: number;
}

/**
 * いいねサービス
 *
 * クリーンアーキテクチャにおける位置づけ:
 * - Application 層のサービス
 * - いいねの付与／解除と、通知向けドメインイベントの発行を調整する
 *
 * ビジネスルール:
 * - 自分の投稿にもいいね可（通知側で「自分→自分」を除外する）
 * - 冪等: 二重いいね／未いいねの解除は DB を変えず、イベントも発行しない
 * - イベント発行の失敗はログのみ（いいね自体は既に確定しているため応答は成功で返す）
 */
export class LikeService {
  constructor(
    private likeRepository: ILikeRepository,
    private eventBus: IEventBus
  ) {}

  /**
   * ツイートにいいねを付ける
   */
  async likeTweet(tweetId: number, likerUserId: string): Promise<LikeResponse> {
    const result = await this.likeRepository.like(tweetId, likerUserId);

    logger.info('Tweet liked via service', {
      tweetId,
      likerUserId,
      inserted: result.inserted,
      likedCount: result.likedCount,
    });

    if (result.inserted) {
      await this.publishSafely(
        new TweetLikedEvent(tweetId, result.tweetOwnerUserId, likerUserId)
      );
    }

    return { liked: true, liked_count: result.likedCount };
  }

  /**
   * ツイートのいいねを外す
   */
  async unlikeTweet(tweetId: number, likerUserId: string): Promise<LikeResponse> {
    const result = await this.likeRepository.unlike(tweetId, likerUserId);

    logger.info('Tweet unliked via service', {
      tweetId,
      likerUserId,
      deleted: result.deleted,
      likedCount: result.likedCount,
    });

    if (result.deleted) {
      await this.publishSafely(new TweetUnlikedEvent(tweetId, likerUserId));
    }

    return { liked: false, liked_count: result.likedCount };
  }

  /**
   * イベント発行（失敗してもいいね処理は成功扱い。tweetService の TweetDeletedEvent と同じ方針）
   */
  private async publishSafely(event: TweetLikedEvent | TweetUnlikedEvent): Promise<void> {
    try {
      await this.eventBus.publish(event);
    } catch (error) {
      logger.error('Failed to publish like event', {
        eventType: event.eventType,
        summary: event.getSummary(),
        error: error instanceof Error ? error.message : 'Unknown error',
      });
    }
  }
}
