import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/usecases/notification_usecases.dart';
import 'dependency_injection.dart';

/// お知らせ一覧 状態管理 Provider（Issue #81）
///
/// 役割:
/// - 公式＋本人に関係するジムのお知らせ（新しい順）を保持し、更新・追加読み込みを行う
///
/// autoDispose: お知らせページを離れたら破棄する（毎回読み直してよい）

class AnnouncementsState {
  final List<Announcement> announcements;
  final bool isFirstFetch;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final String? nextCursor;

  const AnnouncementsState({
    required this.announcements,
    required this.isFirstFetch,
    this.isLoadingMore = false,
    required this.hasMore,
    this.error,
    this.nextCursor,
  });

  AnnouncementsState copyWith({
    List<Announcement>? announcements,
    bool? isFirstFetch,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    String? nextCursor,
  }) {
    return AnnouncementsState(
      announcements: announcements ?? this.announcements,
      isFirstFetch: isFirstFetch ?? this.isFirstFetch,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      nextCursor: nextCursor ?? this.nextCursor,
    );
  }
}

class AnnouncementsNotifier extends StateNotifier<AnnouncementsState> {
  final GetAnnouncementsUseCase _getAnnouncements;

  static const int _pageSize = 20;

  bool _isFetching = false;

  AnnouncementsNotifier(this._getAnnouncements)
      : super(const AnnouncementsState(
          announcements: [],
          isFirstFetch: true,
          hasMore: true,
        )) {
    refresh();
  }

  Future<void> refresh() async {
    if (_isFetching) return;
    _isFetching = true;
    try {
      final fetched = await _getAnnouncements.execute(limit: _pageSize);
      if (!mounted) return;
      state = AnnouncementsState(
        announcements: fetched,
        isFirstFetch: false,
        hasMore: fetched.length >= _pageSize,
        nextCursor: fetched.isNotEmpty
            ? fetched.last.publishedAt.toUtc().toIso8601String()
            : null,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isFirstFetch: false, error: 'お知らせの取得に失敗しました');
    } finally {
      _isFetching = false;
    }
  }

  Future<void> loadMore() async {
    if (_isFetching || !state.hasMore || state.isLoadingMore) return;
    _isFetching = true;
    state = state.copyWith(isLoadingMore: true, error: state.error);
    try {
      final fetched = await _getAnnouncements.execute(
        limit: _pageSize,
        cursor: state.nextCursor,
      );
      if (!mounted) return;
      final known = state.announcements.map((a) => a.id).toSet();
      final fresh = fetched.where((a) => !known.contains(a.id)).toList();
      state = state.copyWith(
        announcements: [...state.announcements, ...fresh],
        isLoadingMore: false,
        hasMore: fetched.length >= _pageSize,
        nextCursor: fetched.isNotEmpty
            ? fetched.last.publishedAt.toUtc().toIso8601String()
            : state.nextCursor,
        error: null,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoadingMore: false,
        hasMore: false,
        error: 'お知らせの取得に失敗しました',
      );
    } finally {
      _isFetching = false;
    }
  }
}

/// お知らせ一覧 Provider
final announcementsProvider = StateNotifierProvider.autoDispose<
    AnnouncementsNotifier, AnnouncementsState>((ref) {
  return AnnouncementsNotifier(ref.read(getAnnouncementsUseCaseProvider));
});
