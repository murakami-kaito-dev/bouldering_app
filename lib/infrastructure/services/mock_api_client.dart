import 'dart:async';
import 'dart:math';
import '../../shared/data/mock_data.dart';

/// APIクライアントのモック実装
/// 
/// 役割:
/// - サーバーサイドAPIのレスポンスをシミュレート
/// - ユーザー、ジム、投稿データの取得・更新処理をモック
/// - ネットワーク遅延とエラーケースのシミュレーション
class MockApiClient {
  static final MockApiClient _instance = MockApiClient._internal();
  factory MockApiClient() => _instance;
  MockApiClient._internal();

  final Duration _baseDelay = const Duration(milliseconds: 300);
  final Random _random = Random();

  /// ネットワーク遅延をシミュレート
  Future<void> _simulateNetworkDelay() async {
    final delay = _baseDelay + Duration(milliseconds: _random.nextInt(500));
    await Future.delayed(delay);
  }

  /// ランダムなネットワークエラーをシミュレート（5%の確率）
  void _simulateNetworkError() {
    if (_random.nextInt(100) < 5) {
      throw MockApiException(
        'ネットワークエラーが発生しました',
        statusCode: 500,
      );
    }
  }

  /// GETリクエストのモック実装
  /// 
  /// [requestId] リクエストID（APIの種類を識別）
  /// [parameters] クエリパラメータ
  /// 
  /// リクエストIDの定義:
  /// - 1: ユーザー情報取得
  /// - 2: ジム一覧取得
  /// - 3: 投稿一覧取得
  /// - 4: ユーザーの投稿取得
  /// - 5: ジムの投稿取得
  /// - 10: ジム検索
  Future<Map<String, dynamic>> get({
    required int requestId,
    Map<String, String>? parameters,
  }) async {
    await _simulateNetworkDelay();
    _simulateNetworkError();

    switch (requestId) {
      case 1: // ユーザー情報取得
        return _getUserInfo(parameters);
      case 2: // ジム一覧取得
        return _getGyms(parameters);
      case 3: // 投稿一覧取得
        return _getTweets(parameters);
      case 4: // ユーザーの投稿取得
        return _getUserTweets(parameters);
      case 5: // ジムの投稿取得
        return _getGymTweets(parameters);
      case 10: // ジム検索
        return _searchGyms(parameters);
      default:
        throw MockApiException(
          '不明なリクエストIDです: $requestId',
          statusCode: 400,
        );
    }
  }

  /// POSTリクエストのモック実装
  /// 
  /// [requestId] リクエストID（APIの種類を識別）
  /// [body] リクエストボディ
  /// [parameters] クエリパラメータ
  /// 
  /// リクエストIDの定義:
  /// - 101: ユーザー登録
  /// - 102: ユーザー情報更新
  /// - 103: 投稿作成
  /// - 104: 投稿削除
  /// - 105: いいね追加/削除
  Future<Map<String, dynamic>> post({
    required int requestId,
    Map<String, dynamic>? body,
    Map<String, String>? parameters,
  }) async {
    await _simulateNetworkDelay();
    _simulateNetworkError();

    switch (requestId) {
      case 101: // ユーザー登録
        return _createUser(body);
      case 102: // ユーザー情報更新
        return _updateUser(body);
      case 103: // 投稿作成
        return _createTweet(body);
      case 104: // 投稿削除
        return _deleteTweet(body);
      case 105: // いいね追加/削除
        return _toggleLike(body);
      default:
        throw MockApiException(
          '不明なリクエストIDです: $requestId',
          statusCode: 400,
        );
    }
  }

  /// ユーザー情報取得
  Map<String, dynamic> _getUserInfo(Map<String, String>? parameters) {
    final userId = parameters?['user_id'];
    if (userId == null) {
      throw MockApiException('user_idパラメータが必要です', statusCode: 400);
    }

    final user = MockData.mockUsers[userId];
    if (user == null) {
      throw MockApiException('ユーザーが見つかりません', statusCode: 404);
    }

    return {
      'status': 'success',
      'data': {
        'id': user.id,
        'userName': user.userName,
        'email': user.email,
        'userIconUrl': user.userIconUrl,
        'userIntroduce': user.userIntroduce,
        'favoriteGym': user.favoriteGym,
        'gender': user.gender,
        'birthday': user.birthday?.toIso8601String(),
        'boulStartDate': user.boulStartDate?.toIso8601String(),
        'homeGymId': user.homeGymId,
      },
    };
  }

