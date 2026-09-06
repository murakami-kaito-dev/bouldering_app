import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'favorite_user_tweets_provider.dart';
import 'general_tweets_provider.dart';
import 'gym_tweets_provider.dart';
import 'my_tweets_provider.dart';
import 'other_user_tweets_provider.dart';

/// いいね状態を、同じツイートを持ちうる全ての一覧 Notifier に反映する
///
/// 同じ投稿は「みんなのボル活」「お気に入り」「ジム別」「自分」「他ユーザー」の
/// 複数一覧に同時に存在しうる。片方でいいねしてもう片方が古いままにならないよう、
/// LikeButton がサーバー確定値を受け取った後にここへ通す。
///
/// family Provider は生きているインスタンスにしか触らない（`ref.exists`）。
/// 存在しないものを read すると Notifier が生成され、余計な API 取得が走るため。
///
/// [gymId] 投稿のジム（gymTweetsProvider のキー）
/// [authorUserId] 投稿者（otherUserTweetsProvider のキー）
/// [myUserId] ログイン中ユーザー（myTweetsProvider / favoriteUserTweetsProvider のキー）
void applyLikeToTweetLists(
  WidgetRef ref, {
  required int tweetId,
  required int gymId,
  required String authorUserId,
  required String? myUserId,
  required bool liked,
  required int count,
}) {
  if (ref.exists(generalTweetsProvider)) {
    ref.read(generalTweetsProvider.notifier).updateLike(tweetId, liked, count);
  }
  if (ref.exists(gymTweetsProvider(gymId))) {
    ref.read(gymTweetsProvider(gymId).notifier).updateLike(tweetId, liked, count);
  }
  if (ref.exists(otherUserTweetsProvider(authorUserId))) {
    ref
        .read(otherUserTweetsProvider(authorUserId).notifier)
        .updateLike(tweetId, liked, count);
  }
  if (myUserId != null) {
    if (ref.exists(myTweetsProvider(myUserId))) {
      ref.read(myTweetsProvider(myUserId).notifier).updateLike(tweetId, liked, count);
    }
    if (ref.exists(favoriteUserTweetsProvider(myUserId))) {
      ref
          .read(favoriteUserTweetsProvider(myUserId).notifier)
          .updateLike(tweetId, liked, count);
    }
  }
}
