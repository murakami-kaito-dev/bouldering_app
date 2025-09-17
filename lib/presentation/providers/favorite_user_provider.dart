import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecases/favorite_usecases.dart';
import 'dependency_injection.dart';
import 'user_provider.dart'; // currentUserProviderが必要

/// お気に入りユーザー状態管理Provider
/// 
/// 役割:
/// - お気に入りユーザーの管理
/// - お気に入り関係の追加・削除機能
/// 
/// クリーンアーキテクチャにおける位置づけ:
/// - Presentation層の状態管理
/// - Domain層のUseCaseを呼び出し
/// - UIコンポーネントから参照される

/// お気に入りユーザー状態を管理するStateNotifier
class FavoriteUserNotifier extends StateNotifier<AsyncValue<List<String>>> {
  final ManageFavoriteUserUseCase _manageFavoriteUserUseCase;
  final String? Function() _getCurrentUserId;

  /// コンストラクタ
  FavoriteUserNotifier(this._manageFavoriteUserUseCase, this._getCurrentUserId) : super(const AsyncValue.data([]));

  /// お気に入りユーザー一覧を読み込み
  /// 
  /// [userId] 基準となるユーザーID
  /// 
  /// 指定ユーザーがお気に入り登録しているユーザー一覧を取得
  Future<void> loadFavoriteUsers(String userId) async {
    if (userId.trim().isEmpty) {
      state = AsyncValue.error(
        ArgumentError('ユーザーIDは必須です'),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncValue.loading();

    try {
      final favoriteUserIds = await _manageFavoriteUserUseCase.getFavoriteUsers(userId);
      state = AsyncValue.data(favoriteUserIds);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// お気に入りユーザーを追加
  /// 
  /// [likeeUserId] お気に入りに追加するユーザーID
  /// 
  /// 現在ログイン中のユーザーのお気に入りに追加
  Future<bool> addFavoriteUser(String likeeUserId) async {
    // 現在のユーザーIDを取得
    final currentUserId = _getCurrentUserId();
    
    if (currentUserId == null || currentUserId.trim().isEmpty) {
      state = AsyncValue.error(
        Exception('ログインが必要です'),
        StackTrace.current,
      );
      return false;
    }

    if (likeeUserId.trim().isEmpty) {
      state = AsyncValue.error(
        ArgumentError('追加対象のユーザーIDは必須です'),
        StackTrace.current,
      );
      return false;
    }

    try {
      final success = await _manageFavoriteUserUseCase.addFavorite(
        currentUserId,
        likeeUserId,
      );

      if (success) {
        // 現在のリストに追加
        final currentList = state.value ?? [];
        if (!currentList.contains(likeeUserId)) {
          final updatedList = [...currentList, likeeUserId];
          updatedList.sort(); // ソート維持
          state = AsyncValue.data(updatedList);
        }
      }

      return success;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return false;
    }
  }

  /// お気に入りユーザーを削除
  /// 
  /// [likeeUserId] お気に入りから削除するユーザーID
  /// 
  /// 現在ログイン中のユーザーのお気に入りから削除
  Future<bool> removeFavoriteUser(String likeeUserId) async {
    // 現在のユーザーIDを取得
    final currentUserId = _getCurrentUserId();
    
    if (currentUserId == null || currentUserId.trim().isEmpty) {
      state = AsyncValue.error(
        Exception('ログインが必要です'),
        StackTrace.current,
      );
      return false;
    }

    if (likeeUserId.trim().isEmpty) {
      return false;
    }

    try {
      final success = await _manageFavoriteUserUseCase.removeFavorite(
        currentUserId,
        likeeUserId,
      );

      if (success) {
        // 現在のリストから削除
        final currentList = state.value ?? [];
        final updatedList = currentList.where((id) => id != likeeUserId).toList();
        state = AsyncValue.data(updatedList);
      }

      return success;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return false;
    }
  }

  /// お気に入り関係の確認
  /// 
  /// [likeeUserId] 確認対象のユーザーID
  /// 
  /// 現在ログイン中のユーザーが指定ユーザーをお気に入り登録しているかチェック
  bool isFavoriteUser(String likeeUserId) {
    final currentList = state.value ?? [];
    return currentList.contains(likeeUserId);
  }

  /// お気に入りユーザー一覧を手動更新
  /// 
  /// プルリフレッシュなどで使用
  Future<void> refresh() async {
    final currentUserId = _getCurrentUserId();
    if (currentUserId != null && currentUserId.trim().isNotEmpty) {
      await loadFavoriteUsers(currentUserId);
    }
  }
}

// ==================== Provider定義 ====================

/// お気に入りユーザー状態管理Provider
/// 
/// ログインユーザーのお気に入りユーザー一覧を管理
final favoriteUserProvider = StateNotifierProvider<FavoriteUserNotifier, AsyncValue<List<String>>>((ref) {
  final manageFavoriteUserUseCase = ref.read(manageFavoriteUserUseCaseProvider);
  
  // 現在のユーザーIDを取得する関数を作成
  String? getCurrentUserId() {
    final currentUser = ref.read(currentUserProvider);
    return currentUser?.id;
  }
  
  return FavoriteUserNotifier(manageFavoriteUserUseCase, getCurrentUserId);
});

/// 特定ユーザーお気に入り状態Provider
/// 
/// 指定されたユーザーがお気に入り登録されているかを確認
final isFavoriteUserProvider = Provider.family<bool, String>((ref, userId) {
  final favoriteUsers = ref.watch(favoriteUserProvider);
  
  return favoriteUsers.when(
    data: (userIds) => userIds.contains(userId),
    loading: () => false,
    error: (_, __) => false,
  );
});