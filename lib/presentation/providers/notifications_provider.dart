import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/usecases/notification_usecases.dart';
import 'dependency_injection.dart';

/// 通知一覧 状態管理 Provider（Issue #81）
///
/// 役割:
/// - 本人の通知一覧（新しい順・いいねは集約済み）を保持し、更新・追加読み込みを行う
/// - 既読化はサーバーへ送るだけで、手元の行の未読表示は次の読み直しまで残す
///   （「どれが新着だったか」を画面に残すため）
///
/// クリーンアーキテクチャにおける位置づけ:
/// - Presentation 層の状態管理
/// - Domain 層の通知 UseCase を呼び出す
///
/// family(userId): ログアウト→別アカウントでログインしても一覧が混ざらないようにする

class NotificationsState {
  final List<AppNotification> notifications;

  /// 初回取得中か（この間だけ骨組みを出す。以降の更新は一覧を出したまま行う）
  final bool isFirstFetch;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final String? nextCursor;

  const NotificationsState({
    required this.notifications,
    required this.isFirstFetch,
    this.isLoadingMore = false,
    required this.hasMore,
    this.error,
    this.nextCursor,
  });

  NotificationsState copyWith({
    List<AppNotification>? notifications,
    bool? isFirstFetch,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    String? nextCursor,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      isFirstFetch: isFirstFetch ?? this.isFirstFetch,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      nextCursor: nextCursor ?? this.nextCursor,
    );
  }
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final String userId;
  final GetNotificationsUseCase _getNotifications;
  final MarkNotificationsReadUseCase _markRead;

  static const int _pageSize = 30;

  bool _isFetching = false;

  NotificationsNotifier(
    this.userId,
    this._getNotifications,
    this._markRead,
  ) : super(const NotificationsState(
          notifications: [],
          isFirstFetch: true,
          hasMore: true,
        )) {
    refresh();
  }

  /// 先頭から読み直す（初回・引っ張って更新・タブ再表示）
  Future<void> refresh() async {
    if (_isFetching) return;
    _isFetching = true;
    try {
      final fetched = await _getNotifications.execute(userId, limit: _pageSize);
      if (!mounted) return;
      state = NotificationsState(
        notifications: fetched,
        isFirstFetch: false,
        hasMore: fetched.length >= _pageSize,
        nextCursor: fetched.isNotEmpty
            ? fetched.last.createdAt.toUtc().toIso8601String()
            : null,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isFirstFetch: false,
        error: '通知の取得に失敗しました',
      );
    } finally {
      _isFetching = false;
    }
  }

  /// 次ページを末尾に足す
  Future<void> loadMore() async {
    if (_isFetching || !state.hasMore || state.isLoadingMore) return;
    _isFetching = true;
    state = state.copyWith(isLoadingMore: true, error: state.error);
    try {
      final fetched = await _getNotifications.execute(
        userId,
        limit: _pageSize,
        cursor: state.nextCursor,
      );
      if (!mounted) return;

      // 集約行の代表 ID は次ページで再登場しないが、念のため重複は除く
      final known = state.notifications.map((n) => n.id).toSet();
      final fresh = fetched.where((n) => !known.contains(n.id)).toList();

      state = state.copyWith(
        notifications: [...state.notifications, ...fresh],
        isLoadingMore: false,
        hasMore: fetched.length >= _pageSize,
        nextCursor: fetched.isNotEmpty
            ? fetched.last.createdAt.toUtc().toIso8601String()
            : state.nextCursor,
        error: null,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoadingMore: false,
        hasMore: false,
        error: '通知の取得に失敗しました',
      );
    } finally {
      _isFetching = false;
    }
  }

  /// 全既読にする（サーバーのみ。手元の未読表示は次の refresh まで残す）
  ///
  /// 失敗しても画面は止めない（次回表示時にまた試す）
  Future<bool> markAllRead() async {
    try {
      await _markRead.execute(userId);
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// 通知一覧 Provider（ユーザーIDごと）
final notificationsProvider = StateNotifierProvider.family<NotificationsNotifier,
    NotificationsState, String>((ref, userId) {
  return NotificationsNotifier(
    userId,
    ref.read(getNotificationsUseCaseProvider),
    ref.read(markNotificationsReadUseCaseProvider),
  );
});
