import '../../domain/entities/block.dart';
import '../../domain/repositories/block_repository.dart';
import '../datasources/block_datasource.dart';

class BlockRepositoryImpl implements BlockRepository {
  final BlockDataSource _dataSource;

  const BlockRepositoryImpl(this._dataSource);

  @override
  Future<UserBlock> blockUser(String blockedUserId) async {
    try {
      return await _dataSource.blockUser(blockedUserId);
    } catch (e) {
      throw Exception('Failed to block user: $e');
    }
  }

  @override
  Future<void> unblockUser(String blockedUserId) async {
    try {
      await _dataSource.unblockUser(blockedUserId);
    } catch (e) {
      throw Exception('Failed to unblock user: $e');
    }
  }

  @override
  Future<List<BlockedUser>> getBlockedUsers() async {
    try {
      return await _dataSource.getBlockedUsers();
    } catch (e) {
      throw Exception('Failed to get blocked users: $e');
    }
  }

  @override
  Future<bool> isBlocked(String targetUserId) async {
    try {
      return await _dataSource.isBlocked(targetUserId);
    } catch (e) {
      throw Exception('Failed to check block status: $e');
    }
  }

  @override
  Future<bool> isMutuallyBlocked(String targetUserId) async {
    try {
      return await _dataSource.isMutuallyBlocked(targetUserId);
    } catch (e) {
      throw Exception('Failed to check mutual block status: $e');
    }
  }
}