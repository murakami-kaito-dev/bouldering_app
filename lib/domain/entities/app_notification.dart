/// 通知の種別（バックエンドの notifications.type と対応）
enum AppNotificationType {
  like,
  comment,
  reply;

  static AppNotificationType fromString(String? value) {
    switch (value) {
      case 'comment':
        return AppNotificationType.comment;
      case 'reply':
        return AppNotificationType.reply;
      case 'like':
      default:
        return AppNotificationType.like;
    }
  }
}

/// 通知のアクター（いいね・コメントをした人）。集約時は最大 6 人まで
class NotificationActor {
  final String userId;
  final String userName;
  final String? userIconUrl;

  const NotificationActor({
    required this.userId,
    required this.userName,
    this.userIconUrl,
  });

  factory NotificationActor.fromJson(Map<String, dynamic> json) {
    return NotificationActor(
      userId: json['user_id']?.toString() ?? '',
      userName: json['user_name'] ?? '',
      userIconUrl: json['user_icon_url'],
    );
  }
}

/// アプリ内通知エンティティ（Issue #81）
///
/// バックエンドの `GET /users/:id/notifications` の 1 要素に対応する。
/// いいねは同じツイートへのものが 1 行に集約されて届く（`actors` は先頭 6 人、`actorCount` が総数）。
/// Flutter の `Notification` クラスと名前が衝突するため `AppNotification` とする
class AppNotification {
  /// 代表行の ID（既読化の up_to_id にも使う）
  final int id;
  final AppNotificationType type;
  final List<NotificationActor> actors;
  final int actorCount;

  /// 対象ツイート（削除済みなら null）
  final int? tweetId;
  final String? gymName;

  /// ツイート本文の冒頭（40 字）
  final String tweetContentHead;

  /// コメント・返信の対象コメント（いいねでは null）
  final int? commentId;

  /// コメント本文の冒頭（40 字。削除済みは空）
  final String commentContentHead;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.actors,
    required this.actorCount,
    this.tweetId,
    this.gymName,
    required this.tweetContentHead,
    this.commentId,
    required this.commentContentHead,
    required this.isRead,
    required this.createdAt,
  });

  /// 先頭のアクター（表示の主語）
  NotificationActor? get primaryActor => actors.isNotEmpty ? actors.first : null;

  /// 「A さんと他 N 名があなたのボル活をいいねしました」形式の一文
  String get sentence {
    final name = primaryActor?.userName ?? '誰か';
    final others = actorCount - 1;
    final subject = others > 0 ? '$name さんと他 $others 名' : '$name さん';
    switch (type) {
      case AppNotificationType.like:
        return '$subjectがあなたのボル活をいいねしました';
      case AppNotificationType.comment:
        return '$subjectがコメントしました';
      case AppNotificationType.reply:
        return '$subjectが返信しました';
    }
  }

  /// 引用として見せる本文（コメント・返信ならコメント本文、いいねなら投稿本文）
  String get quotedText {
    if (type != AppNotificationType.like && commentContentHead.isNotEmpty) {
      return commentContentHead;
    }
    return tweetContentHead;
  }

  /// 「3分前」形式の経過時間（Comment.timeAgoDisplay と同じ規則。7 日を超えたら日付）
  String get timeAgoDisplay {
    final duration = DateTime.now().difference(createdAt);
    if (duration.inDays >= 7) {
      final local = createdAt.toLocal();
      return '${local.month}/${local.day}';
    } else if (duration.inDays > 0) {
      return '${duration.inDays}日前';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}時間前';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}分前';
    }
    return 'たった今';
  }

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      type: type,
      actors: actors,
      actorCount: actorCount,
      tweetId: tweetId,
      gymName: gymName,
      tweetContentHead: tweetContentHead,
      commentId: commentId,
      commentContentHead: commentContentHead,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }

  /// API レスポンス（snake_case）から生成
  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final tweet = json['tweet'];
    final comment = json['comment'];
    final actorsJson = json['actors'];
    return AppNotification(
      id: json['notification_id'] is int
          ? json['notification_id']
          : int.tryParse('${json['notification_id']}') ?? 0,
      type: AppNotificationType.fromString(json['type']?.toString()),
      actors: actorsJson is List
          ? actorsJson
              .map((a) => NotificationActor.fromJson(a as Map<String, dynamic>))
              .toList()
          : const [],
      actorCount: json['actor_count'] ?? 1,
      tweetId: tweet is Map ? tweet['tweet_id'] : null,
      gymName: tweet is Map ? tweet['gym_name'] : null,
      tweetContentHead: tweet is Map ? (tweet['content_head'] ?? '') : '',
      commentId: comment is Map ? comment['comment_id'] : null,
      commentContentHead: comment is Map ? (comment['content_head'] ?? '') : '',
      isRead: json['is_read'] == true,
      createdAt: DateTime.tryParse(json['created_at'] ?? '')?.toLocal() ??
          DateTime(1990, 1, 1),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppNotification &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
