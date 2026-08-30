import '../entities/gym.dart';
import '../entities/gym_photo.dart';

abstract class GymRepository {
  Future<List<Gym>> getAllGyms();

  /// ジムの写真セットを取得する（出どころの判定はバックエンド側で行う）
  Future<GymPhotoSet> getGymPhotos(int gymId);
  Future<Gym?> getGymById(int gymId);
  Future<List<Gym>> searchGyms({
    String? prefecture,
    String? city,
    String? name,
    List<String>? climbingTypes,
  });
  Future<List<Gym>> getGymsByLocation({
    required double latitude,
    required double longitude,
    required double radiusKm,
  });
  Future<List<Gym>> getPopularGyms({int limit = 10});
  Future<bool> incrementIkitaiCount(int gymId);
  Future<bool> decrementIkitaiCount(int gymId);
}