/**
 * いいねリポジトリインターフェース
 *
 * クリーンアーキテクチャにおける位置づけ:
 * - Domain 層のインターフェース
 * - いいねデータアクセスの抽象化を提供
 * - インフラストラクチャの詳細に依存しない
 */

/** いいね付与の結果 */
export interface LikeResult {
  /** 今回新しく挿入されたか（既にいいね済みなら false） */
  inserted: boolean;
  /** 更新後の tweets.liked_counts */
  likedCount: number;
  /** 投稿者のユーザーID（通知イベント用） */
  tweetOwnerUserId: string;
}

/** いいね解除の結果 */
export interface UnlikeResult {
  /** 今回実際に削除されたか（元々いいねが無ければ false） */
  deleted: boolean;
  /** 更新後の tweets.liked_counts */
  likedCount: number;
}

export interface ILikeRepository {
  /**
   * ツイートにいいねを付ける（冪等）
   * - tweet_likes へ INSERT ... ON CONFLICT DO NOTHING
   * - 挿入できた時だけ tweets.liked_counts を +1（同一トランザクション）
   * @throws ApiError(404) ツイートが存在しない
   */
  like(tweetId: number, userId: string): Promise<LikeResult>;

  /**
   * ツイートのいいねを外す（冪等）
   * - tweet_likes から DELETE
   * - 削除できた時だけ tweets.liked_counts を -1（0 未満にはしない。同一トランザクション）
   * @throws ApiError(404) ツイートが存在しない
   */
  unlike(tweetId: number, userId: string): Promise<UnlikeResult>;
}
