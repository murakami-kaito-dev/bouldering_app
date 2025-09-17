import '../services/api_client.dart';

/// お気に入り関係データソースクラス
///
/// 役割:
/// - お気に入りユーザーとイキタイジムの関係データのAPI通信を担当
/// - APIレスポンスとDomainエンティティ間の変換
/// - お気に入り追加・削除、関係性の確認処理
///
/// クリーンアーキテクチャにおける位置づけ:
/// - Infrastructure層のデータソースコンポーネント
/// - 外部API（お気に入り関係API）との通信窓口
/// - Repository実装から呼び出される
class FavoriteDataSource {
  final ApiClient _apiClient;

  /// コンストラクタ
  ///
  /// [_apiClient] API通信クライアント
  FavoriteDataSource(this._apiClient);

  /// お気に入りユーザーID一覧取得
  ///
  /// [userId] 基準となるユーザーID
  ///
  /// 返り値:
  /// [List<String>] お気に入りに登録しているユーザーIDリスト
  ///
  /// 処理フロー:
  /// 1. REST API: GET /api/users/{userId}/favorites/users で取得
  /// 2. APIエラー時は例外を上位に伝播
  Future<List<String>> getFavoriteUserIds(String userId) async {
    try {
      final response = await _apiClient.get(
        endpoint: '/users/$userId/favorites/users',
        requireAuth: true,
      );

      final List<dynamic> favoriteData = response['data'] ?? [];
      return favoriteData
          .map((item) => item['likee_user_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList();
    } catch (e) {
      throw Exception('お気に入りユーザー取得に失敗しました: $e');
    }
  }

  /// 自分をお気に入りに登録しているユーザーID一覧取得
  ///
  /// [userId] 基準となるユーザーID
  ///
  /// 返り値:
  /// [List<String>] 自分をお気に入りに登録しているユーザーIDリスト
  ///
  /// 処理フロー:
  /// 1. REST API: GET /api/users/{userId}/favorited-by で取得
  /// 2. APIエラー時は例外を上位に伝播
  Future<List<String>> getFavoritedByUserIds(String userId) async {
    try {
      final response = await _apiClient.get(
        endpoint: '/users/$userId/favorited-by',
        requireAuth: true,
      );

      final List<dynamic> favoriteData = response['data'] ?? [];
      return favoriteData
          .map((item) => item['liker_user_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList();
    } catch (e) {
      throw Exception('お気に入りされているユーザー取得に失敗しました: $e');
    }
  }

  /// お気に入りユーザー追加
  ///
  /// [likerUserId] お気に入りを追加するユーザーID
  /// [likeeUserId] お気に入りに追加されるユーザーID
  ///
  /// 返り値:
  /// [bool] 追加成功時はtrue、失敗時はfalse
  ///
  /// 処理フロー:
  /// 1. REST API: POST /api/users/{likerUserId}/favorites/users で追加
  /// 2. APIエラー時は例外を上位に伝播
  Future<bool> addFavoriteUser(String likerUserId, String likeeUserId) async {
    try {
      final response = await _apiClient.post(
        endpoint: '/users/$likerUserId/favorites/users',
        body: {'likee_user_id': likeeUserId},
        requireAuth: true,
      );
      
      final success = response['success'] == true;
      return success;
    } catch (e) {
      throw Exception('お気に入りユーザー追加に失敗しました: $e');
    }
  }

  /// お気に入りユーザー削除
  ///
  /// [likerUserId] お気に入りを削除するユーザーID
  /// [likeeUserId] お気に入りから削除されるユーザーID
  ///
  /// 返り値:
  /// [bool] 削除成功時はtrue、失敗時はfalse
  ///
  /// 処理フロー:
  /// 1. REST API: DELETE /api/users/{likerUserId}/favorites/users/{likeeUserId} で削除
  /// 2. APIエラー時は例外を上位に伝播
  Future<bool> removeFavoriteUser(
      String likerUserId, String likeeUserId) async {
    try {
      final response = await _apiClient.delete(
        endpoint: '/users/$likerUserId/favorites/users/$likeeUserId',
        requireAuth: true,
      );

      return response['success'] == true;
    } catch (e) {
      throw Exception('お気に入りユーザー削除に失敗しました: $e');
    }
  }

  /// お気に入りユーザー関係確認
  ///
  /// [likerUserId] お気に入りを確認するユーザーID
  /// [likeeUserId] お気に入りに登録されているか確認するユーザーID
  ///
  /// 返り値:
  /// [bool] お気に入り関係が存在する場合はtrue、しない場合はfalse
  ///
  /// 処理フロー:
  /// 1. REST API: GET /api/users/{likerUserId}/favorites/users/{likeeUserId} で確認
  /// 2. APIエラー時は例外を上位に伝播
  Future<bool> isFavoriteUser(String likerUserId, String likeeUserId) async {
    try {
      final response = await _apiClient.get(
        endpoint: '/users/$likerUserId/favorites/users/$likeeUserId',
        requireAuth: true,
      );

      return response['exists'] == true;
    } catch (e) {
      throw Exception('お気に入り関係確認に失敗しました: $e');
    }
  }

  /// イキタイジムID一覧取得
  ///
  /// [userId] 基準となるユーザーID
  ///
  /// 返り値:
  /// [List<int>] イキタイに登録しているジムIDリスト
  ///
  /// 処理フロー:
  /// 1. REST API: GET /api/users/{userId}/favorite-gyms で取得
  /// 2. APIエラー時は例外を上位に伝播
  Future<List<int>> getFavoriteGymIds(String userId) async {
    try {
      final response = await _apiClient.get(
        endpoint: '/users/$userId/favorite-gyms',
      );

      final List<dynamic> favoriteData = response['data'] ?? [];
      return favoriteData
          .map((item) => _parseInt(item['gym_id']) ?? 0)
          .where((id) => id > 0)
          .toList();
    } catch (e) {
      throw Exception('イキタイジム取得に失敗しました: $e');
    }
  }

  /// イキタイジム追加
  ///
  /// [userId] イキタイを追加するユーザーID
  /// [gymId] イキタイに追加するジムID
  ///
  /// 返り値:
  /// [bool] 追加成功時はtrue、失敗時はfalse
  ///
  /// 処理フロー:
  /// 1. REST API: POST /api/users/{userId}/favorite-gyms で追加
  /// 2. APIエラー時は例外を上位に伝播
  Future<bool> addFavoriteGym(String userId, int gymId) async {
    try {
      final response = await _apiClient.post(
        endpoint: '/users/$userId/favorite-gyms',
        body: {'gym_id': gymId},
        requireAuth: true,
      );

      return response['success'] == true;
    } catch (e) {
      throw Exception('イキタイジム追加に失敗しました: $e');
    }
  }

  /// イキタイジム削除
  ///
  /// [userId] イキタイを削除するユーザーID
  /// [gymId] イキタイから削除するジムID
  ///
  /// 返り値:
  /// [bool] 削除成功時はtrue、失敗時はfalse
  ///
  /// 処理フロー:
  /// 1. REST API: DELETE /api/users/{userId}/favorite-gyms/{gymId} で削除
  /// 2. APIエラー時は例外を上位に伝播
  Future<bool> removeFavoriteGym(String userId, int gymId) async {
    try {
      final response = await _apiClient.delete(
        endpoint: '/users/$userId/favorite-gyms/$gymId',
        requireAuth: true,
      );

      return response['success'] == true;
    } catch (e) {
      throw Exception('イキタイジム削除に失敗しました: $e');
    }
  }

  /// イキタイジム関係確認
  ///
  /// [userId] イキタイを確認するユーザーID
  /// [gymId] イキタイに登録されているか確認するジムID
  ///
  /// 返り値:
  /// [bool] イキタイ関係が存在する場合はtrue、しない場合はfalse
  ///
  /// 処理フロー:
  /// 1. REST API: GET /api/users/{userId}/favorite-gyms/{gymId} で確認
  /// 2. APIエラー時は例外を上位に伝播
  Future<bool> isFavoriteGym(String userId, int gymId) async {
    try {
      final response = await _apiClient.get(
        endpoint: '/users/$userId/favorite-gyms/$gymId',
        requireAuth: true,
      );

      return response['exists'] == true;
    } catch (e) {
      throw Exception('イキタイ関係確認に失敗しました: $e');
    }
  }

  /// お気に入りジム一覧取得（公開情報）
  ///
  /// [userId] 取得対象のユーザーID
  ///
  /// 返り値:
  /// [List<Map<String, dynamic>>] お気に入りジム情報リスト
  ///
  /// 処理フロー:
  /// 1. REST API: GET /api/users/{userId}/favorite-gyms で取得（認証不要）
  /// 2. APIエラー時は例外を上位に伝播
  Future<List<Map<String, dynamic>>> getFavoriteGyms(String userId) async {
    try {
      final response = await _apiClient.get(
        endpoint: '/users/$userId/favorite-gyms',
        requireAuth: false, // Public access
      );

      final List<dynamic> gymData = response['data'] ?? [];
      return gymData.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      throw Exception('お気に入りジム取得に失敗しました: $e');
    }
  }

  /// 文字列をintに安全に変換
  ///
  /// [value] 変換対象の値
  ///
  /// 返り値:
  /// [int?] 変換結果、失敗時はnull
  int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }
}