  /// ジム一覧取得
  Map<String, dynamic> _getGyms(Map<String, String>? parameters) {
    final limit = int.tryParse(parameters?['limit'] ?? '10') ?? 10;
    final offset = int.tryParse(parameters?['offset'] ?? '0') ?? 0;

    final allGyms = MockData.mockGyms.values.toList();
    final pagedGyms = allGyms.skip(offset).take(limit).map((gym) => {
      'id': gym.id,
      'name': gym.name,
      'hpLink': gym.hpLink,
      'prefecture': gym.prefecture,
      'city': gym.city,
      'addressLine': gym.addressLine,
      'latitude': gym.latitude,
      'longitude': gym.longitude,
      'telNo': gym.telNo,
      'fee': gym.fee,
      'minimumFee': gym.minimumFee,
      'equipmentRentalFee': gym.equipmentRentalFee,
      'ikitaiCount': gym.ikitaiCount,
      'boulCount': gym.boulCount,
      'isBoulderingGym': gym.isBoulderingGym,
      'isLeadGym': gym.isLeadGym,
      'isSpeedGym': gym.isSpeedGym,
      'photoUrls': gym.photoUrls,
    }).toList();

    return {
      'status': 'success',
      'data': pagedGyms,
      'pagination': {
        'total': allGyms.length,
        'limit': limit,
        'offset': offset,
        'hasMore': (offset + limit) < allGyms.length,
      },
    };
  }

  /// 投稿一覧取得
  Map<String, dynamic> _getTweets(Map<String, String>? parameters) {
    final limit = int.tryParse(parameters?['limit'] ?? '20') ?? 20;
    final offset = int.tryParse(parameters?['offset'] ?? '0') ?? 0;

    final allTweets = MockData.mockTweets;
    final pagedTweets = allTweets.skip(offset).take(limit).map((tweet) => {
      'id': tweet.id,
      'userId': tweet.userId,
      'userName': tweet.userName,
      'userIconUrl': tweet.userIconUrl,
      'gymId': tweet.gymId,
      'gymName': tweet.gymName,
      'prefecture': tweet.prefecture,
      'content': tweet.content,
      'visitedDate': tweet.visitedDate.toIso8601String(),
      'tweetedDate': tweet.tweetedDate.toIso8601String(),
      'likedCount': tweet.likedCount,
      'movieUrl': tweet.movieUrl,
      'mediaUrls': tweet.mediaUrls,
    }).toList();

    return {
      'status': 'success',
      'data': pagedTweets,
      'pagination': {
        'total': allTweets.length,
        'limit': limit,
        'offset': offset,
        'hasMore': (offset + limit) < allTweets.length,
      },
    };
  }

  /// ユーザーの投稿取得
  Map<String, dynamic> _getUserTweets(Map<String, String>? parameters) {
    final userId = parameters?['user_id'];
    if (userId == null) {
      throw MockApiException('user_idパラメータが必要です', statusCode: 400);
    }

    final userTweets = MockData.getTweetsByUserId(userId);
    final tweetData = userTweets.map((tweet) => {
      'id': tweet.id,
      'userId': tweet.userId,
      'userName': tweet.userName,
      'userIconUrl': tweet.userIconUrl,
      'gymId': tweet.gymId,
      'gymName': tweet.gymName,
      'prefecture': tweet.prefecture,
      'content': tweet.content,
      'visitedDate': tweet.visitedDate.toIso8601String(),
      'tweetedDate': tweet.tweetedDate.toIso8601String(),
      'likedCount': tweet.likedCount,
      'movieUrl': tweet.movieUrl,
      'mediaUrls': tweet.mediaUrls,
    }).toList();

    return {
      'status': 'success',
      'data': tweetData,
    };
  }

  /// ジムの投稿取得
  Map<String, dynamic> _getGymTweets(Map<String, String>? parameters) {
    final gymIdStr = parameters?['gym_id'];
    if (gymIdStr == null) {
      throw MockApiException('gym_idパラメータが必要です', statusCode: 400);
    }

    final gymId = int.tryParse(gymIdStr);
    if (gymId == null) {
      throw MockApiException('無効なgym_idです', statusCode: 400);
    }

    final gymTweets = MockData.getTweetsByGymId(gymId);
    final tweetData = gymTweets.map((tweet) => {
      'id': tweet.id,
      'userId': tweet.userId,
      'userName': tweet.userName,
      'userIconUrl': tweet.userIconUrl,
      'gymId': tweet.gymId,
      'gymName': tweet.gymName,
      'prefecture': tweet.prefecture,
      'content': tweet.content,
      'visitedDate': tweet.visitedDate.toIso8601String(),
      'tweetedDate': tweet.tweetedDate.toIso8601String(),
      'likedCount': tweet.likedCount,
      'movieUrl': tweet.movieUrl,
      'mediaUrls': tweet.mediaUrls,
    }).toList();

    return {
      'status': 'success',
      'data': tweetData,
    };
  }

  /// ジム検索
  Map<String, dynamic> _searchGyms(Map<String, String>? parameters) {
    final query = parameters?['query'] ?? '';
    final searchResults = MockData.searchGyms(query);
    
    final gymData = searchResults.map((gym) => {
      'id': gym.id,
      'name': gym.name,
      'hpLink': gym.hpLink,
      'prefecture': gym.prefecture,
      'city': gym.city,
      'addressLine': gym.addressLine,
      'latitude': gym.latitude,
      'longitude': gym.longitude,
      'telNo': gym.telNo,
      'fee': gym.fee,
      'minimumFee': gym.minimumFee,
      'equipmentRentalFee': gym.equipmentRentalFee,
      'ikitaiCount': gym.ikitaiCount,
      'boulCount': gym.boulCount,
      'isBoulderingGym': gym.isBoulderingGym,
      'isLeadGym': gym.isLeadGym,
      'isSpeedGym': gym.isSpeedGym,
      'photoUrls': gym.photoUrls,
    }).toList();

    return {
      'status': 'success',
      'data': gymData,
      'query': query,
    };
  }

