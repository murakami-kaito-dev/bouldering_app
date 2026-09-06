import { Router } from 'express';
import { authenticate, AuthenticatedRequest } from '../middleware/auth';
import { handleValidationErrors } from '../middleware/validation';
import { getLikeService } from '../infrastructure/setup/dependencies';
import { validateTweetId } from '../utils/validation';
import { ApiError } from '../middleware/error';

const router = Router();
const likeService = getLikeService();

/**
 * いいね関連のエンドポイント（Issue #17）
 *
 * 実際のURL（/api/tweets がベースパスとして追加される）:
 * POST   /api/tweets/:tweet_id/like - いいねを付ける（冪等）
 * DELETE /api/tweets/:tweet_id/like - いいねを外す（冪等）
 *
 * routes/tweets.ts とは別ファイルにしてあるのは、並行開発（コメント機能）との
 * 衝突を避けるため。マウントは index.ts で行う。
 */

// 24. Like tweet
router.post(
  '/:tweet_id/like',
  authenticate,
  validateTweetId(),
  handleValidationErrors,
  async (req, res, next) => {
    try {
      const { tweet_id } = req.params;
      const requestUser = (req as AuthenticatedRequest).user;

      if (!requestUser) {
        throw new ApiError(401, 'Authentication required');
      }

      const result = await likeService.likeTweet(parseInt(tweet_id), requestUser.uid);

      res.json({
        success: true,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }
);

// 25. Unlike tweet
router.delete(
  '/:tweet_id/like',
  authenticate,
  validateTweetId(),
  handleValidationErrors,
  async (req, res, next) => {
    try {
      const { tweet_id } = req.params;
      const requestUser = (req as AuthenticatedRequest).user;

      if (!requestUser) {
        throw new ApiError(401, 'Authentication required');
      }

      const result = await likeService.unlikeTweet(parseInt(tweet_id), requestUser.uid);

      res.json({
        success: true,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }
);

export default router;
