import '../entities/tweet.dart';

abstract class TweetRepository {
  Future<List<Tweet>> getAllTweets({int limit = 20, String? cursor});
  Future<List<Tweet>> getTweetsByUserId(String userId, {int limit = 20, int offset = 0});
  Future<List<Tweet>> getTweetsByGymId(int gymId, {int limit = 20, int offset = 0});
  Future<List<Tweet>> getFavoriteTweets(String userId, {int limit = 20, String? cursor});
  Future<Tweet?> getTweetById(int tweetId);
  Future<bool> createTweet({
    required String userId,
    required int gymId,
    required String content,
    required DateTime visitedDate,
    required String postUuid,
    String? movieUrl,
    List<Map<String, String>>? mediaData,
  });
  Future<bool> updateTweet({
    required int tweetId,
    required String userId,
    required int gymId,
    required String content,
    required DateTime visitedDate,
    String? movieUrl,
    List<String>? mediaUrls,
  });
  Future<bool> deleteTweet(int tweetId, String userId);
  Future<bool> likeTweet(int tweetId, String userId);
  Future<bool> unlikeTweet(int tweetId, String userId);
}