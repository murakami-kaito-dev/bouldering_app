/// コメント（スレッド）エンティティ
///
/// バックエンドの `GET /tweets/:id/comments` の 1 要素に対応する。
/// 表示は 2 段（ルート → 返信）に畳む: `rootCommentId` が null ならルート、
/// それ以外はそのルートの下に 1 段インデントして並べる。
/// 返信先が別の返信（`parentCommentId != rootCommentId`）なら本文頭に「@名前 さん」を付ける。
class Comment {
  final int id;
  final int tweetId;
  final String userId;
  final String userName;
  final String? userIconUrl;
  final int? parentCommentId;
  final int? rootCommentId;
  final String? replyToUserId;
  final String? replyToUserName;

  /// 本文（削除済みは空文字）
  final String content;

  /// 論理削除済みか（プレースホルダ表示の判定に使う）
  final bool isDeleted;
  final DateTime createdAt;

  const Comment({
    required this.id,
    required this.tweetId,
    required this.userId,
    required this.userName,
    this.userIconUrl,
    this.parentCommentId,
    this.rootCommentId,
    this.replyToUserId,
    this.replyToUserName,
    required this.content,
    required this.isDeleted,
    required this.createdAt,
  });

  /// ルートコメント（スレッドの起点）か
  bool get isRoot => rootCommentId == null;

  /// 「返信への返信」か（ルート直下でなければ @名前 を付けて表示する）
  bool get isReplyToReply =>
      parentCommentId != null &&
      rootCommentId != null &&
      parentCommentId != rootCommentId;

  /// 「3分前」形式の経過時間
  String get timeAgoDisplay {
    final duration = DateTime.now().difference(createdAt);
    if (duration.inDays > 0) {
      return '${duration.inDays}日前';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}時間前';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}分前';
    }
    return 'たった今';
  }

  Comment copyWith({
    String? content,
    bool? isDeleted,
  }) {
    return Comment(
      id: id,
      tweetId: tweetId,
      userId: userId,
      userName: userName,
      userIconUrl: userIconUrl,
      parentCommentId: parentCommentId,
      rootCommentId: rootCommentId,
      replyToUserId: replyToUserId,
      replyToUserName: replyToUserName,
      content: content ?? this.content,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt,
    );
  }

  /// API レスポンス（snake_case）から生成
  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['comment_id'] ?? 0,
      tweetId: json['tweet_id'] ?? 0,
      userId: json['user_id']?.toString() ?? '',
      userName: json['user_name'] ?? '',
      userIconUrl: json['user_icon_url'],
      parentCommentId: json['parent_comment_id'],
      rootCommentId: json['root_comment_id'],
      replyToUserId: json['reply_to_user_id'],
      replyToUserName: json['reply_to_user_name'],
      content: json['content'] ?? '',
      isDeleted: json['is_deleted'] == true,
      createdAt: DateTime.tryParse(json['created_at'] ?? '')?.toLocal() ??
          DateTime(1990, 1, 1),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Comment && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
