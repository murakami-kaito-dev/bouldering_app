import '../../domain/entities/tweet.dart';
import '../../domain/repositories/tweet_repository.dart';
import '../datasources/tweet_datasource.dart';

/// ツイートリポジトリ実装クラス
/// 
/// 役割:
/// - Domainレイヤーで定義されたTweetRepositoryインタフェースの実装
/// - データソースとDomainレイヤー間の橋渡し
/// - ツイート投稿・取得に関するビジネスロジック実装
/// 
/// クリーンアーキテクチャにおける位置づけ:
/// - Infrastructure層のRepository実装
/// - Domain層のRepository抽象クラスに依存（依存関係逆転の原則）
/// - UseCase層から使用される
class TweetRepositoryImpl implements TweetRepository {
  final TweetDataSource _dataSource;

  /// コンストラクタ
  /// 
  /// [_dataSource] ツイートデータソース
  TweetRepositoryImpl(this._dataSource);

  /// 全ツイート取得
  /// 
  /// [limit] 取得件数の上限
  /// [cursor] ページネーション用のカーソル（前回取得の最後のツイートの投稿日時）
  /// 
  /// 返り値:
  /// [List<Tweet>] ツイートリスト
  /// 
  /// ビジネスルール:
  /// - 取得件数は1〜100件の範囲
  /// - カーソルベースページネーション対応
  /// - 取得したツイートは投稿日時の降順でソート（バックエンドで実施済み）
  @override
  Future<List<Tweet>> getAllTweets({int limit = 20, String? cursor}) async {
    // パラメータの妥当性チェック
    if (limit < 1 || limit > 100) {
      throw ArgumentError('取得件数は1〜100件の範囲で指定してください');
    }

    try {
      final tweets = await _dataSource.getAllTweets(limit: limit, cursor: cursor);
      
      // 投稿日時の降順でソート（最新が先頭）
      tweets.sort((a, b) => b.tweetedDate.compareTo(a.tweetedDate));
      
      return tweets;
    } catch (e) {
      rethrow;
    }
  }

  /// ユーザーID指定によるツイート取得
  /// 
  /// [userId] ユーザーID
  /// [limit] 取得件数の上限
  /// [offset] 取得開始位置
  /// 
  /// 返り値:
  /// [List<Tweet>] 指定ユーザーのツイートリスト
  /// 
  /// ビジネスルール:
  /// - ユーザーIDは空文字不可
  /// - 取得件数とオフセットは全ツイート取得と同じ制限
  @override
  Future<List<Tweet>> getTweetsByUserId(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) async {
    if (userId.trim().isEmpty) {
      throw ArgumentError('ユーザーIDは必須です');
    }

    if (limit < 1 || limit > 100) {
      throw ArgumentError('取得件数は1〜100件の範囲で指定してください');
    }

    if (offset < 0) {
      throw ArgumentError('オフセットは0以上で指定してください');
    }

    try {
      final tweets = await _dataSource.getTweetsByUserId(
        userId,
        limit: limit,
        offset: offset,
      );
      
      // 投稿日時の降順でソート
      tweets.sort((a, b) => b.tweetedDate.compareTo(a.tweetedDate));
      
      return tweets;
    } catch (e) {
      rethrow;
    }
  }

  /// ジムID指定によるツイート取得
  /// 
  /// [gymId] ジムID
  /// [limit] 取得件数の上限
  /// [offset] 取得開始位置
  /// 
  /// 返り値:
  /// [List<Tweet>] 指定ジムのツイートリスト
  /// 
  /// ビジネスルール:
  /// - ジムIDは正の整数のみ許可
  /// - 取得件数とオフセットは全ツイート取得と同じ制限
  @override
  Future<List<Tweet>> getTweetsByGymId(
    int gymId, {
    int limit = 20,
    int offset = 0,
  }) async {
    if (gymId <= 0) {
      throw ArgumentError('ジムIDは正の整数で指定してください');
    }

    if (limit < 1 || limit > 100) {
      throw ArgumentError('取得件数は1〜100件の範囲で指定してください');
    }

    if (offset < 0) {
      throw ArgumentError('オフセットは0以上で指定してください');
    }

    try {
      final tweets = await _dataSource.getTweetsByGymId(
        gymId,
        limit: limit,
        offset: offset,
      );
      
      // 投稿日時の降順でソート
      tweets.sort((a, b) => b.tweetedDate.compareTo(a.tweetedDate));
      
      return tweets;
    } catch (e) {
      rethrow;
    }
  }

