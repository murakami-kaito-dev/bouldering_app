import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../components/user/user_profile_section.dart';
import '../components/my_tweets_section.dart';
import '../components/favorite_gyms_section.dart';
import 'settings_page.dart';

/// ログイン時のマイページ
///
/// 役割:
/// - ログイン済みユーザーのマイページ表示
/// - ユーザープロフィール表示
/// - ボル活・イキタイタブの表示
/// - 設定画面への遷移
///
/// クリーンアーキテクチャにおける位置づけ:
/// - Presentation層のView
/// - ログイン状態でのみ表示される画面
class LoggedInMyPage extends ConsumerWidget {
  const LoggedInMyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFFEF7FF),
        appBar: AppBar(
          // 【必須】戻るボタンを非表示
          automaticallyImplyLeading: false,
          backgroundColor: const Color(0xFFFEF7FF),
          surfaceTintColor: const Color(0xFFFEF7FF),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: IconButton(
                icon:
                    const Icon(Icons.settings, size: 32.0, color: Colors.grey),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsPage(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: NestedScrollView(
            headerSliverBuilder:
                (BuildContext context, bool innerBoxIsScrolled) {
              return [
                // ユーザープロフィールセクション
                const UserProfileSection(),

                // ボル活・イキタイタブ
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverAppBarDelegate(
                    const TabBar(
                      tabs: [
                        Tab(text: "ボル活"),
                        Tab(text: "イキタイ"),
                      ],
                      labelStyle: TextStyle(
                        color: Color(0xFF0056FF),
                        fontSize: 20,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w900,
                        height: 1.4,
                        letterSpacing: -0.50,
                      ),
                    ),
                  ),
                ),
              ];
            },
            // タブの中に表示する画面
            body: const TabBarView(
              children: [
                // ボル活タブ：自分のツイート一覧
                MyTweetsSection(),
                // イキタイタブ：お気に入りジム一覧
                FavoriteGymsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// TabBar用のSliverPersistentHeaderDelegate
///
/// 役割:
/// - TabBarを固定ヘッダーとして表示するためのデリゲート
/// - NestedScrollViewでのTabBar表示に必要
///
/// このページでのみ使用されるため、同一ファイル内に配置
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFFFEF7FF),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
