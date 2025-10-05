import { Router } from 'express';
import { handleValidationErrors } from '../middleware/validation';
import { validateCreateReport } from '../utils/validation';
import { getReportService } from '../infrastructure/setup/dependencies';
import { ApiError } from '../middleware/error';

const router = Router();

/**
 * 報告関連のエンドポイント
 * 
 * POST /api/reports - 報告を作成
 */

// 報告作成エンドポイント
router.post(
  '/',
  validateCreateReport(),
  handleValidationErrors,
  async (req, res, next) => {
    try {
      const {
        reporter_user_id,
        target_user_id,
        target_tweet_id,
        report_description
      } = req.body;

      // ReportServiceをDIコンテナから取得
      const reportService = getReportService();

      // 報告を作成
      const report = await reportService.createReport({
        reporter_user_id,
        target_user_id,
        target_tweet_id,
        report_description,
      });

      // 成功レスポンス（既存のAPIと同じ形式）
      res.status(201).json({
        success: true,
        data: report,
      });
    } catch (error) {
      // エラーハンドリングはerror middlewareに委譲
      next(error);
    }
  }
);

export default router;