import '../entities/app_notification.dart';

/// 通知リポジトリ（Issue #81）
abstract class NotificationRepository {
  /// 通知一覧（新しい順・いいねは集約済み）
  ///
  /// [cursor] 前ページ最後の `createdAt`（ISO8601）。null で先頭から
  Future<List<AppNotification>> getNotifications(String userId,
      {int limit = 30, String? cursor});

  /// 未読数
  Future<int> getUnreadCount(String userId);

  /// 既読化。[upToId] があればその ID 以下だけ、無ければ全部
  Future<void> markRead(String userId, {int? upToId});
}
