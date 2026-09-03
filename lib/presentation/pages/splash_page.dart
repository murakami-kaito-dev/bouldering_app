import 'dart:async';

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
/// 起動直後の暗転対策（Issue #60）:
/// - iOS 側は LaunchScreen（同じ画像）を Flutter の最初のフレームが描かれた瞬間に
///   0.2 秒の alpha フェードで外す（Flutter エンジンの固定挙動）。そのとき Flutter 側の
///   フレームに画像がまだ無い（非同期デコード中）と、背景色だけの暗い画面が透けて見える。
/// - そこで画像は [precache] で runApp より前にデコード済みにしておき、最初のフレームから
///   必ず画像が載るようにする（main_dev / main_prod から呼ぶ）
/// - スピナーはフェードが終わってから出す。クロスフェードが「同じ画像どうし」になり、
///   受け渡しの瞬間に何も変化しない
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  /// スプラッシュ画像（iOS の LaunchImage とピクセル一致）
  static const ImageProvider image = AssetImage('assets/splash.png');

  /// スピナーを出し始めるまでの待ち時間（LaunchScreen のフェード 0.2 秒より長く）
  static const Duration spinnerDelay = Duration(milliseconds: 500);

  /// スプラッシュ画像を ImageCache にデコード済みにする（runApp の前に呼ぶ）
  ///
  /// 画面に出す [Image] と同じ [image] を同じ設定で解決するので、最初のフレームは
  /// キャッシュから同期的に描かれる。失敗・遅延しても起動は止めない（タイムアウト付き）
  static Future<void> precache({Duration timeout = const Duration(seconds: 2)}) {
    final completer = Completer<void>();
    final stream = image.resolve(ImageConfiguration.empty);
    late final ImageStreamListener listener;
    void done() {
      stream.removeListener(listener);
      if (!completer.isCompleted) completer.complete();
    }

    listener = ImageStreamListener(
      (_, __) => done(),
      onError: (_, __) => done(),
    );
    stream.addListener(listener);
    return completer.future.timeout(timeout, onTimeout: done);
  }

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool _showSpinner = false;
  Timer? _spinnerTimer;

  @override
  void initState() {
    super.initState();
    _spinnerTimer = Timer(SplashPage.spinnerDelay, () {
      if (mounted) setState(() => _showSpinner = true);
    });
  }

  @override
  void dispose() {
    _spinnerTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.iwa,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 専用スプラッシュ画像（画面いっぱい。上下は画像側のビネットで自然に暗く落ちる）
          const Image(
            image: SplashPage.image,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            gaplessPlayback: true,
          ),
          // 下端の控えめなローディング（LaunchScreen のフェードが終わってから淡く出す）
          Align(
            alignment: const Alignment(0, 0.82),
            child: AnimatedOpacity(
              opacity: _showSpinner ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.kabeBlue,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
