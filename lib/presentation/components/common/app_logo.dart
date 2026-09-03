import 'package:flutter/material.dart';
import '../../theme/app_text.dart';

/// アプリのロゴ表示（アイコン＋アプリ名）
///
/// ログイン画面・未ログインのマイページ・空状態などで使用する。
/// アイコンは新アプリアイコン（登攀シルエット）を使用。
/// 背景が岩肌色のためアイコンの暗い地と馴染み、人物が浮かんで見える。
/// アプリ名の書体はホームのロゴ行と同じ AppText.display（Zen Kaku Gothic New）。
/// 以前は RocknRoll One だったが、フォント未同梱＋ランタイム取得無効のため
/// 実機では常に端末標準の書体になっていたので、アプリ全体の書体に統一した。
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
        // アプリ名テキスト（アプリ共通の見出し書体）
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'イワノボリタイ',
            textAlign: TextAlign.center,
            style: AppText.display(size: 28),
          ),
        ),
      ],
    );
  }
}
