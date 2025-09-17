class Tweet {
  final int id;
  final String userId;
  final String userName;
  final String userIconUrl;
  final DateTime visitedDate;
  final DateTime tweetedDate;
  final int gymId;
  final String content;
  final int likedCount;
  final String? movieUrl;
  final String gymName;
  final String prefecture;
  final List<String> mediaUrls;

  const Tweet({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userIconUrl,
    required this.visitedDate,
    required this.tweetedDate,
    required this.gymId,
    required this.content,
    required this.likedCount,
    this.movieUrl,
    required this.gymName,
    required this.prefecture,
    this.mediaUrls = const [],
  });

  bool get hasMedia => mediaUrls.isNotEmpty;
  bool get hasMovie => movieUrl != null && movieUrl!.isNotEmpty;
  
  Duration get timeSincePosted => DateTime.now().difference(tweetedDate);
  
  String get timeAgoDisplay {
    final duration = timeSincePosted;
    if (duration.inDays > 0) {
      return '${duration.inDays}日前';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}時間前';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}分前';
    } else {
      return 'たった今';
    }
  }

  String get formattedCreatedAt {
    return '${tweetedDate.year}年${tweetedDate.month}月${tweetedDate.day}日 ${tweetedDate.hour.toString().padLeft(2, '0')}:${tweetedDate.minute.toString().padLeft(2, '0')}';
  }

  Tweet copyWith({
    int? id,
    String? userId,
    String? userName,
    String? userIconUrl,
    DateTime? visitedDate,
    DateTime? tweetedDate,
    int? gymId,
    String? content,
    int? likedCount,
    String? movieUrl,
    String? gymName,
    String? prefecture,
    List<String>? mediaUrls,
  }) {
    return Tweet(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userIconUrl: userIconUrl ?? this.userIconUrl,
      visitedDate: visitedDate ?? this.visitedDate,
      tweetedDate: tweetedDate ?? this.tweetedDate,
      gymId: gymId ?? this.gymId,
      content: content ?? this.content,
      likedCount: likedCount ?? this.likedCount,
      movieUrl: movieUrl ?? this.movieUrl,
      gymName: gymName ?? this.gymName,
      prefecture: prefecture ?? this.prefecture,
      mediaUrls: mediaUrls ?? this.mediaUrls,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Tweet &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  /// JSONからTweetインスタンスを作成
  /// 
  /// API連携用のファクトリコンストラクタ
  factory Tweet.fromJson(Map<String, dynamic> json) {
    return Tweet(
      id: json['tweet_id'] ?? json['id'] ?? 0,
      userId: json['user_id'] ?? '',
      userName: json['user_name'] ?? '',
      userIconUrl: json['user_icon_url'] ?? '',
      visitedDate: DateTime.tryParse(json['visited_date'] ?? '') ?? DateTime(1990, 1, 1),
      tweetedDate: DateTime.tryParse(json['tweeted_date'] ?? '') ?? DateTime(1990, 1, 1),
      gymId: json['gym_id'] ?? 0,
      content: json['tweet_contents'] ?? json['content'] ?? '',
      likedCount: json['liked_counts'] ?? json['liked_count'] ?? 0,
      movieUrl: json['movie_url'],
      gymName: json['gym_name'] ?? '',
      prefecture: json['prefecture'] ?? '',
      mediaUrls: List<String>.from(json['media_urls'] ?? []),
    );
  }

  /// JSONに変換
  /// 
  /// API送信用のメソッド
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'user_icon_url': userIconUrl,
      'visited_date': visitedDate.toIso8601String(),
      'tweeted_date': tweetedDate.toIso8601String(),
      'gym_id': gymId,
      'content': content,
      'liked_count': likedCount,
      'movie_url': movieUrl,
      'gym_name': gymName,
      'prefecture': prefecture,
      'media_urls': mediaUrls,
    };
  }
}