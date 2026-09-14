import { Router } from 'express';
import { authenticate, optionalAuthenticate, AuthenticatedRequest } from '../middleware/auth';
import { handleValidationErrors } from '../middleware/validation';
import { requestVerification } from '../services/emailVerificationService';
import { getUserService, getFavoriteService } from '../infrastructure/setup/dependencies';
import {
  validateUserId,
  validateCreateUser,
  validateUpdateUserName,
  validateUpdateUserProfile,
  validateUpdateGender,
  validateUpdateDates,
  validateUpdateHomeGym,
  validateUpdateIconUrl,
  validateUpdateEmail,
  validateRequestEmail,
  validatePagination,
  validateFavoriteGym,
} from '../utils/validation';
import { ApiError } from '../middleware/error';
import { query } from 'express-validator';

const router = Router();
const userService = getUserService();
const favoriteService = getFavoriteService();

// 1. Get user data
router.get(
  '/:user_id',
  authenticate,
  validateUserId(),
  handleValidationErrors,
  async (req, res, next) => {
    try {
      const { user_id } = req.params;
      const requestUser = (req as AuthenticatedRequest).user;

      // Check if user is accessing their own data or has permission
      if (requestUser?.uid !== user_id) {
        throw new ApiError(403, 'Access denied');
      }

      const user = await userService.getUserById(user_id);
      if (!user) {
        throw new ApiError(404, 'User not found');
      }

      res.json({
        success: true,
        data: user,
      });
    } catch (error) {
      next(error);
    }
  }
);

// 2. Get user profile (simplified)
router.get(
  '/:user_id/profile',
  validateUserId(),
  handleValidationErrors,
  async (req, res, next) => {
    try {
      const { user_id } = req.params;
      const profile = await userService.getUserProfile(user_id);

      if (!profile) {
        throw new ApiError(404, 'User not found');
      }

      res.json({
        success: true,
        data: profile,
      });
    } catch (error) {
      next(error);
    }
  }
);

// 3. Create new user - SNS ログイン（Google/Apple）直後に本人の行を作る。
// Firebase トークン必須・作れるのは自分の uid の行だけ（他人の uid やゴミ行を作らせない）
router.post(
  '/',
  authenticate,
  validateCreateUser(),
  handleValidationErrors,
  async (req, res, next) => {
    try {
      const requestUser = (req as AuthenticatedRequest).user;
      const { 
        user_id, 
        email = null,
        user_name = '駆け出しボルダー',
        user_introduce = '設定から自己紹介を記入しましょう！',
        favorite_gym = '設定から好きなジムを記入しましょう！',
        gender = 0,
        home_gym_id = null,
        boul_start_date
      } = req.body;

      if (requestUser?.uid !== user_id) {
        throw new ApiError(403, 'Access denied');
      }

      const user = await userService.createUser({ 
        user_id, 
        email,
        user_name,
        user_introduce,
        favorite_gym,
        gender,
        home_gym_id,
        boul_start_date
      });

      res.json({
        success: true,
        data: user,
        message: 'User created successfully',
      });
    } catch (error) {
      console.error('[USER CREATE ERROR]', error);
      next(error);
    }
  }
);

// 4. Update user name
router.patch(
  '/:user_id',
  authenticate,
  validateUserId(),
  validateUpdateUserName(),
  handleValidationErrors,
  async (req, res, next) => {
    try {
      const { user_id } = req.params;
      const { user_name } = req.body;
      const requestUser = (req as AuthenticatedRequest).user;

      if (requestUser?.uid !== user_id) {
        throw new ApiError(403, 'Access denied');
      }

      const user = await userService.updateUserName(user_id, user_name);

      res.json({
        success: true,
        data: user,
      });
    } catch (error) {
      next(error);
    }
  }
);

// 5. Update user profile texts
router.patch(
  '/:user_id/profile/texts',
  authenticate,
  validateUserId(),
  validateUpdateUserProfile(),
  handleValidationErrors,
  async (req, res, next) => {
    try {
      const { user_id } = req.params;
      const { description, type } = req.body;
      const requestUser = (req as AuthenticatedRequest).user;

      if (requestUser?.uid !== user_id) {
        throw new ApiError(403, 'Access denied');
      }

      const user = await userService.updateUserProfileText(user_id, description, type);

      res.json({
        success: true,
        data: user,
      });
    } catch (error) {
      next(error);
    }
  }
);

