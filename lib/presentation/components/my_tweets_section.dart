import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_provider.dart';
import '../providers/my_tweets_provider.dart';
import 'common/boul_log.dart';
import '../theme/app_tokens.dart';
import 'common/boul_log_skeleton.dart';

/// マイツイートセクション
///
/// 役割:
/// - 自分が投稿したツイートを表示するクラス
/// - 過去のプロジェクトと同様の表示形式
///
/// クリーンアーキテクチャにおける位置づけ:
/// - Presentation層のComponent
/// - ユーザーの投稿データ表示に特化したUI部品
///
/// スクロール構造の注意（#74）:
/// - マイページは NestedScrollView（プロフィール＋TabBar が外側、この一覧が body）。
///   内側の ListView に独自の ScrollController を持たせると外側との連動が崩れるため、
///   controller は渡さず PrimaryScrollController に任せる。
/// - 無限スクロールの検知は ScrollController ではなく ScrollNotification で行う。
/// - 件数が少なくても引っ張って更新できるよう AlwaysScrollableScrollPhysics を付ける
///   （これが無いと 1〜2 件のときスクロールできず RefreshIndicator が始まらない）。
class MyTweetsSection extends ConsumerStatefulWidget {
  const MyTweetsSection({super.key});

  @override
  MyTweetsSectionState createState() => MyTweetsSectionState();
}

class MyTweetsSectionState extends ConsumerState<MyTweetsSection> {
  /// ■ メソッド
  /// - 無限スクロール: 一覧の下端付近まで来たら次ページを読む
  bool _onScrollNotification(ScrollNotification notification) {
    // depth 0 = この一覧自身の通知（カード内の横スクロール等は対象外）
    if (notification.depth != 0) return false;
    if (notification is! ScrollUpdateNotification &&
        notification is! ScrollEndNotification) {
      return false;
    }
    if (notification.metrics.pixels >=
        notification.metrics.maxScrollExtent - 100) {
      final user = ref.read(userProvider).valueOrNull;
      if (user != null) {
        ref.read(myTweetsProvider(user.id).notifier).loadMore();
      }
    }
    return false;
  }

  /// ■ メソッド
  /// - リフレッシュ開始（プルリフレッシュ／初回失敗時の再読み込み）
  /// - 失敗しても一覧はそのまま残し、SnackBar で知らせる
  Future<void> _refetchTweets() async {
    final user = ref.read(userProvider).valueOrNull;
    if (user == null) return;

    final succeeded =
        await ref.read(myTweetsProvider(user.id).notifier).refresh();
    if (!succeeded && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ボル活の更新に失敗しました')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);

    return userState.when(
      data: (user) {
        if (user == null) {
          // ログイン済みだがユーザー情報がまだ来ていない（起動直後の初期状態）。
          // 読込中と同じ骨組みを出しておく（取得後に一覧へ差し替わる）
          return const BoulLogSkeletonList();
        }

        // 自分のツイート状態を監視
        final myTweetsState = ref.watch(myTweetsProvider(user.id));
        final tweets = myTweetsState.tweets;

        // 骨組みは「初回取得でまだ一度も結果を受け取っていない」ときだけ（スピナーは出さない）。
        // プルリフレッシュ中（isRefreshing）は今の一覧／空状態をそのまま出し続ける（#77）
        if (myTweetsState.isFirstFetch && tweets.isEmpty) {
          return const BoulLogSkeletonList();
        }

        // 初回取得に失敗して 1 件も出せない場合だけ、エラーと再読み込み動線を出す
        // （追加読込・更新の失敗は一覧を残したまま知らせる）
        if (myTweetsState.error != null && tweets.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  myTweetsState.error!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.sunabokori,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _refetchTweets,
                  child: const Text('再読み込み'),
                ),
              ],
            ),
          );
        }

        return NotificationListener<ScrollNotification>(
          onNotification: _onScrollNotification,
          child: RefreshIndicator(
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
                              color: AppColors.sunabokori,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'まだボル活記録がありません',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.sunabokori,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'ジムに行って記録を投稿してみましょう！',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.sunabokori,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    key: const PageStorageKey<String>('my_tweets_section'),
                    // 件数が少なくても引っ張って更新できるようにする（#74）
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount:
                        tweets.length + (myTweetsState.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      // 追加読込（ページング）中のスピナー: 一覧の末尾に出す
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
                        contextPrefix: 'my_tweets', // マイツイート画面用
                      );
                    },
                  ),
          ),
        );
      },
      // ユーザー情報の取得中も骨組みを置いておく（取得後に一覧へ差し替わる）
      loading: () => const BoulLogSkeletonList(),
      error: (error, stackTrace) => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.holdRed,
            ),
            SizedBox(height: 16),
            Text(
              'ツイートの読み込みに失敗しました',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.sunabokori,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
