import '../domain/gym.dart';
import '../domain/gym_repository.dart';
import 'gym_datasource.dart';

/// インフラ層: リポジトリ「実装」
///
/// 本体の対応箇所: lib/infrastructure/repositories/gym_repository_impl.dart
///
/// 要点:
/// - domain の抽象（GymRepository）を implements し、
///   datasource の生データをエンティティに変換して返す
/// - 依存の向きに注目:
///     infrastructure ──▶ domain（実装が抽象に依存する）
///   domain は infrastructure を一切 import していない
class GymRepositoryImpl implements GymRepository {
  GymRepositoryImpl(this._dataSource);
  final GymDataSource _dataSource;

  @override
  Future<List<Gym>> getGyms() async {
    final json = await _dataSource.fetchGymsJson();
    // JSON→エンティティのマッピングはこの層の責務
    return json
        .map((e) => Gym(
              id: e['gym_id'] as int,
              name: e['gym_name'] as String,
              prefecture: e['prefecture'] as String,
              isBoulderingGym: e['is_bouldering_gym'] as bool,
            ))
        .toList();
  }
}
