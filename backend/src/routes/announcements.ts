import { Router } from 'express';
import { optionalAuthenticate, AuthenticatedRequest } from '../middleware/auth';
import { handleValidationErrors } from '../middleware/validation';
import { getAnnouncementService } from '../infrastructure/setup/dependencies';
import { validatePagination } from '../utils/validation';

const router = Router();
const announcementService = getAnnouncementService();

/**
 * お知らせエンドポイント（Issue #81）
 *
 * 実際のURL（/api/announcements がベースパス）:
 * GET /api/announcements?limit=20&cursor= - 公式（gym_id NULL）＋認証時は本人のホームジム・イキタイジムのお知らせ。新しい順
 */

// 52. Get announcements
router.get(
  '/',
  optionalAuthenticate,
  validatePagination(),
  handleValidationErrors,
  async (req, res, next) => {
    try {
      const { limit = '20', cursor } = req.query;
      const requestUser = (req as AuthenticatedRequest).user;

      const announcements = await announcementService.getAnnouncements(
        parseInt(limit as string),
        cursor as string | undefined,
        requestUser?.uid
      );

      res.json({
        success: true,
        data: announcements,
      });
    } catch (error) {
      next(error);
    }
  }
);

export default router;
