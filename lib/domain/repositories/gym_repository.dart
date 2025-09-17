import '../entities/gym.dart';

abstract class GymRepository {
  Future<List<Gym>> getAllGyms();
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