import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../common/image_viewer.dart';
import '../common/skeleton_bone.dart';
import '../../theme/app_tokens.dart';
import '../../theme/app_text.dart';

/// ■ クラス
/// - マイページで(他ユーザーも含む),アイコンとユーザー名を表示する
class UserLogoAndName extends StatelessWidget {
  // プロパティ
  final String userName;
  final String? userLogo;
  final String? heroTag; // ユーザーアイコン写真を拡大表示するために必要な識別子タグ
  final String? userId;
  final bool isLoading; // true = ユーザー情報の取得中（アイコン・名前の場所だけ確保する）

  // コンストラクタ
  const UserLogoAndName({
    super.key,
    required this.userName,
    this.userLogo,
    this.heroTag,
    this.userId,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    // ユーザー名が長すぎる場合、...でカット
    final displayUserName =
        (userName.length > 12) ? '${userName.substring(0, 11)}…' : userName;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 画像
          GestureDetector(
            onTap: () {
              if (_isValidUrl(userLogo)) {
                ImageViewer.show(
                  context: context,
                  imageUrls: [userLogo!],
                  initialIndex: 0,
                  heroTagPrefix: 'profile_icon_${userId ?? userName.hashCode}',
                );
              }
            },
            child: Hero(
              tag: 'profile_icon_${userId ?? userName.hashCode}_0',
              child: ClipOval(
                // 画像の初回フレームが来るまでも同寸の円を敷いておく（場所取り）
                child: Container(
                  width: 72,
                  height: 72,
                  color: AppColors.wareme,
                  // ユーザー情報の取得中は無地の円だけ（画像の読込中と同じ見た目に揃える）
                  child: isLoading
                      ? null
                      : (_isValidUrl(userLogo))
                    // 縮小デコード+ディスクキャッシュ
                    ? Image(
                        image: ResizeImage(
                          CachedNetworkImageProvider(userLogo!),
                          width: 200,
                        ),
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return _buildPlaceholderIcon();
                        },
                        errorBuilder: (context, error, stackTrace) {
                          // 画像読み込み失敗時，デフォルトアイコンを表示
                          return _buildPlaceholderIcon();
                        },
                      )
                    : _buildPlaceholderIcon(),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 名前（取得中は同じ行の高さで淡い面を置いておく）
          isLoading
              ? SkeletonTextBone(style: AppText.heading(size: 20), width: 140)
              : Text(
                  displayUserName,
                  style: AppText.heading(size: 20),
                ),
        ],
      ),
    );
  }

  /// デフォルト画像アイコン
  Widget _buildPlaceholderIcon() {
    return Container(
      width: 72,
      height: 72,
      decoration: const BoxDecoration(
        color: AppColors.wareme,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.person,
        color: AppColors.sunabokori,
        size: 40,
      ),
    );
  }

  /// URL有効性チェック
  bool _isValidUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    return Uri.tryParse(url) != null && url.startsWith('http');
  }
}
