import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/gym_tweets_provider.dart';
import '../common/boul_log.dart';

/// ジム別ツイートセクション
///
/// 役割:
/// - 特定ジムでの投稿のみを表示するUIコンポーネント
/// - ジム詳細ページの「ボル活」タブで使用
/// - ページネーション機能（無限スクロール対応）
/// - プルリフレッシュ機能
///
/// クリーンアーキテクチャにおける位置づけ:
/// - Presentation層のComponent
/// - gym_tweets_providerを通じてデータを取得
/// - 再利用可能なUIコンポーネント
///
/// 単一責任の原則:
/// - ジムツイート表示に関する責任のみを持つ
/// - ページロジックとは分離
class GymTweetsSection extends ConsumerStatefulWidget {
  final int gymId;

  const GymTweetsSection({
    super.key,
    required this.gymId,
  });

  @override
  GymTweetsSectionState createState() => GymTweetsSectionState();
}

class GymTweetsSectionState extends ConsumerState<GymTweetsSection> {
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

  /// 無限スクロール用リスナー
  /// スクロール位置が下端に近づいたら追加データを読み込み
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      ref.read(gymTweetsProvider(widget.gymId).notifier).loadMore();
    }
  }

  /// プルリフレッシュ処理
  /// ツイート一覧を初期化して最新データを取得
  Future<void> _onRefresh() async {
    await ref.read(gymTweetsProvider(widget.gymId).notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final gymTweetsState = ref.watch(gymTweetsProvider(widget.gymId));

    // 初回ローディング表示
    if (gymTweetsState.isLoading && gymTweetsState.tweets.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.purple,
        ),
      );
    }

    // エラー表示
    if (gymTweetsState.error != null && gymTweetsState.tweets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              gymTweetsState.error!,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _onRefresh,
              child: const Text('再試行'),
            ),
          ],
        ),
      );
    }

    final tweets = gymTweetsState.tweets;

    // 空状態表示
    if (tweets.isEmpty) {
      return RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 64),
                    Icon(
                      Icons.article_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'まだボル活の投稿がありません',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '最初の投稿者になりましょう！',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ツイート一覧表示
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: tweets.length + (gymTweetsState.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          // 追加ローディング表示
          if (index == tweets.length) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: CircularProgressIndicator(
                  color: Colors.purple,
                ),
              ),
            );
          }

          final tweet = tweets[index];
          
          // ツイートカード表示
          return BoulLog(
            userId: tweet.userId,
            userName: tweet.userName,
            userIconUrl: tweet.userIconUrl,
            visitedDate: tweet.visitedDate
                .toLocal()
                .toIso8601String()
                .split('T')[0],
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