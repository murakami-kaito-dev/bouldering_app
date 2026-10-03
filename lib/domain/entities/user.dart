import '../../shared/utils/app_clock.dart';

class User {
  final String id;
  final String userName;

  /// 通知用に任意で登録するメールアドレス（未登録なら null。認証には使わない）
  final String? email;
  final String? userIconUrl;
  final String? userIntroduce;
  final String? favoriteGym;
  final int? gender;
  final DateTime? birthday;
  final DateTime? boulStartDate;
  final int? homeGymId;

  /// 管理しているジムの ID（ジム管理者のみ。一般ユーザーは null）
  ///
  /// 登録は運営が DB（users.managed_gym_id）を直接更新する運用。アプリからは変更できない。
  /// コンペの「開催する」ボタンはこの値がある人にだけ表示する
  final int? managedGymId;

  const User({
    required this.id,
    required this.userName,
    this.email,
    this.userIconUrl,
    this.userIntroduce,
    this.favoriteGym,
    this.gender,
    this.birthday,
    this.boulStartDate,
    this.homeGymId,
    this.managedGymId,
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
    int? managedGymId,
    bool clearEmail = false, // true でメールアドレスを未登録に戻す
  }) {
    return User(
      id: id ?? this.id,
      userName: userName ?? this.userName,
      email: clearEmail ? null : (email ?? this.email),
      userIconUrl: userIconUrl ?? this.userIconUrl,
      userIntroduce: userIntroduce ?? this.userIntroduce,
      favoriteGym: favoriteGym ?? this.favoriteGym,
      gender: gender ?? this.gender,
      birthday: birthday ?? this.birthday,
      boulStartDate: boulStartDate ?? this.boulStartDate,
      homeGymId: homeGymId ?? this.homeGymId,
      managedGymId: managedGymId ?? this.managedGymId,
    );
  }

  /// ジム管理者か（コンペを開催できるか）
  bool get isGymManager => managedGymId != null;

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
    final now = AppClock.todayJst();
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