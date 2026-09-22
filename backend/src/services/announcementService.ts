import {
  IAnnouncementRepository,
  AnnouncementRow,
} from '../domain/repositories/IAnnouncementRepository';

/**
 * お知らせサービス（Issue #81）
 *
 * クリーンアーキテクチャにおける位置づけ:
 * - Application 層のサービス
 * - 公式＋本人に関係するジムのお知らせを一覧で返す（イベントバスは使わない）
 */
export class AnnouncementService {
  constructor(private announcementRepository: IAnnouncementRepository) {}

  async getAnnouncements(limit: number = 20, cursor?: string, userId?: string): Promise<AnnouncementRow[]> {
    return await this.announcementRepository.listAnnouncements(limit, cursor, userId);
  }
}
