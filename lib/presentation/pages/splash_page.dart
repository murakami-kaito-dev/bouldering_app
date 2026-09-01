import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';

/// スプラッシュ画面
///
/// 役割:
/// - 起動ゲート（app.dart の AppRoot）から表示される
/// - この画面が出ている裏でジム全件データの先行読込が行われる（Issue #21）
/// - iOSのLaunchScreenから違和感なく繋がる、静的で軽い画面に保つこと
///
/// 見た目: 専用スプラッシュ画像（登攀シルエット・岩壁）を全画面に敷き、
/// 下端に控えめなローディングを重ねる。画像に世界観が入っているため文字は載せない。
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.iwa,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 専用スプラッシュ画像（画面いっぱい。上下は画像側のビネットで自然に暗く落ちる）
          Image.asset(
            'assets/splash.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
          // 下端の控えめなローディング
          const Align(
            alignment: Alignment(0, 0.82),
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.kabeBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
