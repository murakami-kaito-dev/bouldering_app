import 'package:flutter/material.dart';
import '../../../shared/utils/image_url_validator.dart';

/// ユーザーアバターコンポーネント
/// 
/// 役割:
/// - ユーザーのアイコンと名前の表示
/// - ゲストユーザーとログインユーザーの表示切り替え
/// - プロフィール画像の拡大表示
/// 
/// クリーンアーキテクチャにおける位置づけ:
/// - Presentation層のUIコンポーネント
/// - 再利用可能なウィジェット
class UserAvatar extends StatelessWidget {
  final String userName;
  final String? userImageUrl;
  final bool isGuest;
  final String? heroTag;
  final VoidCallback? onTap;

  const UserAvatar({
    super.key,
    required this.userName,
    this.userImageUrl,
    this.isGuest = false,
    this.heroTag,
    this.onTap,
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
          // プロフィール画像
          GestureDetector(
            onTap: onTap ?? (userImageUrl != null ? () => _showImageDialog(context) : null),
            child: Hero(
              tag: heroTag ?? 'user_avatar_${userName.hashCode}',
              child: ClipOval(
                child: _buildProfileImage(),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // ユーザー名
          Text(
            displayUserName,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.w500,
              height: 1.2,
              letterSpacing: -0.50,
            ),
          ),
        ],
      ),
    );
  }

  /// プロフィール画像の構築
  Widget _buildProfileImage() {
    if (ImageUrlValidator.isValidImageUrl(userImageUrl)) {
      return Image.network(
        userImageUrl!,
        width: 72,
        height: 72,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildPlaceholderIcon();
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholderIcon();
        },
      );
    } else {
      return _buildPlaceholderIcon();
    }
  }

  /// デフォルトアイコン
  Widget _buildPlaceholderIcon() {
    return Container(
      width: 72,
      height: 72,
      decoration: const BoxDecoration(
        color: Color(0xFFEEEEEE),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.person,
        color: Colors.grey,
        size: 40,
      ),
    );
  }

  /// 画像拡大ダイアログ
  void _showImageDialog(BuildContext context) {
    if (userImageUrl == null) return;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "ProfileImageDialog",
      barrierColor: Colors.white.withOpacity(0.8),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, _, __) {
        return Stack(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(color: Colors.transparent),
            ),
            Center(
              child: Hero(
                tag: heroTag ?? 'user_avatar_${userName.hashCode}',
                child: InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 20.0,
                  child: Image.network(
                    userImageUrl!,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ],
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }
}