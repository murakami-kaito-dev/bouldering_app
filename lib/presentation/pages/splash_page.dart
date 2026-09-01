import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';

/// スプラッシュ画面
///
/// 役割:
/// - 起動ゲート（app.dart の AppRoot）から表示される
/// - この画面が出ている裏でジム全件データの先行読込が行われる（Issue #21）
/// - iOSのLaunchScreenから違和感なく繋がる、静的で軽い画面に保つこと
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.iwa,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Image.asset(
                'assets/icon.png',
                width: 120,
                height: 120,
              ),
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.kabeBlue),
            ),
          ],
        ),
      ),
    );
  }
}
