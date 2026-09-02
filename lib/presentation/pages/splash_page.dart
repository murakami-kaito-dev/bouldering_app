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
///
/// 起動時のチラつき対策:
/// iOS の LaunchScreen（同じ画像）から Flutter の最初のフレームへ切り替わる瞬間、
/// `assets/splash.png` のデコードが間に合っていないと「画像なし＋スピナーだけ」の
/// フレームが1〜数フレーム出て、暗く点滅して見える。これを防ぐため、
/// 画像をメモリに展開し終えるまで Flutter の最初のフレーム送出を保留する
/// （保留中は iOS 側が LaunchScreen を出し続けるので、見た目は繋がったままになる）。
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  static const _splashImage = AssetImage('assets/splash.png');

  /// 最初のフレーム保留を解除したか（アプリの生存期間で一度だけ）
  static bool _firstFrameReleased = false;

  /// この State が保留を掛けたか（掛けた側が必ず解除する）
  bool _holdingFirstFrame = false;

  @override
  void initState() {
    super.initState();
    // まだ最初のフレームを出していない起動直後だけ保留する。
    // 2回目以降に SplashPage が作られても（規約同意後など）何もしない
    if (!_firstFrameReleased) {
      WidgetsBinding.instance.deferFirstFrame();
      _holdingFirstFrame = true;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_holdingFirstFrame) return;
    // 画像のデコード完了を待ってから最初のフレームを許可する。
    // 何かの理由で完了しなくても起動を止めないよう、上限を設けて必ず解除する
    precacheImage(_splashImage, context)
        .timeout(const Duration(seconds: 2), onTimeout: () {})
        .whenComplete(_releaseFirstFrame);
  }

  @override
  void dispose() {
    _releaseFirstFrame();
    super.dispose();
  }

  void _releaseFirstFrame() {
    if (!_holdingFirstFrame) return;
    _holdingFirstFrame = false;
    _firstFrameReleased = true;
    WidgetsBinding.instance.allowFirstFrame();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.iwa,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 専用スプラッシュ画像（画面いっぱい。上下は画像側のビネットで自然に暗く落ちる）
          Image(
            image: _splashImage,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            // 画像の差し替え時にフェードさせない（LaunchScreen と同じ絵をそのまま据える）
            gaplessPlayback: true,
          ),
          // 下端の控えめなローディング
          Align(
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
