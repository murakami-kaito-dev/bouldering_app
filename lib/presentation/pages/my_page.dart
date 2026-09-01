import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import 'unlogged_my_page.dart';
import 'logged_in_my_page.dart';

/// マイページ
///
/// 役割:
/// - 認証状態に応じたマイページの表示制御
/// - 未ログイン時: UnloggedMyPageを表示
/// - ログイン時: LoggedMyPageを表示（今後実装）
///
/// クリーンアーキテクチャにおける位置づけ:
/// - Presentation層のView
/// - 認証状態を監視して適切なページを表示
/// - 単一責任の原則に従った認証ゲート
class MyPage extends ConsumerWidget {
  const MyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(authProvider);
    final userState = ref.watch(userProvider);

    if (!isAuthenticated) {
      // 未ログイン時のマイページ
      return const UnloggedMyPage();
    }

    // Firebase上はログイン済みだがユーザー情報の取得に失敗している場合
    // （機内モード起動など）。壊れたマイページを出さず、再読み込み動線を表示する
    if (userState.hasError) {
      return Scaffold(
        backgroundColor: const Color(0xFFFEF7FF),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('ユーザー情報を取得できませんでした'),
              const SizedBox(height: 4),
              const Text(
                '通信環境を確認してください',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () =>
                    ref.read(authProvider.notifier).retryUserLoadIfNeeded(),
                child: const Text('再読み込み'),
              ),
            ],
          ),
        ),
      );
    }

    if (userState.valueOrNull == null) {
      // ユーザー情報の読み込み中（起動直後・再読み込み中）
      return const Scaffold(
        backgroundColor: Color(0xFFFEF7FF),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // ログイン済みマイページ
    return const LoggedInMyPage();
  }
}