// 6. Update user gender
router.patch(
  '/:user_id/gender',
  authenticate,
  validateUserId(),
  validateUpdateGender(),
  handleValidationErrors,
  async (req, res, next) => {
    try {
      const { user_id } = req.params;
      const { gender } = req.body;
      const requestUser = (req as AuthenticatedRequest).user;

      if (requestUser?.uid !== user_id) {
        throw new ApiError(403, 'Access denied');
      }

      const user = await userService.updateUserGender(user_id, gender);

      res.json({
        success: true,
        data: user,
      });
    } catch (error) {
      next(error);
    }
  }
);

// 7. Update user dates
router.patch(
  '/:user_id/dates',
  authenticate,
  validateUserId(),
  validateUpdateDates(),
  handleValidationErrors,
  async (req, res, next) => {
    try {
      const { user_id } = req.params;
      const { update_date, is_bouldering_debut } = req.body;
      const requestUser = (req as AuthenticatedRequest).user;

      if (requestUser?.uid !== user_id) {
        throw new ApiError(403, 'Access denied');
      }

      // フロントエンドの仕様に合わせて引数を変換
      // is_bouldering_debut: false = 誕生日, true = ボルダリング開始日
      const dateValue = update_date ? new Date(update_date) : undefined;
      const boulStartDate = is_bouldering_debut ? dateValue : undefined;
      const birthday = !is_bouldering_debut ? dateValue : undefined;
      
      const user = await userService.updateUserDates(user_id, boulStartDate, birthday);

      res.json({
        success: true,
        data: user,
      });
    } catch (error) {
      next(error);
    }
  }
);

// 8. Update home gym
router.patch(
  '/:user_id/home-gym',
  authenticate,
  validateUserId(),
  validateUpdateHomeGym(),
  handleValidationErrors,
  async (req, res, next) => {
    try {
      const { user_id } = req.params;
      const { home_gym_id } = req.body;
      const requestUser = (req as AuthenticatedRequest).user;

      if (requestUser?.uid !== user_id) {
        throw new ApiError(403, 'Access denied');
      }

      const user = await userService.updateUserHomeGym(user_id, home_gym_id);

      res.json({
        success: true,
        data: user,
      });
    } catch (error) {
      next(error);
    }
  }
);

// 9. Update icon URL
router.patch(
  '/:user_id/icon-url',
  authenticate,
  validateUserId(),
  validateUpdateIconUrl(),
  handleValidationErrors,
  async (req, res, next) => {
    try {
      const { user_id } = req.params;
      const { user_icon_url } = req.body;
      const requestUser = (req as AuthenticatedRequest).user;

      if (requestUser?.uid !== user_id) {
        throw new ApiError(403, 'Access denied');
      }

      const user = await userService.updateUserIconUrl(user_id, user_icon_url);

      res.json({
        success: true,
        data: user,
      });
    } catch (error) {
      next(error);
    }
  }
);

// 10. Remove notification email（任意登録の解除。登録は 10b の申請 → 確認リンクで行う）
router.patch(
  '/:user_id/email',
  authenticate,
  validateUserId(),
  validateUpdateEmail(),
  handleValidationErrors,
  async (req, res, next) => {
    try {
      const { user_id } = req.params;
      const { email: requestedEmail } = req.body;
      const requestUser = (req as AuthenticatedRequest).user;

      if (requestUser?.uid !== user_id) {
        throw new ApiError(403, 'Access denied');
      }
      // 本人確認なしにメールを書くことはできない。登録は /email/request 経由のみ
      if (requestedEmail !== null && requestedEmail !== undefined) {
        throw new ApiError(400, 'Use POST /users/:user_id/email/request to register an email', 'USE_EMAIL_REQUEST');
      }

      const user = await userService.updateUserEmail(user_id, null);

      res.json({
        success: true,
        data: user,
      });
    } catch (error) {
      next(error);
    }
  }
);

// 10b. Request email verification（通知用メールの登録申請 → Brevo で確認メール送信）
// - 本人のみ。DB にはまだ書かず、リンク押下（GET /email/confirm）で確定する
// - 別アカウントで登録済み: 409 / 60 秒以内の再送: 429 / 未設定環境: 503
router.post(
  '/:user_id/email/request',
  authenticate,
  validateUserId(),
  validateRequestEmail(),
  handleValidationErrors,
  async (req, res, next) => {
    try {
      const { user_id } = req.params;
      const requestUser = (req as AuthenticatedRequest).user;
      if (requestUser?.uid !== user_id) {
        throw new ApiError(403, 'Access denied');
      }
      const state = await requestVerification(user_id, String(req.body.email));
      res.status(state === 'sent' ? 202 : 200).json({ success: true, data: { state } });
    } catch (error) {
      next(error);
    }
  }
);

