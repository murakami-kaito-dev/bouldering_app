import '../services/api_client.dart';
import '../../domain/entities/announcement.dart';

/// お知らせデータソース（Issue #81）
///
/// 役割:
/// - お知らせ API 通信を担当（未ログインでも取得可。ログイン時はトークンが付き、
///   本人のホームジム・イキタイジムのお知らせも含まれる）
///
/// クリーンアーキテクチャにおける位置づけ:
/// - Infrastructure 層のデータソース
class AnnouncementDataSource {
  final ApiClient _apiClient;

  AnnouncementDataSource(this._apiClient);

  /// お知らせ一覧取得
  ///
  /// REST API: GET /api/announcements?limit=&cursor=
  Future<List<Announcement>> getAnnouncements({
    int limit = 20,
    String? cursor,
  }) async {
    try {
      final parameters = <String, String>{
        'limit': limit.toString(),
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      };

      final response = await _apiClient.get(
        endpoint: '/announcements',
        parameters: parameters,
        requireAuth: false, // 任意認証（ログイン済みならトークンが付く）
      );

      final List<dynamic> data = response['data'] ?? [];
      return data
          .map((item) => Announcement.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('お知らせ取得に失敗しました: $e');
    }
  }
}
