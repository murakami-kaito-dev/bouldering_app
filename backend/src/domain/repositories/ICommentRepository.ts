/**
 * コメントリポジトリインターフェース
 *
 * クリーンアーキテクチャにおける位置づけ:
 * - Domain 層のインターフェース
 * - コメント（スレッド）の永続化を抽象化する
 */

/** 一覧・作成レスポンスで返すコメント 1 件の形（social-spec.md の契約どおり） */
export interface CommentRow {
  comment_id: number;
  tweet_id: number;
  user_id: string;
  user_name: string;
  user_icon_url: string | null;
  parent_comment_id: number | null;
  root_comment_id: number | null;
  reply_to_user_id: string | null;
  reply_to_user_name: string | null;
  content: string; // 削除済みは ""
  is_deleted: boolean;
  created_at: Date;
}

/** 作成結果（レスポンス用の行 + イベント発行に必要な付帯情報） */
export interface CreatedComment {
  comment: CommentRow;
  tweetOwnerUserId: string;
  parentCommentOwnerUserId?: string;
}

export interface ICommentRepository {
  /**
   * ツイートのコメント一覧（作成日時 昇順・フラット）
   * @param requestUserId 認証ユーザー（ブロック関係のコメントを除外する）
   * @param cursor 前ページ最後の created_at（ISO8601）。これより後を返す
   */
  getComments(
    tweetId: number,
    limit: number,
    cursor?: string,
    requestUserId?: string
  ): Promise<CommentRow[]>;

  /** コメント作成（親があれば root / reply_to を導出。comment_counts +1 を同一トランザクションで） */
  createComment(data: {
    tweetId: number;
    userId: string;
    content: string;
    parentCommentId?: number;
  }): Promise<CreatedComment>;

  /**
   * 論理削除（コメント本人 または ツイート投稿者のみ。comment_counts -1 を同一トランザクションで）
   * @returns 削除後のコメント ID（既に削除済みでも成功扱い）
   */
  softDeleteComment(commentId: number, requestUserId: string): Promise<{ comment_id: number; is_deleted: true }>;
}
