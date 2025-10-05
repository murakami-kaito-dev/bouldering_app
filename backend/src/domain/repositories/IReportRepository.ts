import { Report } from '../../models/types';

/**
 * Report repository interface for Clean Architecture
 * 
 * This interface defines the contract for report data operations
 * Following the Repository pattern and dependency inversion principle
 */
export interface IReportRepository {
  /**
   * Create a new report
   * @param report Report data to create
   * @returns Created report with generated ID
   */
  createReport(report: Omit<Report, 'report_id' | 'status' | 'created_at' | 'reviewed_at'>): Promise<Report>;
}