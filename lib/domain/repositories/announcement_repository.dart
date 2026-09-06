import '../entities/announcement.dart';

/// お知らせリポジトリ（Issue #81）
abstract class AnnouncementRepository {
  /// お知らせ一覧（新しい順）。ログイン時は本人のホームジム・イキタイジム分も含む
  ///
  /// [cursor] 前ページ最後の `publishedAt`（ISO8601）。null で先頭から
  Future<List<Announcement>> getAnnouncements({int limit = 20, String? cursor});
}
