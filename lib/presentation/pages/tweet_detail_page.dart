import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/tweet.dart';
import '../../shared/utils/navigation_helper.dart';

/// ツイート詳細ページ
/// 
/// 役割:
/// - 個別ツイートの詳細表示
/// - コメント一覧の表示
/// - いいね・ブックマーク・シェア機能
/// - 返信投稿機能
class TweetDetailPage extends ConsumerStatefulWidget {
  final Tweet tweet;

  const TweetDetailPage({
    super.key,
    required this.tweet,
  });

  @override
  ConsumerState<TweetDetailPage> createState() => _TweetDetailPageState();
}

class _TweetDetailPageState extends ConsumerState<TweetDetailPage> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ツイート詳細'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: _shareTweet,
            icon: const Icon(Icons.share),
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.report, size: 20),
                    SizedBox(width: 8),
                    Text('報告'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // ツイート詳細表示
          Expanded(
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // メインツイート
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: _buildDetailedTweetCard(),
                  ),
                ),
                
                // アクション統計
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey[200]!,
                          width: 1,
                        ),
                      ),
                    ),
                    child: _buildActionStats(),
                  ),
                ),
                
                // アクションボタン
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey[200]!,
                          width: 1,
                        ),
                      ),
                    ),
                    child: _buildActionButtons(),
                  ),
                ),
                
                // コメントセクション
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'コメント',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildCommentsList(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // コメント入力欄
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildDetailedTweetCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ユーザー情報
        Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: widget.tweet.userIconUrl.isNotEmpty
                  ? NetworkImage(widget.tweet.userIconUrl)
                  : null,
              child: widget.tweet.userIconUrl.isEmpty
                  ? const Icon(Icons.person, size: 24)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => NavigationHelper.toOtherUserProfile(
                      context, 
                      widget.tweet.userId,
                    ),
                    child: Text(
                      widget.tweet.userName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    widget.tweet.timeAgoDisplay,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // ツイート内容
        Text(
          widget.tweet.content,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        
        if (widget.tweet.mediaUrls.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildMediaGallery(),
        ],
        
        if (widget.tweet.movieUrl != null) ...[
          const SizedBox(height: 12),
          _buildVideoPlayer(),
        ],
        
        const SizedBox(height: 16),
        
        // ジム情報
        GestureDetector(
          onTap: () => NavigationHelper.toGymDetail(
            context, 
            widget.tweet.gymId,
          ),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.fitness_center, 
                  size: 20, 
                  color: Colors.blue[600],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.tweet.gymName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: Colors.blue[800],
                        ),
                      ),
                      Text(
                        widget.tweet.prefecture,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.blue[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, 
                  color: Colors.blue[600],
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // 投稿日時
        Text(
          widget.tweet.formattedCreatedAt,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildMediaGallery() {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.tweet.mediaUrls.length,
        itemBuilder: (context, index) {
          return Container(
            width: 200,
            margin: EdgeInsets.only(right: index < widget.tweet.mediaUrls.length - 1 ? 8 : 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                widget.tweet.mediaUrls[index],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.broken_image, size: 40),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_circle_outline, 
              size: 60, 
              color: Colors.white,
            ),
            SizedBox(height: 8),
            Text(
              '動画プレイヤー（実装予定）',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionStats() {
    return Row(
      children: [
        _buildStatItem(
          count: widget.tweet.likedCount,
          label: 'いいね',
          onTap: () {
            // TODO: Show users who liked
          },
        ),
        const SizedBox(width: 24),
        _buildStatItem(
          count: 0, // TODO: Get actual comment count
          label: 'コメント',
          onTap: () {
            // Scroll to comments
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
        ),
        const SizedBox(width: 24),
        _buildStatItem(
          count: 0, // TODO: Get actual bookmark count
          label: 'ブックマーク',
          onTap: () {
            // TODO: Show users who bookmarked
          },
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required int count,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyMedium,
          children: [
            TextSpan(
              text: count.toString(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            TextSpan(
              text: ' $label',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildActionButton(
          icon: Icons.chat_bubble_outline,
          onPressed: () {
            // Focus comment input
            FocusScope.of(context).requestFocus(FocusNode());
          },
        ),
        _buildActionButton(
          icon: Icons.favorite_border, // TODO: Change based on like status
          color: Colors.red[400],
          onPressed: _toggleLike,
        ),
        _buildActionButton(
          icon: Icons.bookmark_border, // TODO: Change based on bookmark status
          color: Colors.blue[400],
          onPressed: _toggleBookmark,
        ),
        _buildActionButton(
          icon: Icons.share,
          onPressed: _shareTweet,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(
          icon,
          size: 24,
          color: color ?? Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildCommentsList() {
    // TODO: Implement actual comments loading
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Text(
          'コメント機能は実装予定です',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'コメントを入力...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Theme.of(context).primaryColor),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              maxLines: null,
              keyboardType: TextInputType.multiline,
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: _canPostComment() ? _postComment : null,
            icon: Icon(
              Icons.send,
              color: _canPostComment() 
                  ? Theme.of(context).primaryColor 
                  : Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  bool _canPostComment() {
    return _commentController.text.trim().isNotEmpty;
  }

  void _postComment() {
    if (!_canPostComment()) return;
    
    // TODO: Implement comment posting
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('コメント機能は実装予定です')),
    );
    
    _commentController.clear();
  }

  void _toggleLike() {
    // TODO: Implement like functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('いいね機能は実装予定です')),
    );
  }

  void _toggleBookmark() {
    // TODO: Implement bookmark functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ブックマーク機能は実装予定です')),
    );
  }

  void _shareTweet() {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('シェア機能は実装予定です')),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'report':
        _reportTweet();
        break;
    }
  }

  void _reportTweet() {
    // TODO: Implement report functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('報告機能は実装予定です')),
    );
  }
}