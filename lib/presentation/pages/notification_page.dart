import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/config/feature_flags.dart';
import '../../shared/utils/navigation_helper.dart';
import '../components/common/app_logo.dart';
import '../components/common/switcher_tab.dart';
import '../components/notification/announcement_row.dart';
import '../components/notification/notification_row.dart';
import '../components/notification/notification_skeleton.dart';
import '../providers/announcements_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/notifications_provider.dart';
import '../providers/unread_count_provider.dart';
import '../providers/user_provider.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import 'login_or_signup_page.dart';

/// 通知ページ（Issue #81）
///
/// 役割:
/// - 上部に「通知｜お知らせ」の 2 タブ（ボル活ページと同じ SwitcherTab）
/// - 当面は FeatureFlags.showAnnouncementsTab = false で「お知らせ」を隠し、通知のみ表示
///   （実装は残す。フラグを true にすれば 2 タブになる）
///
/// クリーンアーキテクチャにおける位置づけ:
/// - Presentation 層の View（タブの枠だけ。中身は各 Section）
class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (!FeatureFlags.showAnnouncementsTab) {
      // 通知のみ。SwitcherTab と同じ高さ・見た目の見出しを置き、フラグ切替で位置が動かないようにする
      return const Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _SingleTabHeader(title: '通知'),
              Expanded(child: NotificationsSection()),
            ],
          ),
        ),
      );
    }

    return const DefaultTabController(
      length: 2,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              SwitcherTab(leftTabName: '通知', rightTabName: 'お知らせ'),
              Expanded(
                child: TabBarView(
                  children: [
                    NotificationsSection(),
                    AnnouncementsSection(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// タブが 1 つだけのときの見出し（SwitcherTab の選択中タブと同じ寸法・下線）
class _SingleTabHeader extends StatelessWidget {
  const _SingleTabHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      color: AppColors.iwa,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(title, style: AppText.heading(size: 16)),
          const SizedBox(height: 10),
          Container(width: 48, height: 3, color: AppColors.kabeBlue),
        ],
      ),
    );
  }
}

/// 「通知」タブの中身
///
/// - 未ログイン: ログイン導線（UnloggedMyPage と同じ様式）
/// - 初回取得中だけ骨組み。以降の更新（引っ張って更新・再表示）は一覧を出したまま
/// - 表示時に既読化（サーバー）→ バッジを消す。手元の未読表示は次の読み直しまで残す
class NotificationsSection extends ConsumerStatefulWidget {
  const NotificationsSection({super.key});

  @override
  ConsumerState<NotificationsSection> createState() =>
      _NotificationsSectionState();
}

class _NotificationsSectionState extends ConsumerState<NotificationsSection> {
  final ScrollController _scrollController = ScrollController();

  /// このページの表示中に既読化を送ったユーザー（二重送信を避ける）
  String? _markedReadFor;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // タブを開くたびに最新化する（タブ切替で本ウィジェットは作り直されるので initState で足りる）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final userId = ref.read(userProvider).valueOrNull?.id;
      if (userId == null) return;
      final notifier = ref.read(notificationsProvider(userId).notifier);
      if (!ref.read(notificationsProvider(userId)).isFirstFetch) {
        notifier.refresh();
      }
      _markRead(userId);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      final userId = ref.read(userProvider).valueOrNull?.id;
      if (userId != null) {
        ref.read(notificationsProvider(userId).notifier).loadMore();
      }
    }
  }

  /// 表示したら既読化（サーバー）し、タブのバッジを消す
  Future<void> _markRead(String userId) async {
    if (_markedReadFor == userId) return;
    _markedReadFor = userId;
    final ok =
        await ref.read(notificationsProvider(userId).notifier).markAllRead();
    if (!mounted) return;
    if (ok) {
      ref.read(unreadCountProvider.notifier).clear();
    } else {
      _markedReadFor = null; // 失敗したら次の表示でまた試す
    }
  }

  Future<void> _refresh(String userId) async {
    await ref.read(notificationsProvider(userId).notifier).refresh();
    if (mounted) ref.read(unreadCountProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = ref.watch(authProvider);
    if (!isLoggedIn) {
      return const _UnloggedNotificationPrompt();
    }

    final userState = ref.watch(userProvider);
    return userState.when(
      data: (user) {
        if (user == null) {
          // ログイン済みだがユーザー情報がまだ来ていない（起動直後）。骨組みで場所を確保
          return const NotificationSkeletonList();
        }
        // ユーザー情報が後から来た場合もここで既読化する
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _markRead(user.id);
        });

        final state = ref.watch(notificationsProvider(user.id));
        final notifications = state.notifications;

        // 初回取得中のみ骨組み（スピナーは出さない）
        if (state.isFirstFetch) {
          return const NotificationSkeletonList();
        }

        // 取得失敗で 1 件も無いときは再読み込み動線
        if (notifications.isEmpty && state.error != null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('読み込みに失敗しました'),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => _refresh(user.id),
                  child: const Text('再読み込み'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => _refresh(user.id),
          child: notifications.isEmpty
              ? ListView(
                  // 件数が無くても引っ張って更新できるようにする
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 96),
                    Icon(Icons.notifications_none,
                        size: 64, color: AppColors.sunabokori),
                    SizedBox(height: 16),
                    Text(
                      '通知はまだありません',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 16, color: AppColors.sunabokori),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'ボル活にいいねやコメントが付くとここに届きます',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13, color: AppColors.sunabokori),
                    ),
                  ],
                )
              : ListView.builder(
                  key: const PageStorageKey<String>('notifications_section'),
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount:
                      notifications.length + (state.hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == notifications.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final n = notifications[index];
                    return NotificationRow(
                      notification: n,
                      onTap: () {
                        final tweetId = n.tweetId;
                        if (tweetId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('この投稿は削除されました')),
                          );
                          return;
                        }
                        NavigationHelper.toTweetDetail(context, tweetId);
                      },
                    );
                  },
                ),
        );
      },
      loading: () => const NotificationSkeletonList(),
      error: (_, __) => const Center(
        child: Text(
          '通知を読み込めませんでした',
          style: TextStyle(color: AppColors.sunabokori),
        ),
      ),
    );
  }
}

