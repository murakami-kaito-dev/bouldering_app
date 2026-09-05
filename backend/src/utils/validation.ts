import { isAfterJstToday } from './jstTime';
import { body, query, param } from 'express-validator';
import {
  ALLOWED_UPLOAD_CONTENT_TYPES,
  UPLOAD_FILE_NAME_MAX_LENGTH,
  UPLOAD_KINDS,
} from '../domain/services/UploadPolicy';

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
  // メールアドレスは持たない（SNS ログイン後に設定画面から任意で登録）。
  // 送られてきた場合だけ形式を確認する
  body('email')
    .optional({ nullable: true })
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

// メールアドレス登録: 本人確認済みのメールは Firebase トークンから取るので body は
// 「null = 未登録に戻す」の指示にだけ使う（値が来た場合は形式のみ確認）
export const validateUpdateEmail = () => [
  body('email')
    .optional({ nullable: true })
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
      // 「今日」は日本時間で判定（共通部品 utils/jstTime.ts）
      if (isAfterJstToday(String(value))) {
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
      if (value && isAfterJstToday(String(value))) {
        throw new Error('Visited date cannot be in the future');
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

// Report validation（報告機能のバリデーション）
export const validateCreateReport = () => [
  body('reporter_user_id')
    .isString()
    .notEmpty()
    .withMessage('報告者のユーザーIDが必要です'),
  body('target_user_id')
    .isString()
    .notEmpty()
    .withMessage('対象ユーザーIDが必要です'),
  body('target_tweet_id')
    .isInt({ min: 1 })
    .withMessage('有効なツイートIDが必要です'),
  body('report_description')
    .optional()
    .isString()
    .isLength({ max: 1000 })
    .withMessage('報告内容は1000文字以内で入力してください'),
];

// Upload validation（Web 向け 署名付きURL発行のバリデーション）
export const validateSignUpload = () => [
  body('kind')
    .isIn([...UPLOAD_KINDS])
    .withMessage(`kind must be one of: ${UPLOAD_KINDS.join(', ')}`),
  body('content_type')
    .isIn([...ALLOWED_UPLOAD_CONTENT_TYPES])
    .withMessage(`content_type must be one of: ${ALLOWED_UPLOAD_CONTENT_TYPES.join(', ')}`),
  // 拡張子の判定にだけ使う（保存名には使わない）
  body('file_name')
    .optional({ nullable: true })
    .isString()
    .isLength({ min: 1, max: UPLOAD_FILE_NAME_MAX_LENGTH })
    .withMessage(`file_name must be ${UPLOAD_FILE_NAME_MAX_LENGTH} characters or less`),
  // kind=post のみ意味を持つ。複数枚を同じ投稿にまとめるときにクライアントが同じ値を渡す
  body('post_uuid')
    .optional({ nullable: true })
    .isUUID()
    .withMessage('post_uuid must be a valid UUID'),
];