// 10. Get monthly statistics (public access for user profiles)
router.get(
  '/:user_id/stats/monthly',
  optionalAuthenticate,  // Changed to optional auth for public access
  validateUserId(),
  query('months_ago').optional().isInt({ min: 0, max: 12 }),
  handleValidationErrors,
  async (req, res, next) => {
    try {
      const { user_id } = req.params;
      const months_ago = parseInt(req.query.months_ago as string) || 0;
      // Removed access control - allow public access to user statistics

      const stats = await userService.getMonthlyStats(user_id, months_ago);

      res.json({
        success: true,
        data: stats,
      });
    } catch (error) {
      next(error);
    }
  }
);

// 11. Add user to favorites
router.post(
  '/:liker_user_id/favorites/users',
  authenticate,
  validateUserId(),
  async (req, res, next) => {
    try {
      const { liker_user_id } = req.params;
      const { likee_user_id } = req.body;
      const requestUser = (req as AuthenticatedRequest).user;

      if (requestUser?.uid !== liker_user_id) {
        throw new ApiError(403, 'Access denied');
      }

      await favoriteService.addUserToFavorites(liker_user_id, likee_user_id);

      res.json({
        success: true,
        message: 'User added to favorites',
      });
    } catch (error) {
      next(error);
    }
  }
);

// 12. Remove user from favorites
router.delete(
  '/:liker_user_id/favorites/users/:likee_user_id',
  authenticate,
  async (req, res, next) => {
    try {
      const { liker_user_id, likee_user_id } = req.params;
      const requestUser = (req as AuthenticatedRequest).user;

      if (requestUser?.uid !== liker_user_id) {
        throw new ApiError(403, 'Access denied');
      }

      await favoriteService.removeUserFromFavorites(liker_user_id, likee_user_id);

      // レコードが存在しない場合も成功として扱う（冪等性の確保）
      res.json({
        success: true,
        message: 'User removed from favorites',
      });
    } catch (error) {
      next(error);
    }
  }
);

// ==================== 重要：ルート定義順序について ====================
//
// 🚨 Express.jsの重要な仕組み：ルートは定義順に評価され、最初にマッチしたルートで処理が停止する
//
// ❌ 間違った順序の例：
//    /:user_id/favorites/users          ← 短い（曖昧）パターン
//    /:user_id/favorites/users/tweets   ← 長い（具体的）パターン
//
//    リクエスト: /users/ABC/favorites/users/tweets
//    結果: 1番目のルート /:user_id/favorites/users にマッチしてしまい、
//          残りの "/tweets" は無視される（バグの原因）
//
// ✅ 正しい順序：
//    /:user_id/favorites/users/tweets   ← 長い（具体的）パターンを先に
//    /:user_id/favorites/users          ← 短い（曖昧）パターンを後に
//
// 💡 ルール：より具体的（長い）なパスパターンを先に定義する（最長一致の原則）
//
// 🔧 リファクタリング時の注意：
//    - このルート順序を変更する際は、必ずより具体的なものから順に並べること
//    - 似たようなパターンのルートがある場合は、パス長の降順で定義すること
//    - テスト時は各エンドポイントが正しく動作することを個別に確認すること
//
// ==================================================================

