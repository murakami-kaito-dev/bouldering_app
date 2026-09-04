import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/user.dart';
import '../../../shared/utils/user_utils.dart';
import '../../../shared/utils/navigation_helper.dart';
import '../../providers/other_user_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/gym_provider.dart';
import '../../providers/favorite_user_provider.dart';
import 'user_logo_and_name.dart';
import '../common/skeleton_bone.dart';
import '../common/button.dart';
import '../this_month_boul_log.dart';
import '../../theme/app_tokens.dart';
import '../../theme/app_text.dart';

/// 他ユーザープロフィールセクション
///
/// 役割:
/// - 他のユーザーのプロフィール情報表示
/// - お気に入り登録・解除機能
/// - ユーザー統計情報の表示
/// - ユーザー情報の取得中は、同じ配置のまま文字の場所に骨組みを置く
///   （セクションをスピナーに差し替えない。マイページと同じ扱い）
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
        child: _buildContent(context, currentUserState, gymMap,
            user: otherUser, isLoading: false),
      ),
      // 読込中はスピナーに差し替えず、取得後と同じ配置の骨組みを先に置く
      loading: () => SliverToBoxAdapter(
        child: _buildContent(context, currentUserState, gymMap,
            user: null, isLoading: true),
      ),
      error: (error, stackTrace) => _buildError(context, error),
    );
  }

  /// プロフィール本体
  ///
  /// [isLoading] のときは文字の入る場所に骨組み（淡い面）を置く。
  /// 統計カード・お気に入りボタン・見出しは取得前から確定している内容なのでそのまま出す
  /// （統計は widget.userId で取れるので、プロフィールの到着を待たない）
  Widget _buildContent(
    BuildContext context,
    AsyncValue<User?> currentUserState,
    Map<int, dynamic> gymMap, {
    required User? user,
    required bool isLoading,
  }) {
    final otherUser = user;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ユーザ写真・名前欄
          UserLogoAndName(
            userName: otherUser?.userName ?? (isLoading ? '' : "名無し"),
            userLogo: otherUser?.userIconUrl,
            heroTag: 'other_user_icon_${widget.userId}',
            userId: otherUser?.id,
            isLoading: isLoading,
          ),
          const SizedBox(height: 16),

          // ボル活（今月の統計）: 対象IDは確定しているので取得中も枠ごと先に出す
          ThisMonthBoulLog(
            userId: widget.userId,
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
                    buttonColorCode: isFavorite ? 0xFF5B8CFF : 0xFF2D313A,
                    buttonTextColorCode: isFavorite ? 0xFF0C1A3A : 0xFFF2F0EA,
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
            child: isLoading
                ? SkeletonTextBone(
                    style: AppText.body(size: 13, height: 1.5), width: 220)
                : Text(
                    otherUser?.userIntroduce?.isNotEmpty == true
                        ? otherUser!.userIntroduce!
                        : " - ",
                    textAlign: TextAlign.left,
                    softWrap: true,
                    overflow: TextOverflow.visible,
                    maxLines: null,
                    style: AppText.body(size: 13, height: 1.5),
                  ),
          ),
          const SizedBox(height: 12),

          // 好きなジム欄
          Text(
            "好きなジム",
            style: AppText.caption(size: 11, weight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: isLoading
                ? SkeletonTextBone(
                    style: AppText.body(size: 13, height: 1.5), width: 160)
                : Text(
                    otherUser?.favoriteGym?.isNotEmpty == true
                        ? otherUser!.favoriteGym!
                        : " - ",
                    textAlign: TextAlign.left,
                    softWrap: true,
                    overflow: TextOverflow.visible,
                    maxLines: null,
                    style: AppText.body(size: 13, height: 1.5),
                  ),
          ),
          const SizedBox(height: 8),

          // ボル活歴
          Row(
            children: [
              _leadingIcon(Icons.date_range),
              const SizedBox(width: 8),
              Text("ボルダリング歴：", style: AppText.caption(size: 12)),
              isLoading
                  ? SkeletonTextBone(style: AppText.body(size: 12), width: 56)
                  : Text(
                      calculateExperience(otherUser?.boulStartDate),
                      style: AppText.body(size: 12),
                    ),
            ],
          ),
          const SizedBox(height: 8),

          // ホームジム（値は複数行になりうるので上揃え。アイコン・見出しは
          // 値の1行ぶんの高さの箱で中央に置き、1行目と縦を揃える）
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _firstLineBox(_homeGymValueStyle, _leadingIcon(Icons.home)),
              const SizedBox(width: 8),
              _firstLineBox(
                _homeGymValueStyle,
                Text("ホームジム：", style: AppText.caption(size: 12)),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: otherUser?.homeGymId != null
                      ? () {
                          NavigationHelper.toGymDetail(
                              context, otherUser!.homeGymId!);
                        }
                      : null,
                  child: isLoading
                      ? SkeletonTextBone(style: _homeGymValueStyle, width: 120)
                      : Text(
                          getHomeGymName(otherUser?.homeGymId, gymMap),
                          style: _homeGymValueStyle.copyWith(
                            color: otherUser?.homeGymId != null
                                ? AppColors.kabeBlue
                                : AppColors.chalk,
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

  /// ホームジム名の書体（行高の基準にもなるので1箇所で定義）
  static final TextStyle _homeGymValueStyle = AppText.body(size: 12);

  /// 行頭のアイコン（見出し文字と光学的に揃える。理由は user_profile_section と同じ）
  static Widget _leadingIcon(IconData icon) => Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Icon(icon, size: 16, color: AppColors.sunabokori),
      );

  /// [valueStyle] の1行ぶんの高さの箱に [child] を中央配置する（本文の1行目と縦揃え）
  static Widget _firstLineBox(TextStyle valueStyle, Widget child) => SizedBox(
        height: valueStyle.fontSize! * (valueStyle.height ?? 1.0),
        child: Center(child: child),
      );

  /// 取得失敗（退会済み・通信エラー）
  Widget _buildError(BuildContext context, Object error) {
    return SliverToBoxAdapter(
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
                  ? AppColors.sunabokori
                  : AppColors.holdRed,
            ),
            const SizedBox(height: 20),
            Text(
              error.toString().contains('USER_WITHDRAWN')
                  ? 'このユーザーページを取得することができませんでした'
                  : 'ユーザー情報の読み込みに失敗しました',
              style: AppText.heading(size: 15, color: AppColors.sunabokori),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString().contains('USER_WITHDRAWN')
                  ? '退会した可能性があります'
                  : '通信エラーが発生しました',
              style: AppText.caption(size: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                '戻る',
                style: AppText.body(size: 14, color: AppColors.kabeBlue),
              ),
            ),
          ],
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
