import '../entities/block.dart';

abstract class BlockRepository {
  /// ユーザーをブロック
  Future<UserBlock> blockUser(String blockedUserId);
  
  /// ユーザーのブロックを解除
  Future<void> unblockUser(String blockedUserId);
  
  /// ブロックしているユーザー一覧を取得
  Future<List<BlockedUser>> getBlockedUsers();
  
  /// 特定のユーザーをブロックしているか確認
  Future<bool> isBlocked(String targetUserId);
  
  /// 相互ブロック状態を確認
  Future<bool> isMutuallyBlocked(String targetUserId);
}