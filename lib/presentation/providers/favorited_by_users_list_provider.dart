import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/favorite_usecases.dart';
import 'dependency_injection.dart';
import 'user_provider.dart';
import 'favorite_user_provider.dart';

/// お気に入られユーザー一覧状態管理Provider
/// 
/// 役割:
/// - 自分をお気に入り登録しているユーザーの詳細情報一覧の管理
/// - ユーザー詳細画面から戻った時の状態同期
/// 
/// クリーンアーキテクチャにおける位置づけ:
/// - Presentation層の状態管理
/// - Domain層のUseCaseを呼び出し
/// - UIコンポーネントから参照される

/// お気に入られユーザー一覧を管理するStateNotifier
class FavoritedByUsersListNotifier extends StateNotifier<AsyncValue<List<User>>> {
  final GetFavoritedByUserDetailsUseCase _getFavoritedByUserDetailsUseCase;
  final ManageFavoriteUserUseCase _manageFavoriteUserUseCase;
  final String? Function() _getCurrentUserId;
  final Ref _ref;

  FavoritedByUsersListNotifier(
    this._getFavoritedByUserDetailsUseCase,
    this._manageFavoriteUserUseCase,
    this._getCurrentUserId,
    this._ref,
  ) : super(const AsyncValue.data([]));

  /// お気に入られユーザー一覧を読み込み
  Future<void> loadFavoritedByUsers() async {
    final currentUserId = _getCurrentUserId();
    if (currentUserId == null || currentUserId.trim().isEmpty) {
      state = AsyncValue.error(
        Exception('ログインが必要です'),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncValue.loading();

    try {
      final favoritedByUsers = await _getFavoritedByUserDetailsUseCase
          .getFavoritedByUsersWithDetails(currentUserId);
      state = AsyncValue.data(favoritedByUsers);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// お気に入り状態をトグル（一覧画面から操作）
  /// 
  /// 仕様：
  /// - お気に入り解除してもリストからは削除しない
  /// - マイページに戻るまではリストに表示され続ける
  /// - お気に入り状態の変更のみUI に反映
  Future<bool> toggleFavorite(String targetUserId) async {
    final currentUserId = _getCurrentUserId();
    if (currentUserId == null || currentUserId.trim().isEmpty) {
      return false;
    }

    try {
      // favorite_user_providerの状態を確認
      final isFavorite = _ref.read(isFavoriteUserProvider(targetUserId));

      bool success;
      if (isFavorite) {
        // お気に入り解除
        success = await _manageFavoriteUserUseCase.removeFavorite(
          currentUserId,
          targetUserId,
        );
      } else {
        // お気に入り登録
        success = await _manageFavoriteUserUseCase.addFavorite(
          currentUserId,
          targetUserId,
        );
      }

      if (success) {
        // favorite_user_providerの状態を更新
        await _ref.read(favoriteUserProvider.notifier).refresh();
      }

      return success;
    } catch (e) {
      return false;
    }
  }

  /// 特定ユーザーがお気に入りかチェック
  bool isFavorite(String userId) {
    return _ref.read(isFavoriteUserProvider(userId));
  }

  /// 他ユーザー画面から戻った時の状態同期
  /// 
  /// 他ユーザー画面でお気に入り状態を変更した場合、
  /// この画面に戻ってきた時にUIを更新するが、
  /// リスト自体は再取得しない（仕様通り）
  void syncFavoriteStatus() {
    // UIの再描画をトリガーするために状態を更新
    // データ自体は変更しない
    final currentData = state.value;
    if (currentData != null) {
      state = AsyncValue.data([...currentData]);
    }
  }

  /// リフレッシュ（プルリフレッシュ用）
  Future<void> refresh() async {
    await loadFavoritedByUsers();
  }
}

// ==================== Provider定義 ====================

/// お気に入られユーザー一覧状態管理Provider
final favoritedByUsersListProvider = 
    StateNotifierProvider<FavoritedByUsersListNotifier, AsyncValue<List<User>>>((ref) {
  final getFavoritedByUserDetailsUseCase = ref.read(getFavoritedByUserDetailsUseCaseProvider);
  final manageFavoriteUserUseCase = ref.read(manageFavoriteUserUseCaseProvider);
  
  // 現在のユーザーIDを取得する関数
  String? getCurrentUserId() {
    final currentUser = ref.read(currentUserProvider);
    return currentUser?.id;
  }
  
  return FavoritedByUsersListNotifier(
    getFavoritedByUserDetailsUseCase,
    manageFavoriteUserUseCase,
    getCurrentUserId,
    ref,
  );
});

/// お気に入られユーザー一覧からの状態Provider（他画面から参照用）
/// 
/// 他ユーザー画面などから、現在のお気に入られユーザー一覧画面の
/// 表示状態を確認するために使用
final isInFavoritedByUsersListProvider = Provider.family<bool, String>((ref, userId) {
  final favoritedByUsersList = ref.watch(favoritedByUsersListProvider);
  
  return favoritedByUsersList.when(
    data: (users) => users.any((user) => user.id == userId),
    loading: () => false,
    error: (_, __) => false,
  );
});