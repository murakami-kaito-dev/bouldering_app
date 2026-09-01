import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../shared/config/environment_config.dart';
import '../../shared/constants/app_routes.dart';
import '../providers/auth_provider.dart';
import '../providers/general_tweets_provider.dart';
import '../providers/gym_provider.dart';
import '../../domain/entities/gym.dart';
import '../providers/terms_acceptance_provider.dart';
import '../theme/app_tokens.dart';
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
import 'splash_page.dart';
import 'block_list_page.dart';
import 'blocked_user_page.dart';

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
    return MaterialApp(
      title: 'ボルダリングアプリ${EnvironmentConfig.appVersionSuffix}',
      theme: _buildTheme(),
      debugShowCheckedModeBanner:
          EnvironmentConfig.isDevelopment, // 開発環境でのみデバッグバナー表示
      // 起動ゲート: スプラッシュ表示とジムデータ先行読込を担う（Issue #21）
      home: const AppRoot(),
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
      AppRoutes.blockList: (context) => const BlockListPage(),
      AppRoutes.blockedUser: (context) => const BlockedUserPage(),
      // Note: Tweet detail uses parameters, so it's handled in navigation helper
    };
  }

  /// アプリケーションテーマ「岩と粉」を構築
  ///
  /// 夜のボルダリングウォールを模したダークテーマ。
  /// 色の定義は app_tokens.dart（AppColors/AppRadius）に集約し、ここでは組むだけ
  ThemeData _buildTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.kabeBlue,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.kabeBlue,
        onPrimary: AppColors.onKabeBlue,
        secondary: AppColors.holdRed,
        surface: AppColors.setsuri,
        onSurface: AppColors.chalk,
        error: AppColors.holdRed,
      ),
      scaffoldBackgroundColor: AppColors.iwa,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.iwa,
        surfaceTintColor: AppColors.iwa,
        foregroundColor: AppColors.chalk,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.kabeBlue,
          foregroundColor: AppColors.onKabeBlue,
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.setsuri,
        hintStyle: const TextStyle(color: AppColors.sunabokori),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          borderSide: const BorderSide(color: AppColors.wareme),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          borderSide: const BorderSide(color: AppColors.wareme),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          borderSide: const BorderSide(color: AppColors.kabeBlue, width: 2),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        color: AppColors.setsuri,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: const BorderSide(color: AppColors.wareme),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.navi,
        selectedItemColor: AppColors.chalk,
        unselectedItemColor: AppColors.sunabokori,
      ),
      dividerColor: AppColors.wareme,
      dialogBackgroundColor: AppColors.setsuri,
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.wareme,
        contentTextStyle: TextStyle(color: AppColors.chalk),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.kabeBlue,
      ),
    );
  }
}

/// 起動ゲート（スプラッシュ）
///
/// 役割:
/// - 起動直後にスプラッシュを表示しつつ、ジム全件データを先行読込する（Issue #21）
/// - 「最低表示時間」かつ「ジム読込完了 or タイムアウト」かつ「規約状態の読込完了」で本体へ
/// - ネットワークで起動をブロックしない設計（タイムアウトで必ず先へ進む。
///   永続キャッシュがあれば読込は通常数百msで完了する）
class AppRoot extends ConsumerStatefulWidget {
  const AppRoot({super.key});

  @override
  ConsumerState<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends ConsumerState<AppRoot> {
  bool _splashDone = false;

  /// スプラッシュ中に読み込んだ「前回選択タブ」。
  /// 本体の初期タブとして渡す（後からsetStateで切り替えるとホームが1フレーム
  /// 見えてチラつくため、最初の描画から前回タブで始める）
  int _initialTab = 0;

  /// スプラッシュの最低表示時間（チラつき防止 + ブランド表示）
  static const Duration _minSplashDuration = Duration(milliseconds: 1000);

  /// ジム読込の待ち上限（オフライン等でもこれ以上は起動を待たせない）
  static const Duration _gymLoadTimeout = Duration(seconds: 4);

  @override
  void initState() {
    super.initState();
    _runStartupSequence();
  }

  Future<void> _runStartupSequence() async {
    // gymListProvider を購読開始＝生成トリガ（コンストラクタが読込を開始する）
    final gymReady = Completer<void>();
    final subscription = ref.listenManual<AsyncValue<List<Gym>>>(
      gymListProvider,
      (previous, next) {
        if ((next.hasValue || next.hasError) && !gymReady.isCompleted) {
          gymReady.complete();
        }
      },
      fireImmediately: true,
    );

    await Future.wait([
      Future.delayed(_minSplashDuration),
      // 読込完了かタイムアウトの早い方。オフラインでも必ず先へ進む
      gymReady.future.timeout(_gymLoadTimeout, onTimeout: () {}),
      _loadLastTab(), // 前回タブの復元もスプラッシュ中に済ませる
    ]);
    subscription.close();

    if (mounted) {
      setState(() => _splashDone = true);
    }
  }

  /// 前回選択タブを読み込む（失敗時はホームのまま）
  Future<void> _loadLastTab() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getInt(ScaffoldWithNavBar.lastTabIndexKey);
      if (saved != null && saved >= 0 && saved < 4 && saved != 2) {
        _initialTab = saved;
      }
    } catch (_) {
      // 復元失敗時はホームタブのまま（起動を妨げない）
    }
  }

  @override
  Widget build(BuildContext context) {
    final termsState = ref.watch(termsAcceptanceProvider);

    if (!_splashDone || termsState.isLoading) {
      return const SplashPage();
    }

    return termsState.hasAccepted
        ? ScaffoldWithNavBar(initialIndex: _initialTab)
        : const TermsAgreementPage();
  }
}

