import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/utils/user_utils.dart';
import '../../../shared/utils/navigation_helper.dart';
import '../../providers/user_provider.dart';
import '../../providers/gym_provider.dart';
import '../../pages/favorite_users_page.dart';
import '../../pages/favorited_by_users_page.dart';
import 'user_logo_and_name.dart';
import '../common/button.dart';
import '../this_month_boul_log.dart';

/// ユーザープロフィールセクション
///
/// 役割:
/// - ログイン済みユーザーのプロフィール情報表示
/// - アバター、ユーザー名、自己紹介などの表示
/// - ユーザー統計情報の表示
///
/// クリーンアーキテクチャにおける位置づき:
/// - Presentation層のComponent
/// - ユーザー情報の表示に特化したUI部品
class UserProfileSection extends ConsumerWidget {
  const UserProfileSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userProvider);
    final gymMap = ref.watch(gymMapProvider);

    // エラー状態でも前回のデータがある場合は表示を続ける
    if (userState.hasError && userState.value != null) {
      final user = userState.value;

      // エラーメッセージを表示しつつ、基本的なUIも表示
      return SliverToBoxAdapter(
        child: Column(
          children: [
            // エラー通知バナー
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8.0),
              color: Colors.orange.shade100,
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'プロフィールの一部が更新できませんでした',
                      style: TextStyle(
                          color: Colors.orange.shade800, fontSize: 12),
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        ref.read(userProvider.notifier).refreshUser(),
                    child: const Text('再試行', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
            // 通常のプロフィール表示
            _buildProfileContent(context, user, gymMap),
          ],
        ),
      );
    }

    return userState.when(
      data: (user) => SliverToBoxAdapter(
        child: _buildProfileContent(context, user, gymMap),
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
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                error.toString().contains('プロフィール更新')
                    ? 'プロフィール更新に失敗しました。再度お試しください。'
                    : 'ユーザー情報の読み込みに失敗しました',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // プロフィール更新エラーの場合はユーザー情報を再取得
                  ref.read(userProvider.notifier).refreshUser();
                },
                child: const Text('再試行'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileContent(
      BuildContext context, user, Map<int, dynamic> gymMap) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ユーザ写真・名前欄
          UserLogoAndName(
            userName: user?.userName ?? "名無し",
            userLogo: user?.userIconUrl,
            heroTag: 'login_user_icon',
            userId: user?.id,
          ),
          const SizedBox(height: 16),

          // ボル活（今月の統計）
          if (user?.id != null)
            ThisMonthBoulLog(
              userId: user!.id,
              monthsAgo: 0,
            ),
          const SizedBox(height: 8),

          // お気に入り・お気にいられ欄
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Button(
                onPressedFunction: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FavoriteUsersPage(),
                    ),
                  );
                },
                buttonName: "お気に入り",
                buttonWidth: ((MediaQuery.of(context).size.width) / 2) - 24,
                buttonHeight: 28,
                buttonColorCode: 0xFFE3DCE4,
                buttonTextColorCode: 0xFF000000,
              ),
              Button(
                onPressedFunction: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FavoritedByUsersPage(),
                    ),
                  );
                },
                buttonName: "お気に入られ",
                buttonWidth: ((MediaQuery.of(context).size.width) / 2) - 24,
                buttonHeight: 28,
                buttonColorCode: 0xFFE3DCE4,
                buttonTextColorCode: 0xFF000000,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 自己紹介文
          SizedBox(
            width: double.infinity,
            child: Text(
              user?.userIntroduce?.isNotEmpty == true
                  ? user!.userIntroduce!
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
              user?.favoriteGym?.isNotEmpty == true
                  ? user!.favoriteGym!
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
              // SVGアイコンの代わりにIconを使用（SVGファイルが存在しないため）
              const Icon(Icons.date_range, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              const Text("ボルダリング歴：", style: TextStyle(fontSize: 12)),
              Text(calculateExperience(user?.boulStartDate),
                  style: const TextStyle(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),

          // ホームジム
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // SVGアイコンの代わりにIconを使用
              const Icon(Icons.home, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              const Text("ホームジム：", style: TextStyle(fontSize: 12)),
              Expanded(
                child: GestureDetector(
                  onTap: user?.homeGymId != null && user?.homeGymId != 0
                      ? () {
                          NavigationHelper.toGymDetail(context, user!.homeGymId!);
                        }
                      : null,
                  child: Text(
                    getHomeGymName(user?.homeGymId, gymMap),
                    style: TextStyle(
                      color: (user?.homeGymId != null && user?.homeGymId != 0)
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
    );
  }
}
