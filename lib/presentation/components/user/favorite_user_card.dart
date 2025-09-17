import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/user.dart';
import '../../../shared/utils/navigation_helper.dart';
import '../../providers/gym_provider.dart';
import '../../providers/favorite_user_provider.dart';

/// お気に入りユーザーカードコンポーネント
/// 
/// 役割:
/// - お気に入りユーザーリストの各アイテム表示
/// - お気に入り登録・解除ボタン
/// - ユーザー詳細画面への遷移
/// 
/// クリーンアーキテクチャにおける位置づけ:
/// - Presentation層のComponent
/// - お気に入りユーザー一覧画面で使用される再利用可能なUI部品
class FavoriteUserCard extends ConsumerWidget {
  final User user;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onAfterNavigation;

  const FavoriteUserCard({
    super.key,
    required this.user,
    this.onFavoriteToggle,
    this.onAfterNavigation,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gymMap = ref.watch(gymMapProvider);
    final isFavorite = ref.watch(isFavoriteUserProvider(user.id));
    
    // ホームジム名を取得
    String homeGymName = '-';
    if (user.homeGymId != null && user.homeGymId! > 0) {
      final gym = gymMap[user.homeGymId];
      if (gym != null) {
        homeGymName = gym.name;
      }
    }

    return InkWell(
      onTap: () async {
        // ユーザー詳細画面へ遷移
        await NavigationHelper.toOtherUserProfile(context, user.id);
        // 戻ってきた時のコールバック
        onAfterNavigation?.call();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Row(
          children: [
            // ユーザーアイコン
            Hero(
              tag: 'favorite_user_icon_${user.id}',
              child: ClipOval(
                child: _buildUserIcon(),
              ),
            ),
            const SizedBox(width: 12),

            // ユーザー名とホームジム
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.userName ?? '名無し',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    homeGymName,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // お気に入りボタン
            OutlinedButton(
              onPressed: onFavoriteToggle,
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: isFavorite ? const Color(0xFF0056FF) : Colors.grey,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size(0, 36),
              ),
              child: Text(
                isFavorite ? 'お気に入り解除' : 'お気に入り登録',
                style: TextStyle(
                  color: isFavorite ? const Color(0xFF0056FF) : Colors.grey[700],
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserIcon() {
    if (user.userIconUrl != null && user.userIconUrl!.isNotEmpty) {
      return Image.network(
        user.userIconUrl!,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackIcon();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildFallbackIcon();
        },
      );
    }
    return _buildFallbackIcon();
  }

  Widget _buildFallbackIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFE0E0E0),
      ),
      child: const Icon(Icons.person, size: 28, color: Colors.grey),
    );
  }
}