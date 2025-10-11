import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/utils/user_utils.dart';
import '../../../shared/utils/navigation_helper.dart';
import '../../providers/other_user_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/gym_provider.dart';
import '../../providers/favorite_user_provider.dart';
import 'user_logo_and_name.dart';
import '../common/button.dart';
import '../this_month_boul_log.dart';

/// 他ユーザープロフィールセクション
///
/// 役割:
/// - 他のユーザーのプロフィール情報表示
/// - お気に入り登録・解除機能
/// - ユーザー統計情報の表示
///
/// クリーンアーキテクチャにおける位置づき:
/// - Presentation層のComponent
/// - 他ユーザー情報の表示に特化したUI部品
class OtherUserProfileSection extends ConsumerStatefulWidget {
  final String userId;

  const OtherUserProfileSection({
    super.key,
    required this.userId,
  });

  @override
  ConsumerState<OtherUserProfileSection> createState() =>
      _OtherUserProfileSectionState();
}

class _OtherUserProfileSectionState
    extends ConsumerState<OtherUserProfileSection> {
  @override
  void initState() {
    super.initState();
    // お気に入りユーザーリストを初期化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser != null) {
        ref
            .read(favoriteUserProvider.notifier)
            .loadFavoriteUsers(currentUser.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final otherUserState = ref.watch(otherUserProvider(widget.userId));
    final currentUserState = ref.watch(userProvider);
    final gymMap = ref.watch(gymMapProvider);

    return otherUserState.when(
      data: (otherUser) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ユーザ写真・名前欄
              UserLogoAndName(
                userName: otherUser?.userName ?? "名無し",
                userLogo: otherUser?.userIconUrl,
                heroTag: 'other_user_icon_${widget.userId}',
                userId: otherUser?.id,
              ),
              const SizedBox(height: 16),

              // ボル活（今月の統計）
              if (otherUser?.id != null)
                ThisMonthBoulLog(
                  userId: otherUser!.id,
                  monthsAgo: 0,
                ),
              const SizedBox(height: 8),

              // お気に入り登録ボタン（ログイン済みユーザーのみ表示）
              currentUserState.when(
                data: (currentUser) {
                  if (currentUser == null || currentUser.id == widget.userId) {
                    return const SizedBox.shrink();
                  }

                  final isFavorite =
                      ref.watch(isFavoriteUserProvider(widget.userId));

                  return Column(
                    children: [
                      Button(
                        onPressedFunction: () =>
                            _toggleFavorite(ref, currentUser.id),
                        buttonName: isFavorite ? "お気に入り登録解除" : "お気に入り登録",
                        buttonWidth: MediaQuery.of(context).size.width - 32,
                        buttonHeight: 36,
                        buttonColorCode: isFavorite ? 0xFF0056FF : 0xFFE3DCE4,
                        buttonTextColorCode:
                            isFavorite ? 0xFFFFFFFF : 0xFF000000,
                      ),
                      const SizedBox(height: 8),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              // 自己紹介文
              SizedBox(
                width: double.infinity,
                child: Text(
                  otherUser?.userIntroduce?.isNotEmpty == true
                      ? otherUser!.userIntroduce!
                      : " - ",
                  textAlign: TextAlign.left,
                  softWrap: true,
                  overflow: TextOverflow.visible,
                  maxLines: null,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                    letterSpacing: -0.50,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 好きなジム欄
              const Text(
                "好きなジム",
                style: TextStyle(
                  color: Color(0xFF8D8D8D),
                  fontSize: 12,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.bold,
                  height: 1.4,
                  letterSpacing: -0.50,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: Text(
                  otherUser?.favoriteGym?.isNotEmpty == true
                      ? otherUser!.favoriteGym!
                      : " - ",
                  textAlign: TextAlign.left,
                  softWrap: true,
                  overflow: TextOverflow.visible,
                  maxLines: null,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                    letterSpacing: -0.50,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // ボル活歴
              Row(
                children: [
                  const Icon(Icons.date_range, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  const Text("ボルダリング歴：", style: TextStyle(fontSize: 12)),
                  Text(
                    calculateExperience(otherUser?.boulStartDate),
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // ホームジム
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.home, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  const Text("ホームジム：", style: TextStyle(fontSize: 12)),
                  Expanded(
                    child: GestureDetector(
                      onTap: otherUser?.homeGymId != null
                          ? () {
                              NavigationHelper.toGymDetail(
                                  context, otherUser!.homeGymId!);
                            }
                          : null,
                      child: Text(
                        getHomeGymName(otherUser?.homeGymId, gymMap),
                        style: TextStyle(
                          color: otherUser?.homeGymId != null
                              ? Colors.blue
                              : Colors.black,
                          fontSize: 12,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.visible,
                        softWrap: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      loading: () => const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      error: (error, stackTrace) => SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                error.toString().contains('USER_WITHDRAWN')
                    ? Icons.person_off
                    : Icons.error_outline,
                size: 64,
                color: error.toString().contains('USER_WITHDRAWN')
                    ? Colors.grey[400]
                    : Colors.red[400],
              ),
              const SizedBox(height: 20),
              Text(
                error.toString().contains('USER_WITHDRAWN')
                    ? 'このユーザーページを取得することができませんでした'
                    : 'ユーザー情報の読み込みに失敗しました',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString().contains('USER_WITHDRAWN')
                    ? '退会した可能性があります'
                    : '通信エラーが発生しました',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text(
                  '戻る',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF0056FF),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleFavorite(WidgetRef ref, String currentUserId) async {
    // お気に入り状態を確認
    final isFavorite = ref.read(isFavoriteUserProvider(widget.userId));
    final favoriteUserNotifier = ref.read(favoriteUserProvider.notifier);

    try {
      bool success;
      if (isFavorite) {
        // お気に入り解除
        success = await favoriteUserNotifier.removeFavoriteUser(widget.userId);
        if (!ref.context.mounted) return;

        if (success) {
          ScaffoldMessenger.of(ref.context).showSnackBar(
            const SnackBar(content: Text('お気に入りを解除しました')),
          );
        } else {
          ScaffoldMessenger.of(ref.context).showSnackBar(
            const SnackBar(content: Text('お気に入り解除に失敗しました')),
          );
        }
      } else {
        // お気に入り登録
        success = await favoriteUserNotifier.addFavoriteUser(widget.userId);
        if (!ref.context.mounted) return;

        if (success) {
          ScaffoldMessenger.of(ref.context).showSnackBar(
            const SnackBar(content: Text('お気に入りに登録しました')),
          );
        } else {
          ScaffoldMessenger.of(ref.context).showSnackBar(
            const SnackBar(content: Text('お気に入り登録に失敗しました')),
          );
        }
      }
    } catch (e) {
      if (!ref.context.mounted) return;
      ScaffoldMessenger.of(ref.context).showSnackBar(
        SnackBar(content: Text('エラーが発生しました: $e')),
      );
    }
  }
}
