import 'dart:core';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../common/boul_log.dart';
import '../common/app_logo.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/favorite_user_tweets_provider.dart';

class FavoriteTweetsSection extends ConsumerStatefulWidget {
  const FavoriteTweetsSection({super.key});

  @override
  FavoriteTweetsSectionState createState() => FavoriteTweetsSectionState();
}

class FavoriteTweetsSectionState extends ConsumerState<FavoriteTweetsSection> {
  // スクロールを監視するコントローラ
  final ScrollController _favoriteTweetsScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _favoriteTweetsScrollController.addListener(_onFavoriteUserTweetsScroll);
  }

  @override
  void dispose() {
    _favoriteTweetsScrollController.dispose();
    super.dispose();
  }

  void _onFavoriteUserTweetsScroll() {
    if (_favoriteTweetsScrollController.position.pixels >
        _favoriteTweetsScrollController.position.maxScrollExtent - 100) {
      final userAsyncValue = ref.read(userProvider);
      userAsyncValue.whenData((user) {
        if (user != null) {
          ref
              .read(favoriteUserTweetsProvider(user.id).notifier)
              .fetchMoreFavoriteUserTweets();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = ref.watch(authProvider);
    final userAsyncValue = ref.watch(userProvider);

    return userAsyncValue.when(
      data: (user) {
        final userId = user?.id;

        if (!isLoggedIn || userId == null) {
          return const Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 余白
              SizedBox(height: 32),

              // ロゴ
              Center(child: AppLogo()),
              SizedBox(height: 16),

              Text(
                'イワノボリタイに登録しよう',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF0056FF),
                  fontSize: 20,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  letterSpacing: -0.50,
                ),
              ),
              SizedBox(height: 16),

              Text(
                'ログインしてユーザーを\nお気に入り登録しよう!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                  letterSpacing: -0.50,
                ),
              ),
              SizedBox(height: 16),

              Text(
                'お気に入り登録したユーザーの\nツイートを見ることができます！',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                  letterSpacing: -0.50,
                ),
              ),
            ],
          );
        }

        // お気に入りユーザーツイート
        final favoriteUserTweetsState =
            ref.watch(favoriteUserTweetsProvider(userId));
        final favoriteUserTweets = favoriteUserTweetsState.favoriteUserTweets;
        final hasMoreFavoriteUserTweets = favoriteUserTweetsState.hasMore;

        // 初回呼び出し時のみ，ローディング表示でツイート取得していることをユーザーに知らせる
        if (favoriteUserTweetsState.isFirstFetch) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: () async {
            await ref
                .read(favoriteUserTweetsProvider(userId).notifier)
                .refreshTweets();
          },
          child: favoriteUserTweets.isEmpty
              ? ListView(
                  children: const [
                    // 余白
                    SizedBox(height: 128),

                    // ロゴ
                    Center(child: AppLogo()),
                    SizedBox(height: 16),

                    Text(
                      'ユーザーをお気に入り登録しよう！',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF0056FF),
                        fontSize: 20,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                        letterSpacing: -0.50,
                      ),
                    ),
                    SizedBox(height: 16),

                    Text(
                      'お気に入り登録して\n他の人の活動を見てみましょう！',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                        letterSpacing: -0.50,
                      ),
                    ),
                    SizedBox(height: 16),
                  ],
                )
              : ListView.builder(
                  controller: _favoriteTweetsScrollController,
                  itemCount: favoriteUserTweets.length +
                      (hasMoreFavoriteUserTweets ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == favoriteUserTweets.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: SizedBox.shrink(),
                        ),
                      );
                    }

                    final favoriteUserTweet = favoriteUserTweets[index];

                    return BoulLog(
                      userId: favoriteUserTweet.userId,
                      userName: favoriteUserTweet.userName,
                      userIconUrl: favoriteUserTweet.userIconUrl,
                      visitedDate: favoriteUserTweet.visitedDate
                          .toLocal()
                          .toIso8601String()
                          .split('T')[0],
                      gymId: favoriteUserTweet.gymId,
                      gymName: favoriteUserTweet.gymName,
                      prefecture: favoriteUserTweet.prefecture,
                      content: favoriteUserTweet.content,
                      mediaUrls: favoriteUserTweet.mediaUrls,
                      tweetId: favoriteUserTweet.id,
                    );
                  },
                ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: CircularProgressIndicator()),
    );
  }
}