  /// ユーザー登録
  Map<String, dynamic> _createUser(Map<String, dynamic>? body) {
    if (body == null) {
      throw MockApiException('リクエストボディが必要です', statusCode: 400);
    }

    final userId = body['userId'] as String?;
    final email = body['email'] as String?;

    if (userId == null || email == null) {
      throw MockApiException('userIdとemailが必要です', statusCode: 400);
    }

    final success = MockData.createUser(userId, email);
    if (!success) {
      throw MockApiException('ユーザーの作成に失敗しました', statusCode: 409);
    }

    return {
      'status': 'success',
      'message': 'ユーザーが作成されました',
      'data': {'userId': userId},
    };
  }

  /// ユーザー情報更新
  Map<String, dynamic> _updateUser(Map<String, dynamic>? body) {
    if (body == null) {
      throw MockApiException('リクエストボディが必要です', statusCode: 400);
    }

    final userId = body['userId'] as String?;
    if (userId == null) {
      throw MockApiException('userIdが必要です', statusCode: 400);
    }

    final user = MockData.mockUsers[userId];
    if (user == null) {
      throw MockApiException('ユーザーが見つかりません', statusCode: 404);
    }

    // ここでは更新成功として扱う（実際の実装では更新処理を行う）
    return {
      'status': 'success',
      'message': 'ユーザー情報が更新されました',
    };
  }

  /// 投稿作成
  Map<String, dynamic> _createTweet(Map<String, dynamic>? body) {
    if (body == null) {
      throw MockApiException('リクエストボディが必要です', statusCode: 400);
    }

    final userId = body['userId'] as String?;
    final gymId = body['gymId'] as int?;
    final content = body['content'] as String?;
    final visitedDate = body['visitedDate'] as String?;
    final mediaUrls = (body['mediaUrls'] as List?)?.cast<String>() ?? <String>[];

    if (userId == null || gymId == null || content == null || visitedDate == null) {
      throw MockApiException('必要なパラメータが不足しています', statusCode: 400);
    }

    final visitedDateTime = DateTime.tryParse(visitedDate);
    if (visitedDateTime == null) {
      throw MockApiException('無効な訪問日時です', statusCode: 400);
    }

    try {
      final newTweetId = MockData.addTweet(
        userId: userId,
        gymId: gymId,
        content: content,
        visitedDate: visitedDateTime,
        mediaUrls: mediaUrls,
      );

      return {
        'status': 'success',
        'message': '投稿が作成されました',
        'data': {'tweetId': newTweetId},
      };
    } catch (e) {
      throw MockApiException('投稿の作成に失敗しました: $e', statusCode: 500);
    }
  }

  /// 投稿削除
  Map<String, dynamic> _deleteTweet(Map<String, dynamic>? body) {
    if (body == null) {
      throw MockApiException('リクエストボディが必要です', statusCode: 400);
    }

    final tweetId = body['tweetId'] as int?;
    final userId = body['userId'] as String?;

    if (tweetId == null || userId == null) {
      throw MockApiException('tweetIdとuserIdが必要です', statusCode: 400);
    }

    // ここでは削除成功として扱う（実際の実装では削除処理を行う）
    return {
      'status': 'success',
      'message': '投稿が削除されました',
    };
  }

  /// いいね追加/削除
  Map<String, dynamic> _toggleLike(Map<String, dynamic>? body) {
    if (body == null) {
      throw MockApiException('リクエストボディが必要です', statusCode: 400);
    }

    final tweetId = body['tweetId'] as int?;
    final userId = body['userId'] as String?;
    final isLiked = body['isLiked'] as bool? ?? false;

    if (tweetId == null || userId == null) {
      throw MockApiException('tweetIdとuserIdが必要です', statusCode: 400);
    }

    // ここではいいね切り替え成功として扱う
    return {
      'status': 'success',
      'message': isLiked ? 'いいねを追加しました' : 'いいねを削除しました',
      'data': {'isLiked': isLiked},
    };
  }
}

/// APIの例外クラス（Mock用）
class MockApiException implements Exception {
  final String message;
  final int? statusCode;

  MockApiException(this.message, {this.statusCode});

  @override
  String toString() => 'MockApiException: $message';
}

/// APIエラーコード定数
class MockApiErrorCodes {
  static const String invalidRequestId = 'invalid-request-id';
  static const String missingParameters = 'missing-parameters';
  static const String userNotFound = 'user-not-found';
  static const String gymNotFound = 'gym-not-found';
  static const String tweetNotFound = 'tweet-not-found';
  static const String networkError = 'network-error';
  static const String serverError = 'server-error';
  static const String unauthorized = 'unauthorized';
  static const String forbidden = 'forbidden';
}