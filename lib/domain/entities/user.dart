class User {
  final String id;
  final String userName;
  final String email;
  final String? userIconUrl;
  final String? userIntroduce;
  final String? favoriteGym;
  final int? gender;
  final DateTime? birthday;
  final DateTime? boulStartDate;
  final int? homeGymId;

  const User({
    required this.id,
    required this.userName,
    required this.email,
    this.userIconUrl,
    this.userIntroduce,
    this.favoriteGym,
    this.gender,
    this.birthday,
    this.boulStartDate,
    this.homeGymId,
  });

  User copyWith({
    String? id,
    String? userName,
    String? email,
    String? userIconUrl,
    String? userIntroduce,
    String? favoriteGym,
    int? gender,
    DateTime? birthday,
    DateTime? boulStartDate,
    int? homeGymId,
  }) {
    return User(
      id: id ?? this.id,
      userName: userName ?? this.userName,
      email: email ?? this.email,
      userIconUrl: userIconUrl ?? this.userIconUrl,
      userIntroduce: userIntroduce ?? this.userIntroduce,
      favoriteGym: favoriteGym ?? this.favoriteGym,
      gender: gender ?? this.gender,
      birthday: birthday ?? this.birthday,
      boulStartDate: boulStartDate ?? this.boulStartDate,
      homeGymId: homeGymId ?? this.homeGymId,
    );
  }

  bool get hasProfile => userIntroduce != null && userIntroduce!.isNotEmpty;
  
  String get genderDisplay {
    switch (gender) {
      case 1:
        return '男性';
      case 2:
        return '女性';
      default:
        return '未回答';
    }
  }

  int? get boulderingYearsExperience {
    if (boulStartDate == null) return null;
    final now = DateTime.now();
    return now.difference(boulStartDate!).inDays ~/ 365;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userName == other.userName &&
          email == other.email;

  @override
  int get hashCode => id.hashCode ^ userName.hashCode ^ email.hashCode;
}