/// ボトムナビゲーション付きのメインスキャフォールド
///
/// アプリライフサイクルを監視してトークン失効を検知
class ScaffoldWithNavBar extends ConsumerStatefulWidget {
  const ScaffoldWithNavBar({super.key, this.initialIndex = 0});

  /// 起動時に表示するタブ（AppRootがスプラッシュ中に前回タブを読み込んで渡す）
  final int initialIndex;

  /// タブ復元用の保存キー（AppRootからも参照）
  static const String lastTabIndexKey = 'last_tab_index';

  @override
  ConsumerState<ScaffoldWithNavBar> createState() => _ScaffoldWithNavBarState();
}

class _ScaffoldWithNavBarState extends ConsumerState<ScaffoldWithNavBar>
    with WidgetsBindingObserver {
  late int _currentIndex = widget.initialIndex;

  final List<Widget> _pages = [
    const HomePage(),
    const BoulLogPage(),
    // 投稿はモーダルシートで開くためタブ本体は使わない（onTapでシートを表示）
    const SizedBox.shrink(),
    const MyPage(),
  ];

  @override
  void initState() {
    super.initState();
    // アプリライフサイクルの監視を開始（トークン失効検知のため）
    WidgetsBinding.instance.addObserver(this);
    debugPrint('[APP LIFECYCLE] ライフサイクル監視開始');

    // 【重要】起動時にログインセッションを復元する。
    // authProvider は生成時に Firebase の保存済みセッションを確認し、
    // ログイン済みなら userProvider へユーザー情報を読み込む（_checkLoginStatus）。
    // ただし Riverpod のプロバイダは「最初に watch/read されるまで生成されない」ため、
    // ここで一度 read して生成しておかないと、マイページを開くまで復元処理が走らず、
    // 投稿ページ等が「未ログイン」表示のままになる不具合があった。
    ref.read(authProvider);
    // 前回選択タブの復元は AppRoot がスプラッシュ中に行い initialIndex で受け取る
    // （ここで非同期に切り替えるとホームが1フレーム見えてチラつくため廃止）
  }

  /// 選択タブを保存する。投稿タブ(index 2)は保存しない
  /// （復帰直後にいきなり投稿フォームが開くのは違和感があり、入力内容は復元できないため）
  Future<void> _saveLastTab(int index) async {
    if (index == 2) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(ScaffoldWithNavBar.lastTabIndexKey, index);
    } catch (_) {
      // 保存失敗は無視（次回はホームタブから始まるだけ）
    }
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

          // オフライン起動などでユーザー情報が未取得のままなら取得し直す
          // （通信回復後にアプリへ戻ってきたタイミングで自己回復させる）
          await ref.read(authProvider.notifier).retryUserLoadIfNeeded();

          // みんなのボル活も、取得失敗で空のままなら取得し直す
          await ref
              .read(generalTweetsProvider.notifier)
              .retryInitialIfFailed();
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
          // 投稿タブはタブ切替ではなくモーダルシートとして開く
          // （×で閉じる明確な動線＝キーボードも確実に閉じられる。
          //   投稿完了時はシートが閉じ、完了したことがユーザーに伝わる）
          if (index == 2) {
            showActivityPostSheet(context);
            return;
          }
          setState(() {
            _currentIndex = index;
          });
          _saveLastTab(index); // fire-and-forget（UIを待たせない）
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
            // 登攀グリフ（Noun Project由来・単色）。選択で壁ブルー、非選択で砂埃
            icon: SvgPicture.asset(
              'lib/view/assets/climber_nav.svg',
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                _currentIndex == 3 ? AppColors.kabeBlue : AppColors.sunabokori,
                BlendMode.srcIn,
              ),
            ),
            label: 'マイページ',
          ),
        ],
        selectedItemColor: AppColors.kabeBlue,
        unselectedItemColor: AppColors.sunabokori,
        selectedLabelStyle: const TextStyle(fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
      ),
    );
  }
}
