import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// 画像拡大表示ウィジェット
/// 
/// 役割:
/// - 複数画像の拡大表示とスワイプ機能
/// - ピンチズーム機能（1.0x - 5.0x）
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
      body: PageView.builder(
        controller: PageController(initialPage: initialIndex),
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              color: Colors.transparent,
              child: Center(
                child: Hero(
                  tag: '${heroTagPrefix}_$index',
                  child: InteractiveViewer(
                    minScale: 1.0,
                    maxScale: 5.0,
                    child: CachedNetworkImage(
                      imageUrl: imageUrls[index],
                      fit: BoxFit.contain,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      ),
                      errorWidget: (context, url, error) => const Icon(
                        Icons.error,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}