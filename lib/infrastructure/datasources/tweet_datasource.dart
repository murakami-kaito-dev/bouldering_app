import 'dart:io';
import '../services/api_client.dart';
import '../services/storage_service.dart';
import '../../domain/entities/tweet.dart';

/// ツイートデータソースクラス
/// 
/// 役割:
/// - ツイート関連のAPI通信を担当
/// - APIレスポンスとDomainエンティティ間の変換
/// - ツイート投稿、取得、削除処理
/// 
/// クリーンアーキテクチャにおける位置づけ:
/// - Infrastructure層のデータソースコンポーネント
/// - 外部API（ツイートAPI）との通信窓口
/// - Repository実装から呼び出される
class TweetDataSource {
  final ApiClient _apiClient;
  final StorageService _storageService;

  /// コンストラクタ
  /// 
  /// [_apiClient] API通信クライアント
  /// [_storageService] ファイルストレージサービス
  TweetDataSource(this._apiClient, this._storageService);

  /// 全ツイート取得
  /// 
  /// [limit] 取得件数の上限
  /// [cursor] ページネーション用のカーソル（前回取得の最後のツイートの投稿日時）
  /// 
  /// 返り値:
  /// [List<Tweet>] ツイートリスト
  /// 
  /// 処理フロー:
  /// 1. REST API: GET /api/tweets?limit={limit}&cursor={cursor} で全ツイート取得
  /// 2. カーソルベースページネーションによる無限スクロール対応
  /// 3. APIエラー時は例外を上位に伝播
  Future<List<Tweet>> getAllTweets({int limit = 20, String? cursor}) async {
    try {
      print('TweetDataSource: getAllTweets呼び出し');
      print('Cursor: ${cursor ?? "初回取得"}');
      
      final parameters = <String, String>{
        'limit': limit.toString(),
      };
      
      // カーソルがある場合のみcursorパラメータを追加（初回はcursor無しで最新取得）
      if (cursor != null && cursor.isNotEmpty) {
        parameters['cursor'] = cursor;
      }

      final response = await _apiClient.get(
        endpoint: '/tweets',
        parameters: parameters,
      );
      
      print('取得したツイート数: ${(response['data'] as List).length}');

      final List<dynamic> tweetData = response['data'] ?? [];
      return tweetData.map((item) => _mapToTweetEntity(item)).toList();
    } catch (e) {
      throw Exception('ツイート取得に失敗しました: $e');
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
  /// 処理フロー:
  /// 1. REST API: GET /api/users/{userId}/tweets?limit={limit}&offset={offset} でユーザーツイート取得
  /// 2. APIエラー時は例外を上位に伝播
  Future<List<Tweet>> getTweetsByUserId(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      // cursorは初回取得時（offset=0）は送信せず、ページネーション時のみ使用
      final parameters = <String, String>{
        'limit': limit.toString(),
      };
      
      // offsetが0より大きい場合のみcursorパラメータを追加
      // 実際のカーソル値はバックエンドのレスポンスから取得する必要がある
      if (offset > 0) {
        // TODO: 実際のカーソル値を使用する実装が必要
        // 現在は簡易実装として省略
      }

      final response = await _apiClient.get(
        endpoint: '/tweets/users/$userId',
        parameters: parameters,
        requireAuth: false,  // This is a public endpoint
      );

      final List<dynamic> tweetData = response['data'] ?? [];
      return tweetData.map((item) => _mapToTweetEntity(item)).toList();
    } catch (e) {
      throw Exception('ユーザーツイート取得に失敗しました: $e');
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
  /// 処理フロー:
  /// 1. REST API: GET /api/gyms/{gymId}/tweets?limit={limit}&offset={offset} でジムツイート取得
  /// 2. APIエラー時は例外を上位に伝播
  Future<List<Tweet>> getTweetsByGymId(
    int gymId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _apiClient.get(
        endpoint: '/gyms/$gymId/tweets',
        parameters: {
          'limit': limit.toString(),
          'offset': offset.toString(),
        },
      );

      final List<dynamic> tweetData = response['data'] ?? [];
      return tweetData.map((item) => _mapToTweetEntity(item)).toList();
    } catch (e) {
      throw Exception('ジムツイート取得に失敗しました: $e');
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
  /// 処理フロー:
  /// 1. REST API: GET /api/users/{userId}/favorites/users/tweets?limit={limit}&cursor={cursor} でお気に入りツイート取得
  /// 2. カーソルベースページネーションによる無限スクロール対応
  /// 3. APIエラー時は例外を上位に伝播
  Future<List<Tweet>> getFavoriteTweets(
    String userId, {
    int limit = 20,
    String? cursor,
  }) async {
    try {
      final parameters = <String, String>{
        'limit': limit.toString(),
      };
      
      // カーソルがある場合のみcursorパラメータを追加（初回はcursor無しで最新取得）
      if (cursor != null && cursor.isNotEmpty) {
        parameters['cursor'] = cursor;
      }

      final response = await _apiClient.get(
        endpoint: '/users/$userId/favorites/users/tweets',
        parameters: parameters,
        requireAuth: true,  // 認証が必要
      );

      final List<dynamic> tweetData = response['data'] ?? [];
      return tweetData.map((item) => _mapToTweetEntity(item)).toList();
    } catch (e) {
      throw Exception('お気に入りツイート取得に失敗しました: $e');
    }
  }

  /// ツイート詳細取得
  /// 
  /// [tweetId] ツイートID
  /// 
  /// 返り値:
  /// [Tweet?] ツイートエンティティ、存在しない場合はnull
  /// 
  /// 処理フロー:
  /// 1. REST API: GET /api/tweets/{tweetId} でツイート詳細取得
  /// 2. APIエラー時は例外を上位に伝播
  Future<Tweet?> getTweetById(int tweetId) async {
    try {
      final response = await _apiClient.get(
        endpoint: '/tweets/$tweetId',
      );

      final tweetData = response['data'];
      if (tweetData == null) return null;

      return _mapToTweetEntity(tweetData);
    } catch (e) {
      throw Exception('ツイート詳細取得に失敗しました: $e');
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
  /// 処理フロー:
  /// 1. REST API: POST /api/tweets でツイート投稿
  /// 2. APIエラー時は例外を上位に伝播
  Future<bool> createTweet({
    required String userId,
    required int gymId,
    required String content,
    required DateTime visitedDate,
    required String postUuid,
    String? movieUrl,
    List<Map<String, String>>? mediaData,
  }) async {
    try {
      final Map<String, dynamic> tweetData = {
        'user_id': userId,
        'gym_id': gymId,
        'tweet_contents': content,
        'visited_date': _formatDate(visitedDate),
        'post_uuid': postUuid,
      };
      
      if (movieUrl != null) {
        tweetData['movie_url'] = movieUrl;
      }
      
      // mediaDataから各情報を抽出してサーバーに送信
      if (mediaData != null && mediaData.isNotEmpty) {
        // URLのリストと拡張メディア情報を送信
        tweetData['media_urls'] = mediaData.map((data) => data['url']).toList();
        
        final metadata = mediaData.map((data) => {
          'asset_uuid': data['assetUuid'] ?? '',
          'storage_prefix': data['storagePrefix'] ?? '',
          'mime_type': data['mimeType'] ?? '',
        }).toList();
        
        tweetData['media_metadata'] = metadata;
      }

      final response = await _apiClient.post(
        endpoint: '/tweets',
        body: tweetData,
      );

      return response['success'] == true;
    } catch (e) {
      throw Exception('ツイート投稿に失敗しました: $e');
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
  /// 処理フロー:
  /// 1. REST API: PATCH /api/tweets/{tweetId} でツイート更新
  /// 2. APIエラー時は例外を上位に伝播
  Future<bool> updateTweet({
    required int tweetId,
    required String userId,
    required int gymId,
    required String content,
    required DateTime visitedDate,
    String? movieUrl,
    List<String>? mediaUrls,
  }) async {
    try {
      final Map<String, dynamic> tweetData = {
        'user_id': userId,
        'gym_id': gymId,
        'tweet_contents': content,
        'visited_date': _formatDate(visitedDate),
      };
      
      if (movieUrl != null) {
        tweetData['movie_url'] = movieUrl;
      }
      
      if (mediaUrls != null && mediaUrls.isNotEmpty) {
        tweetData['media_urls'] = mediaUrls;
      }

      final response = await _apiClient.patch(
        endpoint: '/tweets/$tweetId',
        body: tweetData,
      );

      return response['success'] == true;
    } catch (e) {
      throw Exception('ツイート更新に失敗しました: $e');
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
  /// 処理フロー:
  /// 1. REST API: DELETE /api/tweets/{tweetId} で認証付きツイート削除
  /// 2. APIエラー時は例外を上位に伝播
  Future<bool> deleteTweet(int tweetId, String userId) async {
    try {
      await _apiClient.delete(
        endpoint: '/tweets/$tweetId',
        requireAuth: true,  // 認証が必要
      );

      // バックエンドは204 No Contentを返すため、例外が発生しなければ成功
      return true;
    } catch (e) {
      throw Exception('ツイート削除に失敗しました: $e');
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
  /// 処理フロー:
  /// 1. REST API: POST /api/tweets/{tweetId}/likes でいいね追加
  /// 2. APIエラー時は例外を上位に伝播
  Future<bool> likeTweet(int tweetId, String userId) async {
    try {
      final response = await _apiClient.post(
        endpoint: '/tweets/$tweetId/likes',
        body: {'user_id': userId},
      );

      return response['success'] == true;
    } catch (e) {
      throw Exception('いいね追加に失敗しました: $e');
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
  /// 処理フロー:
  /// 1. REST API: DELETE /api/tweets/{tweetId}/likes?user_id={userId} でいいね削除
  /// 2. APIエラー時は例外を上位に伝播
  Future<bool> unlikeTweet(int tweetId, String userId) async {
    try {
      final response = await _apiClient.delete(
        endpoint: '/tweets/$tweetId/likes',
        parameters: {'user_id': userId},
      );

      return response['success'] == true;
    } catch (e) {
      throw Exception('いいね削除に失敗しました: $e');
    }
  }

  /// 投稿メディアファイルアップロード
  /// 
  /// [mediaPath] アップロードするメディアファイルのパス
  /// [mediaType] メディアタイプ（'image', 'video'）
  /// [userId] ユーザーID
  /// [postUuid] 投稿UUID（クライアント側で生成済み）
  /// 
  /// 返り値:
  /// [Map<String, String>?] アップロード成功時は画像情報、失敗時はnull
  Future<Map<String, String>?> uploadPostMedia(String mediaPath, String mediaType, {required String userId, required String postUuid}) async {
    try {
      final mediaFile = File(mediaPath);
      return await _storageService.uploadPostMedia(mediaFile, mediaType, userId: userId, postUuid: postUuid);
    } catch (e) {
      throw Exception('メディアアップロードに失敗しました: $e');
    }
  }

  /// APIレスポンスからTweetエンティティにマッピング
  /// 
  /// [tweetData] APIから取得したツイートデータ
  /// 
  /// 返り値:
  /// [Tweet] ツイートエンティティ
  Tweet _mapToTweetEntity(Map<String, dynamic> tweetData) {
    return Tweet(
      id: tweetData['tweet_id'] ?? 0,
      userId: tweetData['user_id']?.toString() ?? '',
      userName: tweetData['user_name'] ?? '',
      userIconUrl: tweetData['user_icon_url'] ?? '',
      visitedDate: DateTime.tryParse(tweetData['visited_date'] ?? '') ?? 
          DateTime(1990, 1, 1),
      tweetedDate: DateTime.tryParse(tweetData['tweeted_date'] ?? '') ?? 
          DateTime(1990, 1, 1),
      gymId: tweetData['gym_id'] ?? 0,
      content: tweetData['tweet_contents'] ?? '',
      likedCount: tweetData['liked_counts'] ?? 0,
      movieUrl: tweetData['movie_url'],
      gymName: tweetData['gym_name'] ?? '',
      prefecture: tweetData['prefecture'] ?? '',
      mediaUrls: _parseMediaUrls(tweetData['media_urls']),
    );
  }

  /// メディアURLリストをパース
  /// 
  /// [mediaData] メディアURLデータ
  /// 
  /// 返り値:
  /// [List<String>] メディアURLリスト
  List<String> _parseMediaUrls(dynamic mediaData) {
    if (mediaData == null) return [];
    
    if (mediaData is List) {
      return mediaData.map((url) => url.toString()).toList();
    }
    
    if (mediaData is String && mediaData.isNotEmpty) {
      // カンマ区切りの文字列の場合
      return mediaData.split(',').map((url) => url.trim()).toList();
    }
    
    return [];
  }

  /// 日付をAPIで使用する形式にフォーマット
  /// 
  /// [date] フォーマット対象の日付
  /// 
  /// 返り値:
  /// [String] YYYY-MM-DD形式の日付文字列
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}