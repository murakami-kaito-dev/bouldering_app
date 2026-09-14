import { Router } from 'express';
import { body, param } from 'express-validator';
import { authenticate, optionalAuthenticate, AuthenticatedRequest } from '../middleware/auth';
import { handleValidationErrors } from '../middleware/validation';
import { getCommentService } from '../infrastructure/setup/dependencies';
import { validateTweetId, validatePagination } from '../utils/validation';
import { ApiError } from '../middleware/error';

/**
 * スレッド（コメント・返信）API（Issue #19）
 *
 * 2 つのルーターを公開する（routes/tweets.ts は触らない）:
 * - tweetCommentsRouter … `/api/tweets` にマウント（GET/POST /:tweet_id/comments）
 * - commentsRouter      … `/api/comments` にマウント（DELETE /:comment_id）
 *
 * バリデーションはこのファイル内に閉じる（並行開発中の utils/validation.ts との衝突回避）
 */

const validateCommentId = () =>
  param('comment_id')
    .isInt({ min: 1 })
    .withMessage('Valid comment ID is required');

const validateCreateComment = () => [
  body('content')
    .isString()
    .withMessage('Comment content is required')
    .trim()
    .isLength({ min: 1, max: 400 })
    .withMessage('Comment content must be between 1 and 400 characters'),
  body('parent_comment_id')
    .optional({ nullable: true })
    .isInt({ min: 1 })
    .withMessage('Valid parent comment ID is required')
    .toInt(),
];

const commentService = getCommentService();

// ---------------------------------------------------------------------------
// /api/tweets/:tweet_id/comments
// ---------------------------------------------------------------------------
export const tweetCommentsRouter = Router();

// 46. Get comments of a tweet (created_at ASC, flat, cursor paging)
tweetCommentsRouter.get(
  '/:tweet_id/comments',
  optionalAuthenticate, // 未ログインでも閲覧可。ログイン時はブロック関係を除外
  validateTweetId(),
  validatePagination(),
  handleValidationErrors,
  async (req, res, next) => {
    try {
      const { tweet_id } = req.params;
      const { limit = '50', cursor } = req.query;
      const requestUser = (req as AuthenticatedRequest).user;

      const comments = await commentService.getComments(
        parseInt(tweet_id),
        parseInt(limit as string),
        cursor as string | undefined,
        requestUser?.uid
      );

      res.json({
        success: true,
        data: comments,
      });
    } catch (error) {
      next(error);
    }
  }
);

// 47. Create comment / reply
tweetCommentsRouter.post(
  '/:tweet_id/comments',
  authenticate,
  validateTweetId(),
  validateCreateComment(),
  handleValidationErrors,
  async (req, res, next) => {
    try {
      const { tweet_id } = req.params;
      const { content, parent_comment_id } = req.body;
      const requestUser = (req as AuthenticatedRequest).user;

      if (!requestUser) {
        throw new ApiError(401, 'Authentication required');
      }

      const comment = await commentService.createComment({
        tweetId: parseInt(tweet_id),
        userId: requestUser.uid,
        content,
        parentCommentId:
          parent_comment_id === undefined || parent_comment_id === null
            ? undefined
            : Number(parent_comment_id),
      });

      res.status(201).json({
        success: true,
        data: comment,
      });
    } catch (error) {
      next(error);
    }
  }
);

// ---------------------------------------------------------------------------
// /api/comments/:comment_id
// ---------------------------------------------------------------------------
export const commentsRouter = Router();

// 48. Soft-delete a comment (comment owner or tweet owner)
commentsRouter.delete(
  '/:comment_id',
  authenticate,
  validateCommentId(),
  handleValidationErrors,
  async (req, res, next) => {
    try {
      const { comment_id } = req.params;
      const requestUser = (req as AuthenticatedRequest).user;

      if (!requestUser) {
        throw new ApiError(401, 'Authentication required');
      }

      const result = await commentService.deleteComment(parseInt(comment_id), requestUser.uid);

      res.json({
        success: true,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }
);
