import '../entities/tweet.dart';
import '../exceptions/app_exceptions.dart';
import '../repositories/tweet_repository.dart';

/// ツイート 1 件取得（スレッド画面の上部に表示する投稿）
///
/// tweet_usecases.dart とは別ファイルにしてある（並行開発中の衝突回避）
class GetTweetByIdUseCase {
  final TweetRepository _tweetRepository;

  GetTweetByIdUseCase(this._tweetRepository);

  Future<Tweet?> execute(int tweetId) async {
    try {
      return await _tweetRepository.getTweetById(tweetId);
    } catch (e) {
      throw DataFetchException(
        message: 'ボル活の取得に失敗しました',
        originalError: e,
      );
    }
  }
}
