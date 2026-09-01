import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_tokens.dart';

/// アプリのロゴ表示（アイコン＋アプリ名）
///
/// ログイン画面・未ログインのマイページ・空状態などで使用する。
/// アイコンは新アプリアイコン（登攀シルエット）を使用。
/// 背景が岩肌色のためアイコンの暗い地と馴染み、人物が浮かんで見える。
class AppLogo extends StatelessWidget {
  const AppLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // アプリアイコン（角丸で表示。原寸1024pxを表示サイズ相当に縮小デコード）
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Image.asset(
            'assets/icon.png',
            width: 112,
            height: 112,
            cacheWidth: 336,
          ),
        ),
        const SizedBox(height: 12),
        // アプリ名テキスト
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'イワノボリタイ',
            textAlign: TextAlign.center,
            style: GoogleFonts.rocknRollOne(
              color: AppColors.chalk,
              fontSize: 28,
              fontWeight: FontWeight.w400,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ],
    );
  }
}
