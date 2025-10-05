import { Report } from '../models/types';
import { IReportRepository } from '../domain/repositories/IReportRepository';
import { ApiError } from '../middleware/error';
import logger from '../utils/logger';

/**
 * 報告サービス
 * 
 * ビジネスロジックとバリデーションを担当
 * リポジトリ層への橋渡し役
 */
export class ReportService {
  constructor(private reportRepository: IReportRepository) {}

  /**
   * 報告を作成
   * 
   * @param reportData 報告データ
   * @returns 作成された報告
   */
  async createReport(reportData: {
    reporter_user_id: string;
    target_user_id: string;
    target_tweet_id: number;
    report_description?: string;
  }): Promise<Report> {
    // 基本的なバリデーション
    if (!reportData.reporter_user_id || !reportData.target_user_id || !reportData.target_tweet_id) {
      throw new ApiError(400, '必須パラメータが不足しています');
    }

    // 説明文の長さチェック（フロントエンドでも制限しているが念のため）
    if (reportData.report_description && reportData.report_description.length > 1000) {
      throw new ApiError(400, '報告内容は1000文字以内で入力してください');
    }

    try {
      const report = await this.reportRepository.createReport({
        reporter_user_id: reportData.reporter_user_id,
        target_user_id: reportData.target_user_id,
        target_tweet_id: reportData.target_tweet_id,
        report_description: reportData.report_description,
      });

      logger.info('報告サービス: 報告を作成しました', {
        report_id: report.report_id,
        reporter: reportData.reporter_user_id,
        target_tweet: reportData.target_tweet_id,
      });

      return report;
    } catch (error) {
      logger.error('報告サービス: 報告作成エラー', {
        error: error instanceof Error ? error.message : '不明なエラー',
        reportData,
      });
      
      if (error instanceof ApiError) {
        throw error;
      }
      
      throw new ApiError(500, '報告の作成に失敗しました');
    }
  }
}