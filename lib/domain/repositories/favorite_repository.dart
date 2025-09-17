abstract class FavoriteRepository {
  Future<List<String>> getFavoriteUserIds(String userId);
  Future<List<String>> getFavoritedByUserIds(String userId);
  Future<bool> addFavoriteUser(String likerUserId, String likeeUserId);
  Future<bool> removeFavoriteUser(String likerUserId, String likeeUserId);
  Future<bool> isFavoriteUser(String likerUserId, String likeeUserId);

  Future<List<int>> getFavoriteGymIds(String userId);
  Future<bool> addFavoriteGym(String userId, int gymId);
  Future<bool> removeFavoriteGym(String userId, int gymId);
  Future<bool> isFavoriteGym(String userId, int gymId);

  /// 他ユーザーのお気に入りジム（イキタイジム）詳細情報を取得
  /// 公開情報として認証なしでアクセス可能
  Future<List<Map<String, dynamic>>> getFavoriteGyms(String userId);
}
