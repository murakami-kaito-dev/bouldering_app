import '../entities/gym.dart';
import '../entities/gym_photo.dart';
import '../repositories/gym_repository.dart';
import '../exceptions/app_exceptions.dart';

/// ジム写真取得ユースケース
///
/// 写真の取得元（自前GCS写真 or Google Places API）はバックエンドが判定する。
/// フロントは受け取った写真を表示するだけ（source=='google' のときは帰属表示が必要）。
class GetGymPhotosUseCase {
  final GymRepository _repository;

  GetGymPhotosUseCase(this._repository);

  Future<GymPhotoSet> execute(int gymId) async {
    if (gymId <= 0) {
      throw const ValidationException(
        message: '有効なジムIDを指定してください',
        errors: {'gymId': '1以上の整数が必要です'},
      );
    }
    return _repository.getGymPhotos(gymId);
  }
}

class SearchGymsUseCase {
  final GymRepository _gymRepository;

  SearchGymsUseCase(this._gymRepository);

  Future<List<Gym>> execute({
    String? prefecture,
    String? city,
    String? name,
    List<String>? climbingTypes,
  }) async {
    try {
      return await _gymRepository.searchGyms(
        prefecture: prefecture,
        city: city,
        name: name,
        climbingTypes: climbingTypes,
      );
    } catch (e) {
      throw DataFetchException(
        message: 'ジム検索に失敗しました',
        originalError: e,
      );
    }
  }
}

class GetNearbyGymsUseCase {
  final GymRepository _gymRepository;

  GetNearbyGymsUseCase(this._gymRepository);

  Future<List<Gym>> execute({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
  }) async {
    try {
      return await _gymRepository.getGymsByLocation(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      );
    } catch (e) {
      throw DataFetchException(
        message: '近くのジム取得に失敗しました',
        originalError: e,
      );
    }
  }
}

class GetPopularGymsUseCase {
  final GymRepository _gymRepository;

  GetPopularGymsUseCase(this._gymRepository);

  Future<List<Gym>> execute({int limit = 10}) async {
    try {
      return await _gymRepository.getPopularGyms(limit: limit);
    } catch (e) {
      throw DataFetchException(
        message: '人気ジム取得に失敗しました',
        originalError: e,
      );
    }
  }
}

class GetGymDetailsUseCase {
  final GymRepository _gymRepository;

  GetGymDetailsUseCase(this._gymRepository);

  Future<Gym?> execute(int gymId) async {
    try {
      return await _gymRepository.getGymById(gymId);
    } catch (e) {
      throw DataFetchException(
        message: 'ジム詳細取得に失敗しました',
        originalError: e,
      );
    }
  }
}