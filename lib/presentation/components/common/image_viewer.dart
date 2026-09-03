import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_tokens.dart';

/// 画像拡大表示ウィジェット
///
/// 役割:
/// - 複数画像の拡大表示とスワイプ機能
/// - ピンチズーム機能（1.0x - 5.0x）。拡大した写真は元の枠に収めず、画面の外へはみ出す
///   （InteractiveViewer を画面全体に広げ、クリップしない。画像サイズの箱に閉じ込めると
///    「枠の中で写真だけが拡大される」見え方になる）
/// - Hero アニメーション対応
/// - タップして閉じる機能
///
/// クリーンアーキテクチャにおける位置づけ:
/// - Presentation層のUIコンポーネント
/// - 再利用可能なウィジェット
/// - 画像表示に特化した単一責任
class ImageViewer extends StatelessWidget {
  /// 表示する画像URLのリスト
  final List<String> imageUrls;

  /// 初期表示する画像のインデックス
  final int initialIndex;

  /// Heroアニメーション用のタグプレフィックス
  final String heroTagPrefix;

  const ImageViewer({
    super.key,
    required this.imageUrls,
    required this.initialIndex,
    required this.heroTagPrefix,
  });

  /// 画像拡大表示ダイアログを表示
  ///
  /// [context] ビルドコンテキスト
  /// [imageUrls] 表示する画像URLのリスト
  /// [initialIndex] 初期表示する画像のインデックス
  /// [heroTagPrefix] Heroアニメーション用のタグプレフィックス
  static Future<void> show({
    required BuildContext context,
    required List<String> imageUrls,
    required int initialIndex,
    required String heroTagPrefix,
  }) async {
    if (imageUrls.isEmpty) return;

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "ImageViewer",
      barrierColor: Colors.black.withOpacity(0.9),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, _, __) {
        return ImageViewer(
          imageUrls: imageUrls,
          initialIndex: initialIndex,
          heroTagPrefix: heroTagPrefix,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          PageView.builder(
            controller: PageController(initialPage: initialIndex),
            itemCount: imageUrls.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).pop(),
                // ズームの箱は画面全体。拡大した写真は元の枠を越えて画面外へはみ出す
                child: InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 5.0,
                  clipBehavior: Clip.none,
                  child: Center(
                    child: Hero(
                      tag: '${heroTagPrefix}_$index',
                      child: CachedNetworkImage(
                        imageUrl: imageUrls[index],
                        fit: BoxFit.contain,
                        // スピナーは出さない: 黒地のまま→フェードイン
                        fadeInDuration: const Duration(milliseconds: 250),
                        placeholder: (context, url) => const SizedBox.expand(),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.error,
                          color: AppColors.chalk,
                          size: 48,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          // 閉じるボタン（右上）
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.chalk.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.close,
                  color: AppColors.chalk,
                  size: 24,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
