import { Tweet, TweetMedia } from '../../models/types';

/**
 * ツイートリポジトリインターface
 * 
 * クリーンアーキテクチャにおける位置づけ:
 * - Domain 層のインターface
 * - データアクセスの抽象化を提供
 * - インフラストラクチャの詳細に依存しない
 */

export interface ITweetRepository {
  /**
   * 全ツイート取得（ページネーション付き）
   */
  getAllTweets(limit: number, cursor?: string): Promise<any[]>;

  /**
   * ユーザーのツイート取得
   */
  getUserTweets(userId: string, limit: number, cursor?: string): Promise<any[]>;

  /**
   * IDでツイート取得
   */
  getTweetById(tweetId: number): Promise<any | null>;

  /**
   * ツイート作成
   */
  createTweet(tweetData: {
    user_id: string;
    gym_id: number;
    tweet_contents: string;
    visited_date?: Date;
    movie_url?: string;
    media_urls?: string[];
    media_metadata?: any[];
    post_uuid?: string;
  }): Promise<Tweet>;

  /**
   * ツイート更新
   */
  updateTweet(
    tweetId: number,
    userId: string,
    updateData: {
      tweet_contents?: string;
      visited_date?: Date;
      gym_id?: number;
      media_urls?: string[];
    }
  ): Promise<Tweet>;

  /**
   * ツイート削除
   * @param tweetId 削除対象のツイートID
   * @param userId 削除を実行するユーザーID
   */
  deleteTweet(tweetId: number, userId: string): Promise<void>;

  /**
   * ツイートに関連するメディア情報を取得（削除用）
   * @param tweetId ツイートID
   * @returns メディアURLの配列
   */
  getTweetMediaUrls(tweetId: number): Promise<string[]>;


  /**
   * ツイートにメディア追加
   */
  addTweetMedia(
    tweetId: number,
    userId: string,
    mediaData: {
      media_url: string;
      media_type: string;
    }
  ): Promise<void>;

  /**
   * ツイートからメディア削除
   */
  deleteTweetMedia(tweetId: number, userId: string, mediaUrl: string): Promise<void>;
}