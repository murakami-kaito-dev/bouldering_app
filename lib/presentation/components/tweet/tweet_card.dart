import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/tweet.dart';
import '../../../shared/utils/navigation_helper.dart';

/// ツイートカードコンポーネント
/// 
/// 役割:
/// - ツイート情報の統一された表示
/// - いいね・コメント・シェア機能
/// - ユーザープロフィールへの遷移
/// - ジム詳細への遷移
class TweetCard extends ConsumerWidget {
  final Tweet tweet;
  final VoidCallback? onTap;
  final bool showGymInfo;
  final bool isDetailView;

  const TweetCard({
    super.key,
    required this.tweet,
    this.onTap,
    this.showGymInfo = true,
    this.isDetailView = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap ?? () => NavigationHelper.toTweetDetail(context, tweet.id),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUserHeader(context),
              const SizedBox(height: 12),
              _buildContent(context),
              if (tweet.hasMedia) ...[
                const SizedBox(height: 12),
                _buildMediaPreview(context),
              ],
              if (showGymInfo) ...[
                const SizedBox(height: 12),
                _buildGymInfo(context),
              ],
              const SizedBox(height: 12),
              _buildActionBar(context, ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserHeader(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: () => NavigationHelper.toOtherUserProfile(context, tweet.userId),
          child: CircleAvatar(
            radius: 20,
            backgroundImage: tweet.userIconUrl.isNotEmpty
                ? NetworkImage(tweet.userIconUrl)
                : null,
            child: tweet.userIconUrl.isEmpty
                ? const Icon(Icons.person)
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () => NavigationHelper.toOtherUserProfile(context, tweet.userId),
                child: Text(
                  tweet.userName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                tweet.timeAgoDisplay,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(context, value),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  Icon(Icons.share),
                  SizedBox(width: 8),
                  Text('シェア'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'report',
              child: Row(
                children: [
                  Icon(Icons.flag),
                  SizedBox(width: 8),
                  Text('報告'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tweet.content,
          style: Theme.of(context).textTheme.bodyLarge,
          maxLines: isDetailView ? null : 5,
          overflow: isDetailView ? null : TextOverflow.ellipsis,
        ),
        if (!isDetailView && tweet.content.length > 100) ...[
          const SizedBox(height: 4),
          Text(
            '続きを読む',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.blue[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMediaPreview(BuildContext context) {
    if (tweet.mediaUrls.isEmpty) return const SizedBox.shrink();

    if (tweet.mediaUrls.length == 1) {
      return _buildSingleMediaPreview(context);
    } else {
      return _buildMultipleMediaPreview(context);
    }
  }

  Widget _buildSingleMediaPreview(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Image.network(
          tweet.mediaUrls.first,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: Colors.grey[300],
            child: const Center(
              child: Icon(Icons.image_not_supported, size: 50),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMultipleMediaPreview(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: tweet.mediaUrls.length,
        itemBuilder: (context, index) => Container(
          width: 200,
          margin: EdgeInsets.only(right: index < tweet.mediaUrls.length - 1 ? 8 : 0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              tweet.mediaUrls[index],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey[300],
                child: const Center(
                  child: Icon(Icons.image_not_supported),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGymInfo(BuildContext context) {
    return InkWell(
      onTap: () => NavigationHelper.toGymDetail(context, tweet.gymId),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.fitness_center, size: 20, color: Colors.blue[600]),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tweet.gymName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: Colors.blue[800],
                    ),
                  ),
                  Text(
                    tweet.prefecture,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.blue[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 16, color: Colors.blue[600]),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBar(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        _buildActionButton(
          icon: Icons.favorite_border,
          activeIcon: Icons.favorite,
          count: tweet.likedCount,
          isActive: false, // TODO: Implement liked status from user state
          onTap: () => _toggleLike(ref),
          activeColor: Colors.red,
        ),
        const SizedBox(width: 24),
        _buildActionButton(
          icon: Icons.comment_outlined,
          count: 0, // TODO: Get comment count
          onTap: () => NavigationHelper.toTweetDetail(context, tweet.id),
        ),
        const SizedBox(width: 24),
        _buildActionButton(
          icon: Icons.bookmark_border,
          activeIcon: Icons.bookmark,
          isActive: false, // TODO: Implement bookmark status
          onTap: () => _toggleBookmark(ref),
          activeColor: Colors.blue,
        ),
        const Spacer(),
        if (tweet.hasMovie) ...[
          Icon(Icons.play_circle_outline, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            '動画',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    IconData? activeIcon,
    int? count,
    bool isActive = false,
    required VoidCallback onTap,
    Color? activeColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive && activeIcon != null ? activeIcon : icon,
              size: 20,
              color: isActive && activeColor != null 
                  ? activeColor 
                  : Colors.grey[600],
            ),
            if (count != null && count > 0) ...[
              const SizedBox(width: 4),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 12,
                  color: isActive && activeColor != null 
                      ? activeColor 
                      : Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _toggleLike(WidgetRef ref) async {
    try {
      // TODO: Implement like functionality
      // await ref.read(tweetProvider.notifier).toggleLike(tweet.id);
    } catch (e) {
      // Handle error silently or show snackbar
    }
  }

  void _toggleBookmark(WidgetRef ref) async {
    try {
      // TODO: Implement bookmark functionality
      // await ref.read(favoriteProvider.notifier).toggleBookmark(tweet.id);
    } catch (e) {
      // Handle error silently or show snackbar
    }
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'share':
        _sharePost(context);
        break;
      case 'report':
        _reportPost(context);
        break;
    }
  }

  void _sharePost(BuildContext context) {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('シェア機能は実装予定です')),
    );
  }

  void _reportPost(BuildContext context) {
    NavigationHelper.showConfirmDialog(
      context: context,
      title: '投稿を報告',
      message: 'この投稿に不適切な内容が含まれていますか？',
      confirmText: '報告する',
    ).then((confirmed) {
      if (confirmed) {
        // TODO: Implement report functionality
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('報告を受け付けました')),
        );
      }
    });
  }
}