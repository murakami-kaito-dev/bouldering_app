import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../shared/config/environment_config.dart';
import '../../shared/constants/app_routes.dart';
import '../providers/auth_provider.dart';
import '../providers/terms_acceptance_provider.dart';
import 'home_page.dart';
import 'gym_detail_page.dart';
import 'gym_search_page.dart';
import 'gym_map_page.dart';
import 'activity_post_page.dart';
import 'profile_edit_page.dart';
import 'settings_page.dart';
import 'favorite_users_page.dart';
import 'boul_log_page.dart';
import 'my_page.dart';
import 'other_user_profile_page.dart';
import 'terms_agreement_page.dart';

/// メインアプリケーションクラス
///
/// 役割:
/// - アプリケーション全体の設定
/// - テーマ・ルーティングの管理
/// - 認証状態に基づく画面切り替え
///
/// クリーンアーキテクチャにおける位置づけ:
/// - Presentation層のルートコンポーネント
/// - 認証状態を監視してUI切り替えを行う
class BoulderingApp extends ConsumerWidget {
  const BoulderingApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final termsState = ref.watch(termsAcceptanceProvider);

    return MaterialApp(
      title: 'ボルダリングアプリ${EnvironmentConfig.appVersionSuffix}',
      theme: _buildTheme(),
      debugShowCheckedModeBanner:
          EnvironmentConfig.isDevelopment, // 開発環境でのみデバッグバナー表示
      home: termsState.isLoading
          ? const Scaffold(
              backgroundColor: Color(0xFFFEF7FF),
              body: Center(child: CircularProgressIndicator()),
            )
          : termsState.hasAccepted
              ? const ScaffoldWithNavBar()
              : const TermsAgreementPage(),
      routes: _buildRoutes(),
    );
  }

  /// アプリケーションのルート定義
  Map<String, WidgetBuilder> _buildRoutes() {
    return {
      AppRoutes.home: (context) => const HomePage(),
      AppRoutes.gymDetail: (context) {
        final args = ModalRoute.of(context)!.settings.arguments as Map?;
        final gymId = args?[RouteParams.gymId];
        final gymIdString =
            gymId is int ? gymId.toString() : (gymId as String? ?? '');
        return GymDetailPage(gymId: gymIdString);
      },
      AppRoutes.gymSearch: (context) => const GymSearchPage(),
      AppRoutes.gymMap: (context) => const GymMapPage(),
      AppRoutes.tweetPost: (context) {
        final args = ModalRoute.of(context)!.settings.arguments as Map?;
        final preSelectedGymId = args?[RouteParams.preSelectedGymId] as int?;
        return ActivityPostPage(
          preSelectedGymId: preSelectedGymId,
          fromGymDetail: true, // ルート経由での遷移なので戻るボタンを表示
        );
      },
      AppRoutes.editProfile: (context) => const ProfileEditPage(),
      AppRoutes.settings: (context) => const SettingsPage(),
      AppRoutes.favoriteUsers: (context) => const FavoriteUsersPage(),
      AppRoutes.otherUserProfile: (context) {
        final args = ModalRoute.of(context)!.settings.arguments as Map?;
        final userId = args?[RouteParams.userId] as String?;
        return OtherUserProfilePage(userId: userId ?? '');
      },
      // Note: Tweet detail uses parameters, so it's handled in navigation helper
    };
  }

  /// アプリケーションテーマを構築
  ///
  /// 以前のアプリと同じ青系の配色を設定
  ThemeData _buildTheme() {
    return ThemeData(
      primarySwatch: Colors.blue,
      primaryColor: const Color(0xFF0056FF), // 以前のアプリと同じ青色
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0056FF),
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0056FF),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0056FF),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: Color(0xFF0056FF),
            width: 2,
          ),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      // scaffoldBackgroundColor: Colors.white,
      scaffoldBackgroundColor: const Color(0xFFFEF7FF),
    );
  }
}

/// ボトムナビゲーション付きのメインスキャフォールド
///
/// アプリライフサイクルを監視してトークン失効を検知
class ScaffoldWithNavBar extends ConsumerStatefulWidget {
  const ScaffoldWithNavBar({super.key});

  @override
  ConsumerState<ScaffoldWithNavBar> createState() => _ScaffoldWithNavBarState();
}

class _ScaffoldWithNavBarState extends ConsumerState<ScaffoldWithNavBar>
    with WidgetsBindingObserver {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const BoulLogPage(),
    const ActivityPostPage(),
    const MyPage(),
  ];

  @override
  void initState() {
    super.initState();
    // アプリライフサイクルの監視を開始（トークン失効検知のため）
    WidgetsBinding.instance.addObserver(this);
    debugPrint('[APP LIFECYCLE] ライフサイクル監視開始');
  }

  @override
  void dispose() {
    // アプリライフサイクルの監視を終了（リソースクリーンアップ）
    WidgetsBinding.instance.removeObserver(this);
    debugPrint('[APP LIFECYCLE] ライフサイクル監視終了');
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // アプリのライフサイクル状態変更をログ出力（開発時のデバッグ用）
    debugPrint('[APP LIFECYCLE] 状態変更: $state');

    // アプリがバックグラウンドから前面に復帰した時の処理
    if (state == AppLifecycleState.resumed) {
      debugPrint('[APP LIFECYCLE] アプリ復帰検知 - トークン失効チェック開始');

      // Firebase認証トークンの失効チェックを非同期で実行
      // バックグラウンド中にトークンが失効した場合の対応
      Future.microtask(() async {
        try {
          await ref.read(authProvider.notifier).checkAuthRevoked();
          debugPrint('[APP LIFECYCLE] トークン失効チェック完了');
        } catch (e) {
          debugPrint('[APP LIFECYCLE ERROR] トークン失効チェックエラー: $e');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'ホーム',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.library_books),
            label: 'ボル活',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.add_box),
            label: '投稿',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              _currentIndex == 3
                  ? 'lib/view/assets/rock_selected.svg'
                  : 'lib/view/assets/rock_unselected.svg',
              width: 24,
              height: 24,
            ),
            label: 'マイページ',
          ),
        ],
        selectedItemColor: const Color(0xFF0056FF),
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
      ),
    );
  }
}
