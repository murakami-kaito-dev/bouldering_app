import { Router } from 'express';
import { authenticate, optionalAuthenticate, AuthenticatedRequest } from '../middleware/auth';
import { handleValidationErrors } from '../middleware/validation';
import { getTweetService } from '../infrastructure/setup/dependencies';
import {
  validateTweetId,
  validateCreateTweet,
  validateUpdateTweet,
  validateAddTweetMedia,
  validatePagination,
} from '../utils/validation';
import { ApiError } from '../middleware/error';
import { query } from 'express-validator';

const router = Router();
const tweetService = getTweetService();

// 17. Get all tweets (public timeline)
router.get(
  '/',
  optionalAuthenticate, // Optional auth to allow public access
  validatePagination(),
  handleValidationErrors,
  async (req, res, next) => {
    try {
      const { limit = '20', cursor } = req.query;
      const requestUser = (req as AuthenticatedRequest).user;

      const tweets = await tweetService.getAllTweets(
        parseInt(limit as string),
        cursor as string,
        requestUser?.uid // 認証されている場合はユーザーIDを渡す
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

// 18. Get user's tweets
router.get(
  '/users/:user_id',
  optionalAuthenticate, // Optional auth for public profiles
  validatePagination(),
  handleValidationErrors,
  async (req, res, next) => {
    try {
      const { user_id } = req.params;
      const { limit = '20', cursor } = req.query;

      const tweets = await tweetService.getUserTweets(
        user_id,
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

// Get single tweet by ID
router.get(
  '/:tweet_id',
  optionalAuthenticate, // Optional auth for public tweet access
  validateTweetId(),
  handleValidationErrors,
  async (req, res, next) => {
    try {
      const { tweet_id } = req.params;

      const tweet = await tweetService.getTweetById(parseInt(tweet_id));

      if (!tweet) {
        res.status(404).json({
          success: false,
          error: 'Tweet not found',
        });
        return;
      }

      res.json({
        success: true,
        data: tweet,
      });
    } catch (error) {
      next(error);
    }
  }
);

// 19. Create new tweet
router.post(
  '/',
  authenticate,
  validateCreateTweet(),
  handleValidationErrors,
  async (req, res, next) => {
    try {
      const { gym_id, tweet_contents, visited_date, media_urls, media_metadata, post_uuid } = req.body;
      const requestUser = (req as AuthenticatedRequest).user;

      if (!requestUser) {
        throw new ApiError(401, 'Authentication required');
      }

      const result = await tweetService.createTweet({
        user_id: requestUser.uid,
        gym_id,
        tweet_contents,
        visited_date,
        media_urls,
        media_metadata,
        post_uuid,
      });

      res.status(201).json({
        success: true,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }
);

// 20. Update tweet
router.patch(
  '/:tweet_id',
  authenticate,
  validateTweetId(),
  validateUpdateTweet(),
  handleValidationErrors,
  async (req, res, next) => {
    try {
      const { tweet_id } = req.params;
      const { tweet_contents, visited_date, gym_id, media_urls } = req.body;
      const requestUser = (req as AuthenticatedRequest).user;

      if (!requestUser) {
        throw new ApiError(401, 'Authentication required');
      }

      const updatedTweet = await tweetService.updateTweet(
        parseInt(tweet_id),
        requestUser.uid,
        {
          tweet_contents,
          visited_date,
          gym_id,
          media_urls,
        }
      );

      res.json({
        success: true,
        data: updatedTweet,
      });
    } catch (error) {
      next(error);
    }
  }
);

// 21. Delete tweet
router.delete(
  '/:tweet_id',
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

      await tweetService.deleteTweet(parseInt(tweet_id), requestUser.uid);

      res.status(204).send();
    } catch (error) {
      next(error);
    }
  }
);

// 22. Add media to tweet
router.post(
  '/:tweet_id/media',
  authenticate,
  validateTweetId(),
  validateAddTweetMedia(),
  handleValidationErrors,
  async (req, res, next) => {
    try {
      const { tweet_id } = req.params;
      const { media_url, media_type } = req.body;
      const requestUser = (req as AuthenticatedRequest).user;

      if (!requestUser) {
        throw new ApiError(401, 'Authentication required');
      }

      await tweetService.addTweetMedia(parseInt(tweet_id), requestUser.uid, {
        media_url,
        media_type,
      });

      res.json({
        success: true,
        message: 'Media added to tweet',
      });
    } catch (error) {
      next(error);
    }
  }
);

// 23. Delete tweet media
router.delete(
  '/:tweet_id/media',
  authenticate,
  validateTweetId(),
  query('media_url').notEmpty().withMessage('Media URL is required'),
  handleValidationErrors,
  async (req, res, next) => {
    try {
      const { tweet_id } = req.params;
      const { media_url } = req.query;
      const requestUser = (req as AuthenticatedRequest).user;

      if (!requestUser) {
        throw new ApiError(401, 'Authentication required');
      }

      await tweetService.deleteTweetMedia(
        parseInt(tweet_id),
        requestUser.uid,
        media_url as string
      );

      res.json({
        success: true,
        message: 'Media deleted from tweet',
      });
    } catch (error) {
      next(error);
    }
  }
);

export default router;