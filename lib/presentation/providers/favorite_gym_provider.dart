import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/favorite_usecases.dart';
import 'dependency_injection.dart';
import 'user_provider.dart';

/// イキタイジム状態管理Provider
///
/// 役割:
/// - イキタイジムの管理
/// - イキタイ関係の追加・削除機能
///
/// クリーンアーキテクチャにおける位置づけ:
/// - Presentation層の状態管理
/// - Domain層のUseCaseを呼び出し
/// - UIコンポーネントから参照される

/// イキタイジム状態を管理するStateNotifier
class FavoriteGymNotifier extends StateNotifier<AsyncValue<List<int>>> {
  final ManageFavoriteGymUseCase _manageFavoriteGymUseCase;
  String? _currentUserId;

  /// コンストラクタ
  FavoriteGymNotifier(this._manageFavoriteGymUseCase)
      : super(const AsyncValue.data([]));

  /// 現在のユーザーIDを設定
  void setCurrentUserId(String userId) {
    _currentUserId = userId;
  }

  /// イキタイジム一覧を読み込み
  ///
  /// [userId] 基準となるユーザーID
  ///
  /// 指定ユーザーがイキタイ登録しているジム一覧を取得
  Future<void> loadFavoriteGyms(String userId) async {
    if (userId.trim().isEmpty) {
      state = AsyncValue.error(
        ArgumentError('ユーザーIDは必須です'),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncValue.loading();
    _currentUserId = userId;

    try {
      final favoriteGymIds =
          await _manageFavoriteGymUseCase.getFavoriteGyms(userId);
      state = AsyncValue.data(favoriteGymIds);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// イキタイジムを追加
  ///
  /// [gymId] イキタイに追加するジムID
  ///
  /// 現在ログイン中のユーザーのイキタイに追加
  Future<bool> addFavoriteGym(int gymId) async {
    if (_currentUserId == null || _currentUserId!.trim().isEmpty) {
      state = AsyncValue.error(
        Exception('ログインが必要です'),
        StackTrace.current,
      );
      return false;
    }

    if (gymId <= 0) {
      state = AsyncValue.error(
        ArgumentError('無効なジムIDです'),
        StackTrace.current,
      );
      return false;
    }

    try {
      final success = await _manageFavoriteGymUseCase.addFavoriteGym(
        _currentUserId!,
        gymId,
      );

      if (success) {
        // 現在のリストに追加
        final currentList = state.value ?? [];
        if (!currentList.contains(gymId)) {
          final updatedList = [...currentList, gymId];
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

  /// イキタイジムを削除
  ///
  /// [gymId] イキタイから削除するジムID
  ///
  /// 現在ログイン中のユーザーのイキタイから削除
  Future<bool> removeFavoriteGym(int gymId) async {
    if (_currentUserId == null || _currentUserId!.trim().isEmpty) {
      state = AsyncValue.error(
        Exception('ログインが必要です'),
        StackTrace.current,
      );
      return false;
    }

    if (gymId <= 0) {
      return false;
    }

    try {
      final success = await _manageFavoriteGymUseCase.removeFavoriteGym(
        _currentUserId!,
        gymId,
      );

      if (success) {
        // 現在のリストから削除
        final currentList = state.value ?? [];
        final updatedList = currentList.where((id) => id != gymId).toList();
        state = AsyncValue.data(updatedList);
      }

      return success;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return false;
    }
  }

  /// イキタイ関係の確認
  ///
  /// [gymId] 確認対象のジムID
  ///
  /// 現在ログイン中のユーザーが指定ジムをイキタイ登録しているかチェック
  bool isFavoriteGym(int gymId) {
    final currentList = state.value ?? [];
    return currentList.contains(gymId);
  }

  /// イキタイジム一覧を手動更新
  ///
  /// プルリフレッシュなどで使用
  Future<void> refresh() async {
    if (_currentUserId != null) {
      await loadFavoriteGyms(_currentUserId!);
    }
  }
}

// ==================== Provider定義 ====================

/// イキタイジム状態管理Provider
///
/// ログインユーザーのイキタイジム一覧を管理
final favoriteGymProvider =
    StateNotifierProvider<FavoriteGymNotifier, AsyncValue<List<int>>>((ref) {
  final manageFavoriteGymUseCase = ref.read(manageFavoriteGymUseCaseProvider);
  final notifier = FavoriteGymNotifier(manageFavoriteGymUseCase);

  // ログインユーザーが変更された場合の自動更新
  ref.listen<User?>(currentUserProvider, (previous, next) {
    if (next != null && (previous?.id != next.id)) {
      notifier.setCurrentUserId(next.id);
      notifier.loadFavoriteGyms(next.id);
    } else if (next == null) {
      // ログアウト時はリストをクリア
      notifier.setCurrentUserId('');
      notifier.loadFavoriteGyms('');
    }
  });

  return notifier;
});

/// 特定ジムイキタイ状態Provider
///
/// 指定されたジムがイキタイ登録されているかを確認
final isFavoriteGymProvider = Provider.family<bool, int>((ref, gymId) {
  final favoriteGyms = ref.watch(favoriteGymProvider);

  return favoriteGyms.when(
    data: (gymIds) => gymIds.contains(gymId),
    loading: () => false,
    error: (_, __) => false,
  );
});

/// イキタイジム数Provider
///
/// 現在のイキタイジム数を取得
final favoriteGymCountProvider = Provider<int>((ref) {
  final favoriteGymsState = ref.watch(favoriteGymProvider);
  return favoriteGymsState.maybeWhen(
    data: (gymIds) => gymIds.length,
    orElse: () => 0,
  );
});
