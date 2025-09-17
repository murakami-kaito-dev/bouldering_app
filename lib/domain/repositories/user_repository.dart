import '../entities/user.dart';
import '../entities/bouldering_stats.dart';

abstract class UserRepository {
  Future<User?> getUserById(String userId);
  Future<User?> getUserProfile(String userId);
  Future<bool> createUser(String userId, String email);
  Future<bool> updateUserName(String userId, String userName);
  Future<bool> updateUserIconUrl(String userId, String iconUrl);
  Future<bool> updateUserProfile({
    required String userId,
    String? userIntroduce,
    String? favoriteGym,
  });
  Future<bool> updateUserGender(String userId, int gender);
  Future<bool> updateUserDates({
    required String userId,
    DateTime? birthday,
    DateTime? boulStartDate,
  });
  Future<bool> updateHomeGym(String userId, int gymId);
  Future<String?> uploadUserIcon(String userId, String imagePath);
  Future<bool> updateUserEmail(String userId, String email);
  Future<bool> deleteUser(String userId);
  
  /// ユーザーの月間統計情報を取得
  /// 
  /// [userId] ユーザーのID
  /// [monthsAgo] 何ヶ月前の統計を取得するか（0: 今月、1: 先月）
  /// 
  /// 返り値:
  /// 月間統計情報
  Future<BoulderingStats> getMonthlyStatistics(String userId, int monthsAgo);
}