// 14. Get tweets from favorite users
// 🔥 重要：このルートは /:user_id/favorites/users よりも具体的なため、先に定義する必要がある
router.get(
  '/:user_id/favorites/users/tweets',
  authenticate,
  validateUserId(),
  validatePagination(),
  handleValidationErrors,
  async (req, res, next) => {
    try {
      const { user_id } = req.params;
      const { limit = '20', cursor } = req.query;
      const requestUser = (req as AuthenticatedRequest).user;

      if (requestUser?.uid !== user_id) {
        throw new ApiError(403, 'Access denied');
      }

      const tweets = await favoriteService.getFavoriteUsersTweets(
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

// 15. Get favorite users
// 📝 注意：このルートは上記の /tweets ルートよりも曖昧（短い）なため、後に定義
router.get(
  '/:user_id/favorites/users',
  authenticate,
  validateUserId(),
  handleValidationErrors,
  async (req, res, next) => {
    try {
      const { user_id } = req.params;
      const requestUser = (req as AuthenticatedRequest).user;

      if (requestUser?.uid !== user_id) {
        throw new ApiError(403, 'Access denied');
      }

      const favoriteUsers = await favoriteService.getUserFavorites(user_id);

      res.json({
        success: true,
        data: favoriteUsers,
      });
    } catch (error) {
      next(error);
    }
  }
);

// 16. Get users who favorited this user
router.get(
  '/:user_id/favorited-by',
  authenticate,
  validateUserId(),
  handleValidationErrors,
  async (req, res, next) => {
    try {
      const { user_id } = req.params;
      const requestUser = (req as AuthenticatedRequest).user;

      if (requestUser?.uid !== user_id) {
        throw new ApiError(403, 'Access denied');
      }

      const favoritedByUsers = await favoriteService.getUserFavoriteBy(user_id);

      res.json({
        success: true,
        data: favoritedByUsers,
      });
    } catch (error) {
      next(error);
    }
  }
);

// 17. Check favorite relationship - 個別のお気に入り関係確認
// 📝 重要：このルートは /:user_id/favorites/users/tweets より曖昧なため、後に定義
router.get(
  '/:liker_user_id/favorites/users/:likee_user_id',
  authenticate,
  async (req, res, next) => {
    try {
      const { liker_user_id, likee_user_id } = req.params;
      const requestUser = (req as AuthenticatedRequest).user;

      if (requestUser?.uid !== liker_user_id) {
        throw new ApiError(403, 'Access denied');
      }

      const exists = await favoriteService.checkUserFavorite(liker_user_id, likee_user_id);

      res.json({
        success: true,
        exists: exists,
      });
    } catch (error) {
      next(error);
    }
  }
);

// 29. Get favorite gyms (public access for user profiles)
router.get(
  '/:user_id/favorite-gyms',
  optionalAuthenticate,  // Changed to optional auth for public access
  validateUserId(),
  handleValidationErrors,
  async (req, res, next) => {
    try {
      const { user_id } = req.params;
      // Removed access control - allow public access to favorite gyms

      const favoriteGyms = await favoriteService.getUserFavoriteGyms(user_id);

      res.json({
        success: true,
        data: favoriteGyms,
      });
    } catch (error) {
      next(error);
    }
  }
);

// 30. Add gym to favorites
router.post(
  '/:user_id/favorite-gyms',
  authenticate,
  validateUserId(),
  validateFavoriteGym(),
  handleValidationErrors,
  async (req, res, next) => {
    try {
      const { user_id } = req.params;
      const { gym_id } = req.body;
      const requestUser = (req as AuthenticatedRequest).user;

      if (requestUser?.uid !== user_id) {
        throw new ApiError(403, 'Access denied');
      }

      await favoriteService.addGymToFavorites(user_id, gym_id);

      res.json({
        success: true,
        message: 'Gym added to favorites',
      });
    } catch (error) {
      next(error);
    }
  }
);

// 31. Check if gym is in favorites
router.get(
  '/:user_id/favorite-gyms/:gym_id',
  authenticate,
  validateUserId(),
  async (req, res, next) => {
    try {
      const { user_id, gym_id } = req.params;
      const requestUser = (req as AuthenticatedRequest).user;

      if (requestUser?.uid !== user_id) {
        throw new ApiError(403, 'Access denied');
      }

      const exists = await favoriteService.checkGymFavorite(user_id, parseInt(gym_id));

      res.json({
        success: true,
        exists: exists,
      });
    } catch (error) {
      next(error);
    }
  }
);

// 32. Remove gym from favorites
router.delete(
  '/:user_id/favorite-gyms/:gym_id',
  authenticate,
  validateUserId(),
  async (req, res, next) => {
    try {
      const { user_id, gym_id } = req.params;
      const requestUser = (req as AuthenticatedRequest).user;

      if (requestUser?.uid !== user_id) {
        throw new ApiError(403, 'Access denied');
      }

      await favoriteService.removeGymFromFavorites(user_id, parseInt(gym_id));

      // レコードが存在しない場合も成功として扱う（冪等性の確保）
      res.json({
        success: true,
        message: 'Gym removed from favorites',
      });
    } catch (error) {
      next(error);
    }
  }
);

// ユーザーアカウント削除（退会処理）
router.delete(
  '/:user_id',
  authenticate,
  validateUserId(),
  handleValidationErrors,
  async (req, res, next) => {
    try {
      const { user_id } = req.params;
      const requestUser = (req as AuthenticatedRequest).user;

      // 本人のアカウントのみ削除可能
      if (requestUser?.uid !== user_id) {
        throw new ApiError(403, 'Access denied: Can only delete own account');
      }


      const deleted = await userService.deleteUser(user_id);

      if (!deleted) {
        throw new ApiError(404, 'User not found');
      }


      res.json({
        success: true,
        message: 'User account deleted successfully',
      });
    } catch (error) {
      console.error('[USER DELETE ERROR]', error);
      next(error);
    }
  }
);

export default router;