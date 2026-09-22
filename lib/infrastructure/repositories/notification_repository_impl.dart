import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_datasource.dart';

/// 通知リポジトリ実装
class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationDataSource _dataSource;

  NotificationRepositoryImpl(this._dataSource);

  @override
  Future<List<AppNotification>> getNotifications(String userId,
      {int limit = 30, String? cursor}) {
    return _dataSource.getNotifications(userId, limit: limit, cursor: cursor);
  }

  @override
  Future<int> getUnreadCount(String userId) {
    return _dataSource.getUnreadCount(userId);
  }

  @override
  Future<void> markRead(String userId, {int? upToId}) {
    return _dataSource.markRead(userId, upToId: upToId);
  }
}
