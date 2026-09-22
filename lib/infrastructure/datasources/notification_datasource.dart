import '../services/api_client.dart';
import '../../domain/entities/app_notification.dart';

/// 通知データソース（Issue #81）
///
/// 役割:
/// - 通知関連の API 通信を担当（すべて認証必須・本人のみ）
/// - API レスポンスと Domain エンティティ間の変換
///
/// クリーンアーキテクチャにおける位置づけ:
/// - Infrastructure 層のデータソース
/// - Repository 実装から呼び出される
class NotificationDataSource {
  final ApiClient _apiClient;

  NotificationDataSource(this._apiClient);

  /// 通知一覧取得
  ///
  /// REST API: GET /api/users/{userId}/notifications?limit=&cursor=
  Future<List<AppNotification>> getNotifications(
    String userId, {
    int limit = 30,
    String? cursor,
  }) async {
    try {
      final parameters = <String, String>{
        'limit': limit.toString(),
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      };

      final response = await _apiClient.get(
        endpoint: '/users/$userId/notifications',
        parameters: parameters,
        requireAuth: true,
      );

      final List<dynamic> data = response['data'] ?? [];
      return data
          .map((item) => AppNotification.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('通知取得に失敗しました: $e');
    }
  }

  /// 未読数取得
  ///
  /// REST API: GET /api/users/{userId}/notifications/unread-count
  Future<int> getUnreadCount(String userId) async {
    try {
      final response = await _apiClient.get(
        endpoint: '/users/$userId/notifications/unread-count',
        requireAuth: true,
      );
      final data = response['data'];
      final count = data is Map ? data['count'] : null;
      return count is int ? count : int.tryParse('$count') ?? 0;
    } catch (e) {
      throw Exception('未読数取得に失敗しました: $e');
    }
  }

  /// 既読化
  ///
  /// REST API: POST /api/users/{userId}/notifications/read  body { up_to_id? }
  Future<void> markRead(String userId, {int? upToId}) async {
    try {
      await _apiClient.post(
        endpoint: '/users/$userId/notifications/read',
        body: {
          if (upToId != null) 'up_to_id': upToId,
        },
        requireAuth: true,
      );
    } catch (e) {
      throw Exception('既読更新に失敗しました: $e');
    }
  }
}
