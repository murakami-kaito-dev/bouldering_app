import '../entities/announcement.dart';
import '../entities/app_notification.dart';
import '../exceptions/app_exceptions.dart';
import '../repositories/announcement_repository.dart';
import '../repositories/notification_repository.dart';

/// 通知一覧取得
class GetNotificationsUseCase {
  final NotificationRepository _repository;

  GetNotificationsUseCase(this._repository);

  Future<List<AppNotification>> execute(String userId,
      {int limit = 30, String? cursor}) async {
    try {
      return await _repository.getNotifications(userId,
          limit: limit, cursor: cursor);
    } catch (e) {
      throw DataFetchException(
        message: '通知の取得に失敗しました',
        originalError: e,
      );
    }
  }
}

/// 未読数取得
class GetUnreadNotificationCountUseCase {
  final NotificationRepository _repository;

  GetUnreadNotificationCountUseCase(this._repository);

  Future<int> execute(String userId) async {
    try {
      return await _repository.getUnreadCount(userId);
    } catch (e) {
      throw DataFetchException(
        message: '未読数の取得に失敗しました',
        originalError: e,
      );
    }
  }
}

/// 既読化
class MarkNotificationsReadUseCase {
  final NotificationRepository _repository;

  MarkNotificationsReadUseCase(this._repository);

  Future<void> execute(String userId, {int? upToId}) async {
    try {
      await _repository.markRead(userId, upToId: upToId);
    } catch (e) {
      throw DataSaveException(
        message: '既読の更新に失敗しました',
        originalError: e,
      );
    }
  }
}

/// お知らせ一覧取得
class GetAnnouncementsUseCase {
  final AnnouncementRepository _repository;

  GetAnnouncementsUseCase(this._repository);

  Future<List<Announcement>> execute({int limit = 20, String? cursor}) async {
    try {
      return await _repository.getAnnouncements(limit: limit, cursor: cursor);
    } catch (e) {
      throw DataFetchException(
        message: 'お知らせの取得に失敗しました',
        originalError: e,
      );
    }
  }
}