  /// お気に入りユーザーのツイート取得
  /// 
  /// [userId] ログインユーザーID
  /// [limit] 取得件数の上限
  /// [cursor] ページネーション用のカーソル（前回取得の最後のツイートの投稿日時）
  /// 
  /// 返り値:
  /// [List<Tweet>] お気に入りユーザーのツイートリスト
  /// 
  /// ビジネスルール:
  /// - ログインユーザーのお気に入り登録ユーザーのツイートのみ取得
  /// - 取得件数は1〜100件の範囲
  /// - カーソルベースページネーション対応
  /// - 取得したツイートは投稿日時の降順でソート（バックエンドで実施済み）
  @override
  Future<List<Tweet>> getFavoriteTweets(
    String userId, {
    int limit = 20,
    String? cursor,
  }) async {
    if (userId.trim().isEmpty) {
      throw ArgumentError('ユーザーIDは必須です');
    }

    if (limit < 1 || limit > 100) {
      throw ArgumentError('取得件数は1〜100件の範囲で指定してください');
    }

    try {
      final tweets = await _dataSource.getFavoriteTweets(
        userId,
        limit: limit,
        cursor: cursor,
      );
      
      // 投稿日時の降順でソート
      tweets.sort((a, b) => b.tweetedDate.compareTo(a.tweetedDate));
      
      return tweets;
    } catch (e) {
      rethrow;
    }
  }

  /// ツイート詳細取得
  /// 
  /// [tweetId] ツイートID
  /// 
  /// 返り値:
  /// [Tweet?] ツイートエンティティ、存在しない場合はnull
  /// 
  /// ビジネスルール:
  /// - ツイートIDは正の整数のみ許可
  @override
  Future<Tweet?> getTweetById(int tweetId) async {
    if (tweetId <= 0) {
      return null;
    }

    try {
      return await _dataSource.getTweetById(tweetId);
    } catch (e) {
      rethrow;
    }
  }

