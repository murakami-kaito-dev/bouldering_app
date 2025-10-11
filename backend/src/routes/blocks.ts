import { Router } from 'express';
import { handleValidationErrors } from '../middleware/validation';
import { param } from 'express-validator';
import { getBlockService } from '../infrastructure/setup/dependencies';
import { ApiError } from '../middleware/error';
import { authenticate, AuthenticatedRequest } from '../middleware/auth';

const router = Router();

/**
 * ブロック関連のエンドポイント
 *
 * 実際のURL（/api/blocksがベースパスとして追加される）:
 * POST /api/blocks/:userId - ユーザーをブロック
 * DELETE /api/blocks/:userId - ブロックを解除
 * GET /api/blocks/blocked-users - ブロックしているユーザー一覧
 * GET /api/blocks/is-blocked/:userId - ブロック状態確認
 */

// ユーザーをブロック
router.post(
  '/:userId',
  authenticate,
  param('userId').isString().notEmpty().withMessage('ユーザーIDが必要です'),
  handleValidationErrors,
  async (req, res, next) => {
    try {
      const requestUser = (req as AuthenticatedRequest).user;
      const blockerUserId = requestUser?.uid;
      const blockedUserId = req.params.userId;

      if (!blockerUserId) {
        throw new ApiError(401, 'Unauthorized');
      }

      // BlockServiceをDIコンテナから取得
      const blockService = getBlockService();

      // ユーザーをブロック
      const block = await blockService.blockUser(blockerUserId, blockedUserId);

      // 成功レスポンス
      res.status(201).json({
        success: true,
        message: 'ユーザーをブロックしました',
        data: block,
      });
    } catch (error) {
      next(error);
    }
  }
);

// ブロックを解除
router.delete(
  '/:userId',
  authenticate,
  param('userId').isString().notEmpty().withMessage('ユーザーIDが必要です'),
  handleValidationErrors,
  async (req, res, next) => {
    try {
      const requestUser = (req as AuthenticatedRequest).user;
      const blockerUserId = requestUser?.uid;
      const blockedUserId = req.params.userId;

      if (!blockerUserId) {
        throw new ApiError(401, 'Unauthorized');
      }

      const blockService = getBlockService();

      // ブロックを解除
      await blockService.unblockUser(blockerUserId, blockedUserId);

      res.status(200).json({
        success: true,
        message: 'ブロックを解除しました',
      });
    } catch (error) {
      next(error);
    }
  }
);

// ブロックしているユーザー一覧を取得
router.get(
  '/blocked-users',
  authenticate,
  async (req, res, next) => {
    try {
      const requestUser = (req as AuthenticatedRequest).user;
      const blockerUserId = requestUser?.uid;

      if (!blockerUserId) {
        throw new ApiError(401, 'Unauthorized');
      }

      const blockService = getBlockService();

      // ブロックしているユーザー一覧を取得
      const blockedUsers = await blockService.getBlockedUsers(blockerUserId);

      res.status(200).json({
        success: true,
        data: blockedUsers,
      });
    } catch (error) {
      next(error);
    }
  }
);

// 特定のユーザーをブロックしているか確認
router.get(
  '/is-blocked/:userId',
  authenticate,
  param('userId').isString().notEmpty().withMessage('ユーザーIDが必要です'),
  handleValidationErrors,
  async (req, res, next) => {
    try {
      const requestUser = (req as AuthenticatedRequest).user;
      const blockerUserId = requestUser?.uid;
      const targetUserId = req.params.userId;

      if (!blockerUserId) {
        throw new ApiError(401, 'Unauthorized');
      }

      const blockService = getBlockService();

      // ブロック状態を確認
      const result = await blockService.checkBlockStatus(blockerUserId, targetUserId);

      res.status(200).json({
        success: true,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }
);

export default router;
