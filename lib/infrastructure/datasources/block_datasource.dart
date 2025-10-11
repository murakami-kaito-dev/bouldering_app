import '../services/api_client.dart';
import '../../domain/entities/block.dart';

class BlockDataSource {
  final ApiClient _apiClient;

  BlockDataSource(this._apiClient);

  /// ユーザーをブロック
  Future<UserBlock> blockUser(String blockedUserId) async {
    try {
      final response = await _apiClient.post(
        endpoint: '/blocks/$blockedUserId',
        requireAuth: true,
      );
      
      return UserBlock.fromJson(response['data']);
    } catch (e) {
      rethrow;
    }
  }

  /// ユーザーのブロックを解除
  Future<void> unblockUser(String blockedUserId) async {
    try {
      await _apiClient.delete(
        endpoint: '/blocks/$blockedUserId',
        requireAuth: true,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// ブロックしているユーザー一覧を取得
  Future<List<BlockedUser>> getBlockedUsers() async {
    try {
      final response = await _apiClient.get(
        endpoint: '/blocks/blocked-users',
        requireAuth: true,
      );
      final List<dynamic> blockedUsersJson = response['data'];
      return blockedUsersJson
          .map((json) => BlockedUser.fromJson(json))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// 特定のユーザーをブロックしているか確認
  Future<bool> isBlocked(String targetUserId) async {
    try {
      final response = await _apiClient.get(
        endpoint: '/blocks/is-blocked/$targetUserId',
        requireAuth: true,
      );
      return response['data']['isBlocked'] as bool;
    } catch (e) {
      rethrow;
    }
  }

  /// 相互ブロック状態を確認（APIにはないので、isBlockedを使用）
  Future<bool> isMutuallyBlocked(String targetUserId) async {
    // バックエンドAPIにmutual確認がないため、isBlockedで代用
    return await isBlocked(targetUserId);
  }
}