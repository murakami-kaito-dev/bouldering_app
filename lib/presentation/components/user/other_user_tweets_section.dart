import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../common/boul_log.dart';
import '../../providers/other_user_tweets_provider.dart';

/// 他ユーザーのツイート一覧セクション
/// 
/// 役割:
/// - 指定されたユーザーの投稿一覧を表示
/// - ボル活ログの表示
/// - 投稿のページネーション（無限スクロール）
/// 
/// クリーンアーキテクチャにおける位置づき:
/// - Presentation層のComponent
/// - 他ユーザーのツイート表示に特化したUI部品
class OtherUserTweetsSection extends ConsumerStatefulWidget {
  final String userId;

  const OtherUserTweetsSection({
    super.key,
    required this.userId,
  });

  @override
  ConsumerState<OtherUserTweetsSection> createState() => _OtherUserTweetsSectionState();
}

class _OtherUserTweetsSectionState extends ConsumerState<OtherUserTweetsSection> {
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      // ページネーション処理
      ref.read(otherUserTweetsProvider(widget.userId).notifier).fetchTweets();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tweetsState = ref.watch(otherUserTweetsProvider(widget.userId));
    
    if (tweetsState.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                tweetsState.error!,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(otherUserTweetsProvider(widget.userId).notifier).refresh();
                },
                child: const Text('再試行'),
              ),
            ],
          ),
        ),
      );
    }

    if (tweetsState.tweets.isEmpty && tweetsState.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (tweetsState.tweets.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.message_outlined,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'まだ投稿がありません',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(otherUserTweetsProvider(widget.userId).notifier).refresh();
      },
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: tweetsState.tweets.length + (tweetsState.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == tweetsState.tweets.length) {
            // ローディングインジケーター
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          final tweet = tweetsState.tweets[index];
          return BoulLog(
            userId: tweet.userId,
            userName: tweet.userName,
            userIconUrl: tweet.userIconUrl,
            visitedDate: tweet.formattedCreatedAt,
            gymId: tweet.gymId,
            gymName: tweet.gymName,
            prefecture: tweet.prefecture,
            content: tweet.content,
            mediaUrls: tweet.mediaUrls,
            tweetId: tweet.id,
          );
        },
      ),
    );
  }
}