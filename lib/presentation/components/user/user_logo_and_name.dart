import 'package:flutter/material.dart';

/// ■ クラス
/// - マイページで(他ユーザーも含む),アイコンとユーザー名を表示する
class UserLogoAndName extends StatelessWidget {
  // プロパティ
  final String userName;
  final String? userLogo;
  final String? heroTag; // ユーザーアイコン写真を拡大表示するために必要な識別子タグ
  final String? userId;

  // コンストラクタ
  const UserLogoAndName({
    super.key,
    required this.userName,
    this.userLogo,
    this.heroTag,
    this.userId,
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
                          child: Container(
                            color: Colors.transparent,
                          ),
                        ),
                        Center(
                          child: Hero(
                            tag: heroTag ??
                                'user_icon_default_${userId ?? userName.hashCode}',
                            child: InteractiveViewer(
                              minScale: 1.0,
                              maxScale: 20.0,
                              child: Image.network(
                                userLogo!,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                  transitionBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                );
              }
            },
            child: Hero(
              tag:
                  heroTag ?? 'user_icon_default_${userId ?? userName.hashCode}',
              child: ClipOval(
                child: (_isValidUrl(userLogo))
                    ? Image.network(
                        userLogo!,
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
          const SizedBox(width: 8),

          // 名前
          Text(
            displayUserName,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w500,
              height: 1.2,
              letterSpacing: -0.50,
            ),
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

  /// URL有効性チェック
  bool _isValidUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    return Uri.tryParse(url) != null && url.startsWith('http');
  }
}
