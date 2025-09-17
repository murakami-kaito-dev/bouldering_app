import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../components/user/other_user_profile_section.dart';
import '../components/user/other_user_tweets_section.dart';
import '../components/user/other_user_favorite_gyms_section.dart';

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
        backgroundColor: const Color(0xFFFEF7FF),
        appBar: AppBar(
          backgroundColor: const Color(0xFFFEF7FF),
          surfaceTintColor: const Color(0xFFFEF7FF),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
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
                      color: const Color(0xFFFEF7FF),
                      child: const TabBar(
                        tabs: [
                          Tab(text: 'ボル活'),
                          Tab(text: 'イキタイ'),
                        ],
                        labelStyle: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        labelColor: Color(0xFF0056FF),
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: Color(0xFF0056FF),
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
