import 'dart:core';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../common/boul_log.dart';
import '../../providers/general_tweets_provider.dart';

/// ■ クラス
/// - みんなのボル活 表示クラス
class GeneralTweetsSection extends ConsumerStatefulWidget {
  const GeneralTweetsSection({super.key});

  @override
  GeneralTweetsSectionState createState() => GeneralTweetsSectionState();
}

class GeneralTweetsSectionState extends ConsumerState<GeneralTweetsSection> {
  // ボル活ページのスクロールを監視するコントローラ
  final ScrollController _generalTweetsScrollController = ScrollController();

  /// ■ メソッド(イニシャライザ)
  /// - 初期化
  @override
  void initState() {
    super.initState();
    _generalTweetsScrollController.addListener(_onGeneralTweetsScroll);
  }

  /// ■ メソッド(クリーンアップ処理)
  /// - dispose
  /// - ページコントローラを破棄
  @override
  void dispose() {
    _generalTweetsScrollController.dispose();
    super.dispose();
  }

  /// ■ メソッド
  /// - スクロールが最下部にに行ったときに，新しいツイートをロードする処理
  void _onGeneralTweetsScroll() {
    if (_generalTweetsScrollController.position.pixels >
        _generalTweetsScrollController.position.maxScrollExtent - 100) {
      ref.read(generalTweetsProvider.notifier).fetchMoreGeneralTweets();
    }
  }

  @override
  Widget build(BuildContext context) {
    final generalTweetsState = ref.watch(generalTweetsProvider);
    final generalTweets = generalTweetsState.generalTweets;
    final hasMoreGeneralTweets = generalTweetsState.hasMore;

    // 初回呼び出し時のみ，ローディング表示でツイート取得していることをユーザーへ知らせる
    if (generalTweetsState.isFirstFetch) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(generalTweetsProvider.notifier).refreshTweets();
      },
      child: ListView.builder(
        controller: _generalTweetsScrollController,
        itemCount: generalTweets.length + (hasMoreGeneralTweets ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == generalTweets.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: SizedBox.shrink(),
              ),
            );
          }

          final generalTweet = generalTweets[index];

          return BoulLog(
            userId: generalTweet.userId,
            userName: generalTweet.userName,
            userIconUrl: generalTweet.userIconUrl,
            visitedDate: generalTweet.visitedDate
                .toLocal()
                .toIso8601String()
                .split('T')[0],
            gymId: generalTweet.gymId,
            gymName: generalTweet.gymName,
            prefecture: generalTweet.prefecture,
            content: generalTweet.content,
            mediaUrls: generalTweet.mediaUrls,
            tweetId: generalTweet.id,
          );
        },
      ),
    );
  }
}