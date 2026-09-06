import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/notification_usecases.dart';
import 'dependency_injection.dart';
import 'user_provider.dart';

/// 通知の未読数 Provider（Issue #81）
///
/// 役割:
/// - ボトムナビの通知タブに出すバッジの数を保持する
/// - 取得タイミングは「起動（ユーザー情報の復元完了）時」「通知タブを開いた時」「アプリ復帰時」のみ。
///   ポーリングはしない（仕様）
/// - ログアウトで 0 に戻す
///
/// クリーンアーキテクチャにおける位置づけ:
/// - Presentation 層の状態管理
class UnreadCountNotifier extends StateNotifier<int> {
  final GetUnreadNotificationCountUseCase _getUnreadCount;

  /// 現在のユーザーID（userProvider の変化に追従して更新される）
  String? _userId;
  bool _isFetching = false;

  UnreadCountNotifier(this._getUnreadCount) : super(0);

  /// ログイン中ユーザーの切替（ログアウトなら null）。ユーザーが変われば取り直す
  void setUser(String? userId) {
    if (_userId == userId) return;
    _userId = userId;
    if (userId == null) {
      state = 0;
    } else {
      refresh();
    }
  }

  /// 未読数を取り直す。未ログインなら 0。失敗時は前の値のまま（バッジが暴れないようにする）
  Future<void> refresh() async {
    final userId = _userId;
    if (userId == null) {
      state = 0;
      return;
    }
    if (_isFetching) return;
    _isFetching = true;
    try {
      final count = await _getUnreadCount.execute(userId);
      if (mounted) state = count;
    } catch (e) {
      debugPrint('[UNREAD COUNT] 取得失敗: $e');
    } finally {
      _isFetching = false;
    }
  }

  /// 既読化後にバッジを消す
  void clear() {
    state = 0;
  }
}

/// 未読数 Provider
///
/// userProvider を購読し、ログイン復元・ログイン・ログアウトに合わせて自動で取り直す
/// （起動直後はユーザー情報の復元が非同期なので、復元完了を待ってから取得する）
final unreadCountProvider =
    StateNotifierProvider<UnreadCountNotifier, int>((ref) {
  final notifier = UnreadCountNotifier(
    ref.read(getUnreadNotificationCountUseCaseProvider),
  );

  ref.listen<AsyncValue<User?>>(
    userProvider,
    (previous, next) {
      // エラー状態で .value を読むと例外が再スローされるので valueOrNull を使う
      notifier.setUser(next.valueOrNull?.id);
    },
    fireImmediately: true,
  );

  return notifier;
});
