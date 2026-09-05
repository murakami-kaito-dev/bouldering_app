import { Router } from 'express';
import { authenticate, AuthenticatedRequest } from '../middleware/auth';
import { handleValidationErrors } from '../middleware/validation';
import { getUploadService } from '../infrastructure/setup/dependencies';
import { validateSignUpload } from '../utils/validation';
import { ApiError } from '../middleware/error';

const router = Router();
const uploadService = getUploadService();

// 33. Issue a signed upload URL (Web app: browser PUTs the file directly to GCS)
router.post(
  '/sign',
  authenticate,
  validateSignUpload(),
  handleValidationErrors,
  async (req, res, next) => {
    try {
      const { kind, content_type, file_name, post_uuid } = req.body;
      const requestUser = (req as AuthenticatedRequest).user;

      if (!requestUser) {
        throw new ApiError(401, 'Authentication required');
      }

      const signed = await uploadService.createSignedUpload({
        uid: requestUser.uid,
        kind,
        contentType: content_type,
        fileName: file_name,
        postUuid: post_uuid,
      });

      res.json({
        success: true,
        data: signed,
      });
    } catch (error) {
      next(error);
    }
  }
);

export default router;
