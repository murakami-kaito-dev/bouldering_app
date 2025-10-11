class UserBlock {
  final int blockId;
  final String blockerUserId;
  final String blockedUserId;
  final DateTime createdAt;

  const UserBlock({
    required this.blockId,
    required this.blockerUserId,
    required this.blockedUserId,
    required this.createdAt,
  });

  factory UserBlock.fromJson(Map<String, dynamic> json) {
    return UserBlock(
      blockId: json['block_id'] as int,
      blockerUserId: json['blocker_user_id'] as String,
      blockedUserId: json['blocked_user_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'block_id': blockId,
      'blocker_user_id': blockerUserId,
      'blocked_user_id': blockedUserId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class BlockedUser {
  final String userId;
  final String userName;
  final String? userIconUrl;
  final String? userBio;
  final DateTime blockedAt;

  const BlockedUser({
    required this.userId,
    required this.userName,
    this.userIconUrl,
    this.userBio,
    required this.blockedAt,
  });

  factory BlockedUser.fromJson(Map<String, dynamic> json) {
    return BlockedUser(
      userId: json['blocked_user_id'] as String,
      userName: json['user_name'] as String,
      userIconUrl: json['user_icon_url'] as String?,
      userBio: json['user_bio'] as String?,
      blockedAt: DateTime.parse(json['blocked_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'blocked_user_id': userId,
      'user_name': userName,
      'user_icon_url': userIconUrl,
      'user_bio': userBio,
      'blocked_at': blockedAt.toIso8601String(),
    };
  }
}