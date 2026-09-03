import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/user.dart';
import '../../../shared/utils/user_utils.dart';
import '../../../shared/utils/navigation_helper.dart';
import '../../providers/user_provider.dart';
import '../../providers/gym_provider.dart';
import '../../pages/favorite_users_page.dart';
import '../../pages/favorited_by_users_page.dart';
import 'user_logo_and_name.dart';
import '../common/skeleton_bone.dart';
import '../../theme/app_tokens.dart';
import '../../theme/app_text.dart';
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
    // 注意: エラー状態の AsyncValue に .value でアクセスすると例外が再スローされ、
    // build中の例外＝release版ではグレー一色のエラー画面になる（Riverpod 2.x仕様）。
    // 必ず valueOrNull を使うこと
    if (userState.hasError && userState.valueOrNull != null) {
      final user = userState.valueOrNull;

      // エラーメッセージを表示しつつ、基本的なUIも表示
      return SliverToBoxAdapter(
        child: Column(
          children: [
            // エラー通知バナー
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8.0),
              color: AppColors.wareme,
              child: Row(
                children: [
                  const Icon(Icons.warning, color: AppColors.holdRed, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'プロフィールの一部が更新できませんでした',
                      style: TextStyle(
                          color: AppColors.holdRed, fontSize: 12),
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

    // 読込中（および起動直後のユーザー情報が未着の初期状態 = data(null)）は、
    // セクションをスピナーに差し替えず、取得後と同じレイアウトの骨組みを先に置く。
    // 各項目は取得できた時点でその場所に埋まる（画面が組み変わらない）
    return userState.when(
      data: (user) => SliverToBoxAdapter(
        child: _buildProfileContent(context, user, gymMap),
      ),
      loading: () => SliverToBoxAdapter(
        child: _buildProfileContent(context, null, gymMap),
      ),
      error: (error, stackTrace) => SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: AppColors.holdRed,
              ),
              const SizedBox(height: 16),
              Text(
                error.toString().contains('プロフィール更新')
                    ? 'プロフィール更新に失敗しました。再度お試しください。'
                    : 'ユーザー情報の読み込みに失敗しました',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.sunabokori,
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

  /// プロフィール本体
  ///
  /// [user] が null のときは「ユーザー情報の取得中」として、同じ配置のまま
  /// 文字の入る場所に骨組み（淡い面）を置く。見出し・ボタン・統計カードの枠は
  /// 取得前から確定している内容なので、そのまま表示する
  Widget _buildProfileContent(
      BuildContext context, User? user, Map<int, dynamic> gymMap) {
    final isLoading = user == null;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ユーザ写真・名前欄
          UserLogoAndName(
            userName: user?.userName ?? '',
            userLogo: user?.userIconUrl,
            heroTag: 'login_user_icon',
            userId: user?.id,
            isLoading: isLoading,
          ),
          const SizedBox(height: 16),

          // ボル活（今月の統計）: ユーザーID未確定でも枠だけ先に置く
          ThisMonthBoulLog(
            userId: user?.id,
            monthsAgo: 0,
          ),
          const SizedBox(height: 8),

          // お気に入り・お気にいられ欄
          Row(
            children: [
              Expanded(
                  child: _relationButton(
                      context, 'お気に入り', const FavoriteUsersPage())),
              const SizedBox(width: 10),
              Expanded(
                  child: _relationButton(
                      context, 'お気に入られ', const FavoritedByUsersPage())),
            ],
          ),
          const SizedBox(height: 14),

          // 自己紹介文
          SizedBox(
            width: double.infinity,
            child: isLoading
                ? SkeletonTextBone(style: AppText.body(size: 13), width: 220)
                : Text(
                    user.userIntroduce?.isNotEmpty == true
                        ? user.userIntroduce!
                        : " - ",
                    textAlign: TextAlign.left,
                    softWrap: true,
                    style: AppText.body(size: 13),
                  ),
          ),
          const SizedBox(height: 14),

          // 好きなジム欄
          Text("好きなジム",
              style: AppText.caption(size: 11, weight: FontWeight.w700)),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: isLoading
                ? SkeletonTextBone(style: AppText.body(size: 13), width: 160)
                : Text(
                    user.favoriteGym?.isNotEmpty == true
                        ? user.favoriteGym!
                        : " - ",
                    textAlign: TextAlign.left,
                    softWrap: true,
                    style: AppText.body(size: 13),
                  ),
          ),
          const SizedBox(height: 12),

          // ボル活歴
          Row(
            children: [
              // SVGアイコンの代わりにIconを使用（SVGファイルが存在しないため）
              const Icon(Icons.date_range,
                  size: 15, color: AppColors.sunabokori),
              const SizedBox(width: 8),
              Text("ボルダリング歴", style: AppText.caption(size: 12)),
              const SizedBox(width: 8),
              isLoading
                  ? SkeletonTextBone(
                      style: AppText.body(size: 13, weight: FontWeight.w600),
                      width: 64)
                  : Text(calculateExperience(user.boulStartDate),
                      style: AppText.body(size: 13, weight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),

          // ホームジム
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // SVGアイコンの代わりにIconを使用
              const Icon(Icons.home, size: 15, color: AppColors.sunabokori),
              const SizedBox(width: 8),
              Text("ホームジム", style: AppText.caption(size: 12)),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: user?.homeGymId != null && user?.homeGymId != 0
                      ? () {
                          NavigationHelper.toGymDetail(context, user!.homeGymId!);
                        }
                      : null,
                  child: isLoading
                      ? SkeletonTextBone(
                          style:
                              AppText.body(size: 13, weight: FontWeight.w600),
                          width: 120)
                      : Text(
                          getHomeGymName(user.homeGymId, gymMap),
                          style: AppText.body(
                            size: 13,
                            weight: FontWeight.w600,
                            color: (user.homeGymId != null &&
                                    user.homeGymId != 0)
                                ? AppColors.kabeBlue
                                : AppColors.chalk,
                          ),
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

  /// お気に入り/お気に入られへの遷移ボタン（静かなピル）
  Widget _relationButton(BuildContext context, String label, Widget page) {
    return OutlinedButton(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => page),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.wareme),
        foregroundColor: AppColors.chalk,
        padding: const EdgeInsets.symmetric(vertical: 9),
        shape: const StadiumBorder(),
      ),
      child: Text(label, style: AppText.label(size: 12)),
    );
  }
}
