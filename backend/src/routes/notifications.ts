import { Router } from 'express';
import { body } from 'express-validator';
import { authenticate, AuthenticatedRequest } from '../middleware/auth';
import { handleValidationErrors } from '../middleware/validation';
import { getNotificationService } from '../infrastructure/setup/dependencies';
import { validateUserId, validatePagination } from '../utils/validation';
import { ApiError } from '../middleware/error';

const router = Router();
const notificationService = getNotificationService();

/**
 * 通知エンドポイント（Issue #81）
 *
 * 実際のURL（/api/users がベースパスとして追加される。routes/users.ts は触らない）:
 * GET  /api/users/:user_id/notifications?limit=30&cursor= - 通知一覧（新しい順・いいねは集約）
 * GET  /api/users/:user_id/notifications/unread-count     - 未読数
 * POST /api/users/:user_id/notifications/read             - 既読化（body { up_to_id? }）
 *
 * すべて認証必須・本人のみ（他人の :user_id は 403）
 */

/** 本人以外は 403（routes/users.ts の self-only パターン） */
function assertSelf(req: AuthenticatedRequest, userId: string): string {
  const requestUser = req.user;
  if (!requestUser) {
    throw new ApiError(401, 'Authentication required');
  }
  if (requestUser.uid !== userId) {
    throw new ApiError(403, 'Access denied');
  }
  return requestUser.uid;
}

const validateMarkRead = () => [
  body('up_to_id')
    .optional({ nullable: true })
    .isInt({ min: 1 })
    .withMessage('up_to_id must be a positive integer')
    .toInt(),
];

// 49. Get notifications (newest first, likes aggregated, cursor paging)
router.get(
  '/:user_id/notifications',
  authenticate,
  validateUserId(),
  validatePagination(),
  handleValidationErrors,
  async (req, res, next) => {
    try {
      const { user_id } = req.params;
      const { limit = '30', cursor } = req.query;
      const uid = assertSelf(req as AuthenticatedRequest, user_id);

      const notifications = await notificationService.getNotifications(
        uid,
        parseInt(limit as string),
        cursor as string | undefined
      );

      res.json({
        success: true,
        data: notifications,
      });
    } catch (error) {
      next(error);
    }
  }
);

// 50. Unread count
router.get(
  '/:user_id/notifications/unread-count',
  authenticate,
  validateUserId(),
  handleValidationErrors,
  async (req, res, next) => {
    try {
      const { user_id } = req.params;
      const uid = assertSelf(req as AuthenticatedRequest, user_id);

      const count = await notificationService.getUnreadCount(uid);

      res.json({
        success: true,
        data: { count },
      });
    } catch (error) {
      next(error);
    }
  }
);

// 51. Mark as read (all, or up to a notification id)
router.post(
  '/:user_id/notifications/read',
  authenticate,
  validateUserId(),
  validateMarkRead(),
  handleValidationErrors,
  async (req, res, next) => {
    try {
      const { user_id } = req.params;
      const { up_to_id } = req.body ?? {};
      const uid = assertSelf(req as AuthenticatedRequest, user_id);

      const updated = await notificationService.markRead(
        uid,
        up_to_id === undefined || up_to_id === null ? undefined : Number(up_to_id)
      );

      res.json({
        success: true,
        data: { updated },
      });
    } catch (error) {
      next(error);
    }
  }
);

export default router;
