class FavoriteUserRelation {
  final String likerUserId;
  final String likeeUserId;
  final DateTime? createdAt;

  const FavoriteUserRelation({
    required this.likerUserId,
    required this.likeeUserId,
    this.createdAt,
  });

  FavoriteUserRelation copyWith({
    String? likerUserId,
    String? likeeUserId,
    DateTime? createdAt,
  }) {
    return FavoriteUserRelation(
      likerUserId: likerUserId ?? this.likerUserId,
      likeeUserId: likeeUserId ?? this.likeeUserId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FavoriteUserRelation &&
          runtimeType == other.runtimeType &&
          likerUserId == other.likerUserId &&
          likeeUserId == other.likeeUserId;

  @override
  int get hashCode => likerUserId.hashCode ^ likeeUserId.hashCode;
}

class FavoriteGymRelation {
  final String userId;
  final int gymId;
  final DateTime? createdAt;

  const FavoriteGymRelation({
    required this.userId,
    required this.gymId,
    this.createdAt,
  });

  FavoriteGymRelation copyWith({
    String? userId,
    int? gymId,
    DateTime? createdAt,
  }) {
    return FavoriteGymRelation(
      userId: userId ?? this.userId,
      gymId: gymId ?? this.gymId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FavoriteGymRelation &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          gymId == other.gymId;

  @override
  int get hashCode => userId.hashCode ^ gymId.hashCode;
}
