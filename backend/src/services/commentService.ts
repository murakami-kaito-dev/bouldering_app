import { ApiError } from '../middleware/error';
import { ICommentRepository, CommentRow } from '../domain/repositories/ICommentRepository';
import { IEventBus } from '../domain/services/IEventBus';
import { CommentCreatedEvent } from '../domain/events/CommentCreatedEvent';
import logger from '../utils/logger';

/**
 * コメント（スレッド）サービス
 *
 * クリーンアーキテクチャにおける位置づけ:
 * - Application 層のサービス
 * - リポジトリで永続化し、作成時に CommentCreatedEvent を発行する（通知チームが購読）
 */
export class CommentService {
  constructor(
    private commentRepository: ICommentRepository,
    private eventBus: IEventBus
  ) {}

  /** コメント一覧（作成日時 昇順・ブロック関係は除外） */
  async getComments(
    tweetId: number,
    limit: number = 50,
    cursor?: string,
    requestUserId?: string
  ): Promise<CommentRow[]> {
    return await this.commentRepository.getComments(tweetId, limit, cursor, requestUserId);
  }

  /** コメント作成（親があれば返信） */
  async createComment(data: {
    tweetId: number;
    userId: string;
    content: string;
    parentCommentId?: number;
  }): Promise<CommentRow> {
    const created = await this.commentRepository.createComment(data);
    const { comment, tweetOwnerUserId, parentCommentOwnerUserId } = created;

    logger.info('Comment created via service', {
      commentId: comment.comment_id,
      tweetId: data.tweetId,
      userId: data.userId,
    });

    // 通知用イベント。失敗してもコメント作成は成功しているのでログのみ
    try {
      const event = new CommentCreatedEvent(
        comment.comment_id,
        data.tweetId,
        tweetOwnerUserId,
        data.userId,
        data.parentCommentId,
        parentCommentOwnerUserId
      );
      await this.eventBus.publish(event);
    } catch (error) {
      logger.error('Failed to publish CommentCreatedEvent', {
        commentId: comment.comment_id,
        error: error instanceof Error ? error.message : 'Unknown error',
      });
    }

    return comment;
  }

  /** 論理削除（コメント本人 または ツイート投稿者） */
  async deleteComment(commentId: number, requestUserId: string): Promise<{ comment_id: number; is_deleted: true }> {
    try {
      return await this.commentRepository.softDeleteComment(commentId, requestUserId);
    } catch (error) {
      if (error instanceof ApiError) throw error;
      logger.error('Error deleting comment via service', { commentId, requestUserId, error });
      throw new ApiError(500, 'Failed to delete comment');
    }
  }
}