/// 未ログイン時の案内（UnloggedMyPage と同じ様式: 節理面のカード＋ロゴ＋ログインボタン）
class _UnloggedNotificationPrompt extends StatelessWidget {
  const _UnloggedNotificationPrompt();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.setsuri,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.wareme),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: AppLogo()),
            const SizedBox(height: 16),
            Text('ログインすると通知が見られます', style: AppText.heading(size: 15)),
            const SizedBox(height: 4),
            Text(
              'あなたのボル活に付いたいいね・コメント・返信がここに届きます．',
              style: AppText.caption(size: 12),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 49,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginOrSignUpPage(),
                    ),
                  );
                },
                child: Text(
                  '新規登録 / ログイン',
                  style: AppText.label(size: 14, color: AppColors.onKabeBlue),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 「お知らせ」タブの中身（当面は FeatureFlags で非表示。実装は維持）
class AnnouncementsSection extends ConsumerStatefulWidget {
  const AnnouncementsSection({super.key});

  @override
  ConsumerState<AnnouncementsSection> createState() =>
      _AnnouncementsSectionState();
}

class _AnnouncementsSectionState extends ConsumerState<AnnouncementsSection> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      ref.read(announcementsProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(announcementsProvider);
    final items = state.announcements;

    if (state.isFirstFetch) {
      return const NotificationSkeletonList();
    }

    if (items.isEmpty && state.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('読み込みに失敗しました'),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => ref.read(announcementsProvider.notifier).refresh(),
              child: const Text('再読み込み'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(announcementsProvider.notifier).refresh(),
      child: items.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 96),
                Icon(Icons.campaign_outlined,
                    size: 64, color: AppColors.sunabokori),
                SizedBox(height: 16),
                Text(
                  'お知らせはまだありません',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: AppColors.sunabokori),
                ),
              ],
            )
          : ListView.builder(
              key: const PageStorageKey<String>('announcements_section'),
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 6),
              itemCount: items.length + (state.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == items.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return AnnouncementRow(announcement: items[index]);
              },
            ),
    );
  }
}
