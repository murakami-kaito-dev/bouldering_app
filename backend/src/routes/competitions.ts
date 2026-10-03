import { Router } from 'express';
import { authenticate, optionalAuthenticate, AuthenticatedRequest } from '../middleware/auth';
import { handleValidationErrors } from '../middleware/validation';
import { getCompetitionService } from '../infrastructure/setup/dependencies';
import {
  validateCompetitionId,
  validateCompetitionInput,
  validateProblemNo,
} from '../utils/validation';
import { ApiError } from '../middleware/error';

const router = Router();
const competitionService = getCompetitionService();

/**
 * コンペティションのエンドポイント（デモ機能・dev 先行）
 *
 * 実際のURL（/api/competitions がベースパス）:
 * GET    /api/competitions                         - 開催中のコンペ一覧（任意認証。ログイン時はホームジムのコンペが先頭）
 * GET    /api/competitions/hosted                  - 自分が開催者のコンペ一覧（要認証。管理者でなければ空）
 * GET    /api/competitions/joined                  - 自分が参加中のコンペ一覧（要認証）
 * POST   /api/competitions                         - 開催（要認証・ジム管理者のみ）
 * GET    /api/competitions/:competition_id         - 1 件取得（任意認証）
 * PATCH  /api/competitions/:competition_id         - 編集（要認証・開催者のみ）
 * POST   /api/competitions/:competition_id/entries - 参加（要認証・開催中のみ・冪等）
 * GET    /api/competitions/:competition_id/leaderboard - 順位表（任意認証）
 * PUT    /api/competitions/:competition_id/results/:problem_no    - 完登を記録（要認証・参加者のみ）
 * DELETE /api/competitions/:competition_id/results/:problem_no    - 完登を取り消す（要認証・参加者のみ）
 *
 * 時刻の基準は JST 固定（期間は 'YYYY-MM-DD' の日付。終了日の 23:59:59 まで開催中）
 */

function requireUser(req: AuthenticatedRequest): { uid: string } {
  const user = req.user;
  if (!user) throw new ApiError(401, 'Authentication required');
  return user;
}

// 53. List active competitions
router.get('/', optionalAuthenticate, async (req, res, next) => {
  try {
    const viewer = (req as AuthenticatedRequest).user?.uid ?? null;
    const competitions = await competitionService.listActive(viewer);
    res.json({ success: true, data: competitions });
  } catch (error) {
    next(error);
  }
});

// 54. List competitions I host（/:competition_id より前に定義して衝突を避ける）
router.get('/hosted', authenticate, async (req, res, next) => {
  try {
    const { uid } = requireUser(req as AuthenticatedRequest);
    const competitions = await competitionService.listHosted(uid);
    res.json({ success: true, data: competitions });
  } catch (error) {
    next(error);
  }
});

// 55. List competitions I joined
router.get('/joined', authenticate, async (req, res, next) => {
  try {
    const { uid } = requireUser(req as AuthenticatedRequest);
    const competitions = await competitionService.listJoined(uid);
    res.json({ success: true, data: competitions });
  } catch (error) {
    next(error);
  }
});

// 56. Host a competition
router.post(
  '/',
  authenticate,
  validateCompetitionInput(),
  handleValidationErrors,
  async (req, res, next) => {
    try {
      const { uid } = requireUser(req as AuthenticatedRequest);
      const competition = await competitionService.create(uid, toInput(req.body));
      res.status(201).json({ success: true, data: competition });
    } catch (error) {
      next(error);
    }
  }
);

// 57. Get a competition
router.get(
  '/:competition_id',
  optionalAuthenticate,
  validateCompetitionId(),
  handleValidationErrors,
  async (req, res, next) => {
    try {
      const viewer = (req as AuthenticatedRequest).user?.uid ?? null;
      const competition = await competitionService.getById(parseInt(req.params.competition_id), viewer);
      res.json({ success: true, data: competition });
    } catch (error) {
      next(error);
    }
  }
);

// 58. Edit a competition
router.patch(
  '/:competition_id',
  authenticate,
  validateCompetitionId(),
  validateCompetitionInput(),
  handleValidationErrors,
  async (req, res, next) => {
    try {
      const { uid } = requireUser(req as AuthenticatedRequest);
      const competition = await competitionService.update(parseInt(req.params.competition_id), uid, toInput(req.body));
      res.json({ success: true, data: competition });
    } catch (error) {
      next(error);
    }
  }
);

// 59. Join a competition
router.post(
  '/:competition_id/entries',
  authenticate,
  validateCompetitionId(),
  handleValidationErrors,
  async (req, res, next) => {
    try {
      const { uid } = requireUser(req as AuthenticatedRequest);
      const competition = await competitionService.join(parseInt(req.params.competition_id), uid);
      res.json({ success: true, data: competition });
    } catch (error) {
      next(error);
    }
  }
);

// 60. Leaderboard
router.get(
  '/:competition_id/leaderboard',
  optionalAuthenticate,
  validateCompetitionId(),
  handleValidationErrors,
  async (req, res, next) => {
    try {
      const viewer = (req as AuthenticatedRequest).user?.uid ?? null;
      const leaderboard = await competitionService.getLeaderboard(parseInt(req.params.competition_id), viewer);
      res.json({ success: true, data: leaderboard });
    } catch (error) {
      next(error);
    }
  }
);

// 61. Record a completed problem
router.put(
  '/:competition_id/results/:problem_no',
  authenticate,
  validateCompetitionId(),
  validateProblemNo(),
  handleValidationErrors,
  async (req, res, next) => {
    try {
      const { uid } = requireUser(req as AuthenticatedRequest);
      const result = await competitionService.setCompleted(
        parseInt(req.params.competition_id), uid, parseInt(req.params.problem_no), true
      );
      res.json({ success: true, data: result });
    } catch (error) {
      next(error);
    }
  }
);

// 62. Remove a completed problem
router.delete(
  '/:competition_id/results/:problem_no',
  authenticate,
  validateCompetitionId(),
  validateProblemNo(),
  handleValidationErrors,
  async (req, res, next) => {
    try {
      const { uid } = requireUser(req as AuthenticatedRequest);
      const result = await competitionService.setCompleted(
        parseInt(req.params.competition_id), uid, parseInt(req.params.problem_no), false
      );
      res.json({ success: true, data: result });
    } catch (error) {
      next(error);
    }
  }
);

/** body → CompetitionInput（express-validator で型は確認済み） */
function toInput(body: Record<string, unknown>) {
  return {
    title: typeof body.title === 'string' ? body.title.trim() : '',
    start_date: String(body.start_date),
    end_date: String(body.end_date),
    problem_from: Number(body.problem_from),
    problem_to: Number(body.problem_to),
    entry_fee_yen: body.entry_fee_yen == null ? 0 : Number(body.entry_fee_yen),
  };
}

export default router;
