import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_provider.dart';
import '../providers/my_tweets_provider.dart';
import 'common/boul_log.dart';

/// マイツイートセクション
///
/// 役割:
/// - 自分が投稿したツイートを表示するクラス
/// - 過去のプロジェクトと同様の表示形式
///
/// クリーンアーキテクチャにおける位置づけ:
/// - Presentation層のComponent
/// - ユーザーの投稿データ表示に特化したUI部品
class MyTweetsSection extends ConsumerStatefulWidget {
  const MyTweetsSection({super.key});

  @override
  MyTweetsSectionState createState() => MyTweetsSectionState();
}

class MyTweetsSectionState extends ConsumerState<MyTweetsSection> {
  // ■ プロパティ
  final ScrollController _scrollController = ScrollController();

  /// ■ dispose
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// ■ メソッド
  /// - 無限スクロール用リスナー
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      final userState = ref.read(userProvider);
      userState.whenData((user) {
        if (user != null) {
          ref.read(myTweetsProvider(user.id).notifier).loadMore();
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  /// ■ メソッド
  /// - リフレッシュ開始
  Future<void> _refetchTweets() async {
    final userState = ref.read(userProvider);
    await userState.when(
      data: (user) async {
        if (user != null) {
          await ref.read(myTweetsProvider(user.id).notifier).refresh();
        }
      },
      loading: () async {},
      error: (_, __) async {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);

    return userState.when(
      data: (user) {
        if (user == null) {
          return const Center(
            child: Text('ユーザー情報が見つかりません'),
          );
        }

        // 自分のツイート状態を監視
        final myTweetsState = ref.watch(myTweetsProvider(user.id));
        final tweets = myTweetsState.tweets;

        // ローディング状態の処理
        if (myTweetsState.isFirstFetch && tweets.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        // エラー状態の処理
        if (myTweetsState.error != null) {
          return Center(child: Text(myTweetsState.error!));
        }

        return RefreshIndicator(
          onRefresh: _refetchTweets,
          child: tweets.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  shrinkWrap: true,
                  children: const [
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: 64),
                          Icon(
                            Icons.library_books_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'まだボル活記録がありません',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'ジムに行って記録を投稿してみましょう！',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  key: const PageStorageKey<String>('my_tweets_section'),
                  controller: _scrollController,
                  itemCount: tweets.length + (myTweetsState.hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    // ローディングインジケーター表示
                    if (index == tweets.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final tweet = tweets[index];

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
                      tweetId: tweet.id,
                      content: tweet.content,
                      mediaUrls: tweet.mediaUrls,
                    );
                  },
                ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stackTrace) => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            SizedBox(height: 16),
            Text(
              'ツイートの読み込みに失敗しました',
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
}
