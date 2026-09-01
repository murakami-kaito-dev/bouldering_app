import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../components/user/other_user_profile_section.dart';
import '../components/user/other_user_tweets_section.dart';
import '../components/user/other_user_favorite_gyms_section.dart';
import '../theme/app_tokens.dart';

/// 他ユーザープロフィールページ
///
/// 役割:
/// - 他のユーザーのプロフィール情報表示
/// - そのユーザーの投稿一覧表示
/// - イキタイジム一覧表示
///
/// クリーンアーキテクチャにおける位置づき:
/// - Presentation層のPage
/// - 他ユーザー情報の統合表示ページ
class OtherUserProfilePage extends ConsumerWidget {
  final String userId;

  const OtherUserProfilePage({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.iwa,
        appBar: AppBar(
          backgroundColor: AppColors.iwa,
          surfaceTintColor: AppColors.iwa,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.chalk),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SafeArea(
          child: NestedScrollView(
            headerSliverBuilder:
                (BuildContext context, bool innerBoxIsScrolled) {
              return [
                // ユーザープロフィールセクション
                OtherUserProfileSection(userId: userId),

                // タブバー
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverAppBarDelegate(
                    Container(
                      color: AppColors.iwa,
                      child: const TabBar(
                        tabs: [
                          Tab(text: 'ボル活'),
                          Tab(text: 'イキタイ'),
                        ],
                        labelStyle: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        labelColor: AppColors.kabeBlue,
                        unselectedLabelColor: AppColors.sunabokori,
                        indicatorColor: AppColors.kabeBlue,
                      ),
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              children: [
                // ボル活タブ
                OtherUserTweetsSection(userId: userId),
                // イキタイタブ
                OtherUserFavoriteGymsSection(userId: userId),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// タブバーをStickyにするためのDelegate
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _SliverAppBarDelegate(this.child);

  @override
  double get minExtent => 48.0;

  @override
  double get maxExtent => 48.0;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return child != oldDelegate.child;
  }
}
