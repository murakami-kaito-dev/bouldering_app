import { Router } from 'express';
import { optionalAuthenticate } from '../middleware/auth';
import { handleValidationErrors } from '../middleware/validation';
import { getGymService } from '../infrastructure/setup/dependencies';
import { validatePagination } from '../utils/validation';
import { ApiError } from '../middleware/error';
import { param } from 'express-validator';

const router = Router();
const gymService = getGymService();

// 24. Get all gyms
router.get(
  '/',
  optionalAuthenticate,
  async (req, res, next) => {
    try {
      const gyms = await gymService.getAllGyms();

      if (gyms.length === 0) {
        throw new ApiError(404, 'No gyms found');
      }

      res.json({
        success: true,
        data: gyms,
      });
    } catch (error) {
      next(error);
    }
  }
);

// 25. Get specific gym details
router.get(
  '/:gym_id',
  optionalAuthenticate,
  param('gym_id').isInt({ min: 1 }).withMessage('Valid gym ID is required'),
  handleValidationErrors,
  async (req, res, next) => {
    try {
      const { gym_id } = req.params;
      const gym = await gymService.getGymById(parseInt(gym_id));

      if (!gym) {
        throw new ApiError(404, 'Gym not found');
      }

      res.json({
        success: true,
        data: gym,
      });
    } catch (error) {
      next(error);
    }
  }
);

// 26. Get gym tweets
router.get(
  '/:gym_id/tweets',
  optionalAuthenticate,
  param('gym_id').isInt({ min: 1 }).withMessage('Valid gym ID is required'),
  validatePagination(),
  handleValidationErrors,
  async (req, res, next) => {
    try {
      const { gym_id } = req.params;
      const { limit = '20', cursor } = req.query;

      const tweets = await gymService.getGymTweets(
        parseInt(gym_id),
        parseInt(limit as string),
        cursor as string
      );

      res.json({
        success: true,
        data: tweets,
      });
    } catch (error) {
      next(error);
    }
  }
);

// 27. Get ikitai counts for all gyms
router.get(
  '/ikitai-counts',
  optionalAuthenticate,
  async (req, res, next) => {
    try {
      const ikitaiCounts = await gymService.getIkitaiCounts();

      res.json({
        success: true,
        data: ikitaiCounts,
      });
    } catch (error) {
      next(error);
    }
  }
);

// 28. Get boul counts for all gyms
router.get(
  '/boul-counts',
  optionalAuthenticate,
  async (req, res, next) => {
    try {
      const boulCounts = await gymService.getBoulCounts();

      res.json({
        success: true,
        data: boulCounts,
      });
    } catch (error) {
      next(error);
    }
  }
);

export default router;