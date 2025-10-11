import { Tweet } from '../models/types';
import { ApiError } from '../middleware/error';
import { ITweetRepository } from '../domain/repositories/ITweetRepository';
import { IEventBus } from '../domain/services/IEventBus';
import { TweetDeletedEvent } from '../domain/events/TweetDeletedEvent';
import logger from '../utils/logger';

/**
 * ツイートサービス
 * 
 * クリーンアーキテクチャにおける位置づけ:
 * - Application 層のサービス
 * - ビジネスロジックの実装
 * - リポジトリとイベントバスを通じた処理の調整
 */
export class TweetService {
  constructor(
    private tweetRepository: ITweetRepository,
    private eventBus: IEventBus
  ) {}

  /**
   * 全ツイート取得（ページネーション付き）
   * @param limit 取得件数
   * @param cursor ページネーション用カーソル
   * @param requestUserId リクエストユーザーID（ブロック関係のフィルタリング用）
   */
  async getAllTweets(limit: number = 20, cursor?: string, requestUserId?: string): Promise<any[]> {
    return await this.tweetRepository.getAllTweets(limit, cursor, requestUserId);
  }

  /**
   * ユーザーのツイート取得
   */
  async getUserTweets(userId: string, limit: number = 20, cursor?: string): Promise<any[]> {
    return await this.tweetRepository.getUserTweets(userId, limit, cursor);
  }

  /**
   * IDでツイート取得
   */
  async getTweetById(tweetId: number): Promise<any | null> {
    return await this.tweetRepository.getTweetById(tweetId);
  }

  /**
   * ツイート作成
   */
  async createTweet(tweetData: {
    user_id: string;
    gym_id: number;
    tweet_contents: string;
    visited_date?: Date;
    movie_url?: string;
    media_urls?: string[];
    media_metadata?: any[];
    post_uuid?: string;
  }): Promise<Tweet> {
    const tweet = await this.tweetRepository.createTweet(tweetData);
    
    logger.info('Tweet created successfully via service', {
      tweetId: tweet.tweet_id,
      userId: tweetData.user_id,
      gymId: tweetData.gym_id
    });
    
    return tweet;
  }

  /**
   * ツイート更新
   */
  async updateTweet(
    tweetId: number,
    userId: string,
    updateData: {
      tweet_contents?: string;
      visited_date?: Date;
      gym_id?: number;
      media_urls?: string[];
    }
  ): Promise<Tweet> {
    const updatedTweet = await this.tweetRepository.updateTweet(tweetId, userId, updateData);
    
    logger.info('Tweet updated successfully via service', {
      tweetId,
      userId,
      updatedFields: Object.keys(updateData)
    });
    
    return updatedTweet;
  }

  /**
   * ツイート削除
   * 
   * 処理の流れ:
   * 1. 削除前にGCS削除用のstorage_prefixを取得
   * 2. データベースからツイート削除（権限チェック + 削除を同時実行）
   * 3. 取得したstorage_prefixでGCS削除イベントを発行
   */
  async deleteTweet(tweetId: number, userId: string): Promise<void> {
    try {
      // 1. GCS削除用のストレージプレフィックスを取得（削除前に）
      const uniquePrefixes = await this.tweetRepository.getTweetMediaUrls(tweetId);

      // 2. データベースからツイート削除（権限チェック + 削除を同時実行、競合状態を防ぐ）
      await this.tweetRepository.deleteTweet(tweetId, userId);

      logger.info('Tweet deleted successfully', { 
        tweetId, 
        userId,
        prefixCount: uniquePrefixes.length
      });

      // 4. GCS削除イベントを発行
      if (uniquePrefixes.length > 0) {
        try {
          const event = new TweetDeletedEvent(tweetId, userId, uniquePrefixes);
          await this.eventBus.publish(event);
          logger.info('TweetDeletedEvent published successfully', { 
            tweetId, 
            prefixes: uniquePrefixes,
            eventSummary: event.getSummary()
          });
        } catch (error) {
          // GCS削除イベントの失敗はログのみ（ツイート削除は既に成功）
          logger.error('Failed to publish TweetDeletedEvent', { 
            tweetId, 
            prefixes: uniquePrefixes,
            error: error instanceof Error ? error.message : 'Unknown error'
          });
        }
      } else {
        logger.info('No GCS prefixes to delete', { tweetId });
      }

    } catch (error) {
      if (error instanceof ApiError) throw error;
      logger.error('Error deleting tweet', { tweetId, userId, error });
      throw new ApiError(500, 'Failed to delete tweet');
    }
  }

  /**
   * ツイートにメディア追加
   */
  async addTweetMedia(
    tweetId: number,
    userId: string,
    mediaData: {
      media_url: string;
      media_type: string;
    }
  ): Promise<void> {
    await this.tweetRepository.addTweetMedia(tweetId, userId, mediaData);
    
    logger.info('Media added to tweet successfully via service', {
      tweetId,
      userId,
      mediaUrl: mediaData.media_url
    });
  }

  /**
   * ツイートからメディア削除
   */
  async deleteTweetMedia(tweetId: number, userId: string, mediaUrl: string): Promise<void> {
    await this.tweetRepository.deleteTweetMedia(tweetId, userId, mediaUrl);
    
    logger.info('Media deleted from tweet successfully via service', {
      tweetId,
      userId,
      mediaUrl
    });
  }
}