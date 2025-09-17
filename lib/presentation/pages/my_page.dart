import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
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

    if (isAuthenticated) {
      // ログイン済みマイページ
      return const LoggedInMyPage();
    } else {
      // 未ログイン時のマイページ
      return const UnloggedMyPage();
    }
  }
}
