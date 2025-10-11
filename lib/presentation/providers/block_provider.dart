import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/block.dart';
import '../../domain/usecases/block_usecase.dart';
import 'dependency_injection.dart';

/// ブロック機能の状態管理プロバイダー
/// 
/// 役割:
/// - ブロック機能の状態管理
/// - UIからのブロック操作の処理
/// - ブロックリストの管理
/// 
/// クリーンアーキテクチャにおける位置づけ:
/// - Presentation層のViewModelに相当
/// - UIの状態とUseCase層を仲介
class BlockProvider extends StateNotifier<BlockState> {
  final BlockUseCase _blockUseCase;

  BlockProvider(this._blockUseCase) : super(const BlockState());

  /// ユーザーをブロック
  /// 
  /// 通常のブロック機能（新規ブロック時）
  Future<void> blockUser(String blockedUserId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final block = await _blockUseCase.blockUser(blockedUserId);
      
      // ブロックリストを再取得
      await getBlockedUsers();
      
      state = state.copyWith(
        isLoading: false,
        lastBlockedUser: block,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// ユーザーを再ブロック
  /// 
  /// 仕様：
  /// - ブロックリスト画面で解除後に再度ブロックする場合
  /// - リストは変更せず、DB側のみ状態を変更
  Future<void> reblockUser(String blockedUserId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      await _blockUseCase.blockUser(blockedUserId);
      
      // リストは変更せず、isLoadingのみfalseに戻す
      state = state.copyWith(
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// ユーザーのブロックを解除
  /// 
  /// 仕様：
  /// - ブロック解除してもリストからは削除しない
  /// - settings_page.dartに戻るまではリストに表示され続ける
  /// - DB側のみ状態を変更、View側のリストは維持
  Future<void> unblockUser(String blockedUserId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      await _blockUseCase.unblockUser(blockedUserId);
      
      // リストは変更せず、isLoadingのみfalseに戻す
      // DB側の状態変更のみ実行、View側のリストは維持
      state = state.copyWith(
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// ブロックしているユーザー一覧を取得
  Future<void> getBlockedUsers() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final users = await _blockUseCase.getBlockedUsers();
      
      state = state.copyWith(
        isLoading: false,
        blockedUsers: users,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// 特定のユーザーをブロックしているか確認
  Future<bool> isBlocked(String targetUserId) async {
    try {
      return await _blockUseCase.isBlocked(targetUserId);
    } catch (e) {
      debugPrint('Error checking block status: $e');
      return false;
    }
  }

  /// エラーをクリア
  void clearError() {
    state = state.copyWith(error: null);
  }

}

/// ブロック機能の状態クラス
class BlockState {
  final bool isLoading;
  final List<BlockedUser> blockedUsers;
  final UserBlock? lastBlockedUser;
  final String? error;

  const BlockState({
    this.isLoading = false,
    this.blockedUsers = const [],
    this.lastBlockedUser,
    this.error,
  });

  BlockState copyWith({
    bool? isLoading,
    List<BlockedUser>? blockedUsers,
    UserBlock? lastBlockedUser,
    String? error,
  }) {
    return BlockState(
      isLoading: isLoading ?? this.isLoading,
      blockedUsers: blockedUsers ?? this.blockedUsers,
      lastBlockedUser: lastBlockedUser ?? this.lastBlockedUser,
      error: error,
    );
  }
}

/// ブロックプロバイダーのインスタンス
final blockProvider = StateNotifierProvider<BlockProvider, BlockState>((ref) {
  final blockUseCase = ref.read(blockUseCaseProvider);
  return BlockProvider(blockUseCase);
});

