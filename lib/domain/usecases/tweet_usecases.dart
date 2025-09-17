import '../entities/tweet.dart';
import '../repositories/tweet_repository.dart';
import '../exceptions/app_exceptions.dart';
import 'package:uuid/uuid.dart';

class GetTweetsUseCase {
  final TweetRepository _tweetRepository;

  GetTweetsUseCase(this._tweetRepository);

  Future<List<Tweet>> execute({int limit = 20, String? cursor}) async {
    try {
      return await _tweetRepository.getAllTweets(limit: limit, cursor: cursor);
    } catch (e) {
      throw DataFetchException(
        message: 'ツイート取得に失敗しました',
        originalError: e,
      );
    }
  }
}

class GetFavoriteTweetsUseCase {
  final TweetRepository _tweetRepository;

  GetFavoriteTweetsUseCase(this._tweetRepository);

  Future<List<Tweet>> execute(String userId,
      {int limit = 20, String? cursor}) async {
    try {
      return await _tweetRepository.getFavoriteTweets(userId,
          limit: limit, cursor: cursor);
    } catch (e) {
      throw DataFetchException(
        message: 'お気に入りツイート取得に失敗しました',
        originalError: e,
      );
    }
  }
}

class GetUserTweetsUseCase {
  final TweetRepository _tweetRepository;

  GetUserTweetsUseCase(this._tweetRepository);

  Future<List<Tweet>> execute(String userId,
      {int limit = 20, int offset = 0}) async {
    try {
      return await _tweetRepository.getTweetsByUserId(userId,
          limit: limit, offset: offset);
    } catch (e) {
      throw DataFetchException(
        message: 'マイツイート取得に失敗しました',
        originalError: e,
      );
    }
  }
}

class GetGymTweetsUseCase {
  final TweetRepository _tweetRepository;

  GetGymTweetsUseCase(this._tweetRepository);

  Future<List<Tweet>> execute(int gymId,
      {int limit = 20, int offset = 0}) async {
    try {
      return await _tweetRepository.getTweetsByGymId(gymId,
          limit: limit, offset: offset);
    } catch (e) {
      throw DataFetchException(
        message: 'ジムツイート取得に失敗しました',
        originalError: e,
      );
    }
  }
}

class PostTweetUseCase {
  final TweetRepository _tweetRepository;

  PostTweetUseCase(this._tweetRepository);

  Future<bool> execute({
    required String userId,
    required int gymId,
    required String content,
    required DateTime visitedDate,
    String? movieUrl,
    List<String>? mediaUrls,
  }) async {
    try {
      if (content.trim().isEmpty) {
        throw const ValidationException(
          message: 'ツイート内容を入力してください',
          errors: {'content': 'ツイート内容は必須です'},
          code: 'EMPTY_CONTENT',
        );
      }

      // 一時的なpostUuidを生成（通常はActivityPostUseCaseから呼ばれるが、後方互換性のため）
      const uuid = Uuid();
      final postUuid = uuid.v4();

      // mediaUrlsをmediaDataに変換（後方互換性のため）
      final mediaData = mediaUrls?.map((url) => {
        'url': url,
        'assetUuid': '', // 既存URLの場合は空
        'storagePrefix': '', // 既存URLの場合は空
        'mimeType': '', // 既存URLの場合は空
      }).toList();

      return await _tweetRepository.createTweet(
        userId: userId,
        gymId: gymId,
        content: content,
        visitedDate: visitedDate,
        postUuid: postUuid,
        movieUrl: movieUrl,
        mediaData: mediaData,
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw DataSaveException(
        message: 'ツイート投稿に失敗しました',
        originalError: e,
      );
    }
  }
}

class DeleteTweetUseCase {
  final TweetRepository _tweetRepository;

  DeleteTweetUseCase(this._tweetRepository);

  Future<bool> execute(int tweetId, String userId) async {
    try {
      return await _tweetRepository.deleteTweet(tweetId, userId);
    } catch (e) {
      throw DataSaveException(
        message: 'ツイート削除に失敗しました',
        originalError: e,
      );
    }
  }
}
