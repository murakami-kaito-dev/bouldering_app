import { db } from '../../config/database';
import { Report } from '../../models/types';
import { IReportRepository } from '../../domain/repositories/IReportRepository';
import logger from '../../utils/logger';

/**
 * 報告機能のPostgreSQL実装
 * 
 * reportsテーブルへのデータ操作を担当
 */
export class PostgresReportRepository implements IReportRepository {

  /**
   * 新しい報告をデータベースに作成
   * 
   * @param report 報告データ（report_id, status, created_at, reviewed_atは自動設定）
   * @returns 作成された報告の完全なデータ
   */
  async createReport(
    report: Omit<Report, 'report_id' | 'status' | 'created_at' | 'reviewed_at'>
  ): Promise<Report> {
    const query = `
      INSERT INTO reports (reporter_user_id, target_user_id, target_tweet_id, report_description)
      VALUES ($1, $2, $3, $4)
      RETURNING *
    `;

    const values = [
      report.reporter_user_id,
      report.target_user_id,
      report.target_tweet_id,
      report.report_description || null,
    ];

    try {
      const result = await db.query(query, values);
      
      if (result.length === 0) {
        throw new Error('報告の作成に失敗しました');
      }

      logger.info('報告が正常に作成されました', {
        report_id: result[0].report_id,
        reporter_user_id: report.reporter_user_id,
        target_tweet_id: report.target_tweet_id,
      });

      return result[0];
    } catch (error) {
      logger.error('報告作成エラー', {
        error: error instanceof Error ? error.message : '不明なエラー',
        reporter_user_id: report.reporter_user_id,
        target_tweet_id: report.target_tweet_id,
      });
      throw error;
    }
  }
}