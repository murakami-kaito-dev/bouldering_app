import { body, query, param } from 'express-validator';

// Common validation rules
export const validateUserId = () =>
  param('user_id')
    .isString()
    .notEmpty()
    .withMessage('User ID is required');

export const validateTweetId = () =>
  param('tweet_id')
    .isInt({ min: 1 })
    .withMessage('Valid tweet ID is required');

export const validateGymId = () =>
  body('gym_id')
    .isInt({ min: 1 })
    .withMessage('Valid gym ID is required');

// User validation rules
export const validateCreateUser = () => [
  body('user_id')
    .isString()
    .notEmpty()
    .withMessage('User ID is required'),
  body('email')
    .isEmail()
    .withMessage('Valid email is required'),
];

export const validateUpdateUserName = () => [
  body('user_name')
    .isString()
    .isLength({ min: 1, max: 50 })
    .withMessage('User name must be between 1 and 50 characters'),
];

export const validateUpdateUserProfile = () => [
  body('description')
    .optional()
    .isString()
    .isLength({ max: 500 })
    .withMessage('Description must be less than 500 characters'),
  body('type')
    .isIn(['true', 'false'])
    .withMessage('Type must be "true" or "false"'),
];

export const validateUpdateGender = () => [
  body('gender')
    .isInt({ min: 0, max: 2 })
    .withMessage('Gender must be 0 (unselected), 1 (male), or 2 (female)'),
];

export const validateUpdateDates = () => [
  body('update_date')
    .isISO8601()
    .withMessage('Valid date is required'),
  body('is_bouldering_debut')
    .isBoolean()
    .withMessage('is_bouldering_debut must be boolean'),
];

export const validateUpdateHomeGym = () => [
  body('home_gym_id')
    .isInt({ min: 0 })
    .withMessage('Valid gym ID is required'),
];

export const validateUpdateIconUrl = () => [
  body('user_icon_url')
    .isURL()
    .withMessage('Valid URL is required'),
];

export const validateUpdateEmail = () => [
  body('email')
    .isEmail()
    .withMessage('Valid email is required'),
];

// Tweet validation rules
export const validateCreateTweet = () => [
  body('gym_id')
    .isInt({ min: 1 })
    .withMessage('Valid gym ID is required'),
  body('tweet_contents')
    .isString()
    .isLength({ min: 0, max: 400 })
    .withMessage('Tweet content must be 400 characters or less'),
  body('visited_date')
    .isISO8601()
    .custom((value) => {
      const visitedDate = new Date(value);
      // 日本時間（JST）での「今日」を計算（UTC+9）
      const now = new Date();
      const jstOffset = 9 * 60; // 日本時間はUTC+9時間
      const jstNow = new Date(now.getTime() + jstOffset * 60 * 1000);
      const todayJst = new Date(jstNow.getFullYear(), jstNow.getMonth(), jstNow.getDate(), 23, 59, 59, 999);
      // 比較用にUTCに戻す
      const todayUtc = new Date(todayJst.getTime() - jstOffset * 60 * 1000);
      
      if (visitedDate > todayUtc) {
        throw new Error('Visited date cannot be in the future');
      }
      return true;
    }),
  body('media_urls')
    .optional()
    .isArray({ max: 5 })
    .withMessage('Maximum 5 media URLs allowed')
    .custom((urls) => {
      if (urls) {
        for (const url of urls) {
          if (typeof url !== 'string' || !url.startsWith('http')) {
            throw new Error('Invalid media URL format');
          }
        }
      }
      return true;
    }),
];

export const validateUpdateTweet = () => [
  body('tweet_contents')
    .optional()
    .isString()
    .isLength({ min: 0, max: 400 })
    .withMessage('Tweet content must be 400 characters or less'),
  body('visited_date')
    .optional()
    .isISO8601()
    .custom((value) => {
      if (value) {
        const visitedDate = new Date(value);
        // 日本時間（JST）での「今日」を計算（UTC+9）
        const now = new Date();
        const jstOffset = 9 * 60; // 日本時間はUTC+9時間
        const jstNow = new Date(now.getTime() + jstOffset * 60 * 1000);
        const todayJst = new Date(jstNow.getFullYear(), jstNow.getMonth(), jstNow.getDate(), 23, 59, 59, 999);
        // 比較用にUTCに戻す
        const todayUtc = new Date(todayJst.getTime() - jstOffset * 60 * 1000);
        
        if (visitedDate > todayUtc) {
          throw new Error('Visited date cannot be in the future');
        }
      }
      return true;
    }),
  body('gym_id')
    .optional()
    .isInt({ min: 1 })
    .withMessage('Valid gym ID is required'),
  body('media_urls')
    .optional()
    .isArray({ max: 5 })
    .withMessage('Maximum 5 media URLs allowed')
    .custom((urls) => {
      if (urls) {
        for (const url of urls) {
          if (typeof url !== 'string' || !url.startsWith('http')) {
            throw new Error('Invalid media URL format');
          }
        }
      }
      return true;
    }),
];

export const validateAddTweetMedia = () => [
  body('media_url')
    .isURL()
    .withMessage('Valid media URL is required'),
  body('media_type')
    .isIn(['photo', 'video'])
    .withMessage('Media type must be "photo" or "video"'),
];

// Pagination validation
export const validatePagination = () => [
  query('limit')
    .optional()
    .isInt({ min: 1, max: 100 })
    .withMessage('Limit must be between 1 and 100'),
  query('cursor')
    .optional()
    .isISO8601()
    .withMessage('Cursor must be a valid ISO8601 date'),
];

// Favorite gym validation
export const validateFavoriteGym = () => [
  body('gym_id')
    .isInt({ min: 1 })
    .withMessage('Valid gym ID is required'),
];