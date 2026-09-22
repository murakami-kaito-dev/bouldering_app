/**
 * お知らせリポジトリインターフェース（Issue #81）
 *
 * クリーンアーキテクチャにおける位置づけ:
 * - Domain 層のインターフェース
 * - お知らせ（運営の公式＋ジム発信）データアクセスの抽象化
 */

export interface AnnouncementRow {
  announcement_id: number;
  /** NULL = 運営の公式お知らせ */
  gym_id: number | null;
  gym_name: string | null;
  title: string;
  body: string;
  image_url: string | null;
  link_url: string | null;
  published_at: Date;
}

export interface IAnnouncementRepository {
  /**
   * お知らせ一覧（新しい順）
   * - 公式（gym_id NULL）は常に含む
   * - userId があれば、そのユーザーのホームジム・イキタイジムのお知らせも含む
   * @param cursor 前ページ最後の published_at（これより古いものを返す）
   */
  listAnnouncements(limit: number, cursor?: string, userId?: string): Promise<AnnouncementRow[]>;
}