  /// ツイート新規投稿
  /// 
  /// [userId] 投稿者のユーザーID
  /// [gymId] 投稿対象のジムID
  /// [content] ツイート内容
  /// [visitedDate] ジム訪問日
  /// [postUuid] 投稿UUID（クライアント側で生成済み）
  /// [movieUrl] 動画URL（オプション）
  /// [mediaData] 画像データリスト（オプション）
  /// 
  /// 返り値:
  /// [bool] 投稿成功時はtrue、失敗時はfalse
  /// 
  /// ビジネスルール:
  /// - ツイート内容は1文字以上500文字以下
  /// - ユーザーIDとジムIDは必須
  /// - 訪問日は現在日以前
  /// - メディアファイルは最大5個まで
  /// - 動画URLとメディアURLの同時指定は不可
  @override
  Future<bool> createTweet({
    required String userId,
    required int gymId,
    required String content,
    required DateTime visitedDate,
    required String postUuid,
    String? movieUrl,
    List<Map<String, String>>? mediaData,
  }) async {
    // 入力値検証
    if (userId.trim().isEmpty) {
      throw ArgumentError('ユーザーIDは必須です');
    }

    if (gymId <= 0) {
      throw ArgumentError('ジムIDは正の整数で指定してください');
    }

    final trimmedContent = content.trim();
    if (trimmedContent.length > 400) {
      throw ArgumentError('ツイート内容は400文字以下で入力してください');
    }

    if (visitedDate.isAfter(DateTime.now())) {
      throw ArgumentError('訪問日は現在日以前で指定してください');
    }

    // メディアファイル数の制限
    if (mediaData != null && mediaData.length > 5) {
      throw ArgumentError('メディアファイルは最大5個まで投稿可能です');
    }

    // 動画URLとメディアURLの同時指定チェック
    if (movieUrl != null && 
        movieUrl.isNotEmpty && 
        mediaData != null && 
        mediaData.isNotEmpty) {
      throw ArgumentError('動画とメディアファイルの同時投稿はできません');
    }

    try {
      return await _dataSource.createTweet(
        userId: userId,
        gymId: gymId,
        content: trimmedContent,
        visitedDate: visitedDate,
        postUuid: postUuid,
        movieUrl: movieUrl?.trim(),
        mediaData: mediaData,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// ツイート更新
  /// 
  /// [tweetId] 更新対象のツイートID
  /// [userId] 更新実行者のユーザーID
  /// [gymId] 投稿対象のジムID
  /// [content] ツイート内容
  /// [visitedDate] ジム訪問日
  /// [movieUrl] 動画URL（オプション）
  /// [mediaUrls] 画像URLリスト（オプション）
  /// 
  /// 返り値:
  /// [bool] 更新成功時はtrue、失敗時はfalse
  /// 
  /// ビジネスルール:
  /// - 自分の投稿のみ更新可能
  /// - ツイート内容は1文字以上500文字以下
  /// - ユーザーID、ツイートID、ジムIDは必須
  /// - 訪問日は現在日以前
  /// - メディアファイルは最大5個まで
  /// - 動画URLとメディアURLの同時指定は不可
  @override
  Future<bool> updateTweet({
    required int tweetId,
    required String userId,
    required int gymId,
    required String content,
    required DateTime visitedDate,
    String? movieUrl,
    List<String>? mediaUrls,
  }) async {
    // 入力値検証
    if (tweetId <= 0) {
      throw ArgumentError('ツイートIDは正の整数で指定してください');
    }

    if (userId.trim().isEmpty) {
      throw ArgumentError('ユーザーIDは必須です');
    }

    if (gymId <= 0) {
      throw ArgumentError('ジムIDは正の整数で指定してください');
    }

    final trimmedContent = content.trim();
    if (trimmedContent.length > 400) {
      throw ArgumentError('ツイート内容は400文字以下で入力してください');
    }

    if (visitedDate.isAfter(DateTime.now())) {
      throw ArgumentError('訪問日は現在日以前で指定してください');
    }

    // メディアファイル数の制限
    if (mediaUrls != null && mediaUrls.length > 5) {
      throw ArgumentError('メディアファイルは最大5個まで投稿可能です');
    }

    // 動画URLとメディアURLの同時指定チェック
    if (movieUrl != null && 
        movieUrl.isNotEmpty && 
        mediaUrls != null && 
        mediaUrls.isNotEmpty) {
      throw ArgumentError('動画とメディアファイルの同時投稿はできません');
    }

    try {
      // 更新前に投稿者確認（セキュリティ）
      final tweet = await _dataSource.getTweetById(tweetId);
      if (tweet == null) {
        return false; // ツイートが存在しない
      }

      if (tweet.userId != userId) {
        throw ArgumentError('自分の投稿のみ更新可能です');
      }

      return await _dataSource.updateTweet(
        tweetId: tweetId,
        userId: userId,
        gymId: gymId,
        content: trimmedContent,
        visitedDate: visitedDate,
        movieUrl: movieUrl?.trim(),
        mediaUrls: mediaUrls?.where((url) => url.trim().isNotEmpty).toList(),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// ツイート削除
  /// 
  /// [tweetId] 削除対象のツイートID
  /// [userId] 削除実行者のユーザーID
  /// 
  /// 返り値:
  /// [bool] 削除成功時はtrue、失敗時はfalse
  /// 
  /// ビジネスルール:
  /// - 自分の投稿のみ削除可能
  /// - ツイートIDとユーザーIDは必須
  @override
  Future<bool> deleteTweet(int tweetId, String userId) async {
    if (tweetId <= 0) {
      throw ArgumentError('ツイートIDは正の整数で指定してください');
    }

    if (userId.trim().isEmpty) {
      throw ArgumentError('ユーザーIDは必須です');
    }

    try {
      // 削除前に投稿者確認（セキュリティ）
      final tweet = await _dataSource.getTweetById(tweetId);
      if (tweet == null) {
        return false; // ツイートが存在しない
      }

      if (tweet.userId != userId) {
        throw ArgumentError('自分の投稿のみ削除可能です');
      }

      return await _dataSource.deleteTweet(tweetId, userId);
    } catch (e) {
      rethrow;
    }
  }

  /// ツイートにいいね追加
  /// 
  /// [tweetId] いいね対象のツイートID
  /// [userId] いいね実行者のユーザーID
  /// 
  /// 返り値:
  /// [bool] いいね追加成功時はtrue、失敗時はfalse
  /// 
  /// ビジネスルール:
  /// - 自分の投稿にはいいねできない
  /// - 重複いいねは防止（バックエンド側で制御）
  @override
  Future<bool> likeTweet(int tweetId, String userId) async {
    if (tweetId <= 0) {
      throw ArgumentError('ツイートIDは正の整数で指定してください');
    }

    if (userId.trim().isEmpty) {
      throw ArgumentError('ユーザーIDは必須です');
    }

    try {
      // 自分の投稿へのいいね防止
      final tweet = await _dataSource.getTweetById(tweetId);
      if (tweet == null) {
        return false; // ツイートが存在しない
      }

      if (tweet.userId == userId) {
        throw ArgumentError('自分の投稿にはいいねできません');
      }

      return await _dataSource.likeTweet(tweetId, userId);
    } catch (e) {
      rethrow;
    }
  }

  /// ツイートのいいね削除
  /// 
  /// [tweetId] いいね削除対象のツイートID
  /// [userId] いいね削除実行者のユーザーID
  /// 
  /// 返り値:
  /// [bool] いいね削除成功時はtrue、失敗時はfalse
  /// 
  /// ビジネスルール:
  /// - いいね済みの投稿のみいいね削除可能
  @override
  Future<bool> unlikeTweet(int tweetId, String userId) async {
    if (tweetId <= 0) {
      throw ArgumentError('ツイートIDは正の整数で指定してください');
    }

    if (userId.trim().isEmpty) {
      throw ArgumentError('ユーザーIDは必須です');
    }

    try {
      return await _dataSource.unlikeTweet(tweetId, userId);
    } catch (e) {
      rethrow;
    }
  }
}