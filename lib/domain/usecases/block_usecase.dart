import '../entities/block.dart';
import '../repositories/block_repository.dart';

class BlockUseCase {
  final BlockRepository _repository;

  const BlockUseCase(this._repository);

  /// ユーザーをブロック
  Future<UserBlock> blockUser(String blockedUserId) async {
    return await _repository.blockUser(blockedUserId);
  }

  /// ユーザーのブロックを解除
  Future<void> unblockUser(String blockedUserId) async {
    return await _repository.unblockUser(blockedUserId);
  }

  /// ブロックしているユーザー一覧を取得
  Future<List<BlockedUser>> getBlockedUsers() async {
    return await _repository.getBlockedUsers();
  }

  /// 特定のユーザーをブロックしているか確認
  Future<bool> isBlocked(String targetUserId) async {
    return await _repository.isBlocked(targetUserId);
  }

  /// 相互ブロック状態を確認
  Future<bool> isMutuallyBlocked(String targetUserId) async {
    return await _repository.isMutuallyBlocked(targetUserId);
  }
}