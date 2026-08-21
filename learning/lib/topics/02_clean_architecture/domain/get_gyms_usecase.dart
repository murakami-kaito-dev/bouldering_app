import 'gym.dart';
import 'gym_repository.dart';

/// ドメイン層: ユースケース
///
/// 本体の対応箇所: lib/domain/usecases/gym_usecases.dart（SearchGyms 等）
///
/// 要点:
/// - 「アプリとして何をするか」を1クラス1責務で表す
/// - ビジネスルール（ここでは並び順の仕様）はUIやAPIではなくここに置く
/// - コンストラクタで抽象（GymRepository）を受け取る = 依存性注入（DI）
class GetGymsUseCase {
  GetGymsUseCase(this._repository);
  final GymRepository _repository;

  Future<List<Gym>> execute() async {
    final gyms = await _repository.getGyms();
    // ビジネスルール例: ボルダリング可のジムを先に、同種は名前順
    return [...gyms]..sort((a, b) {
        if (a.isBoulderingGym != b.isBoulderingGym) {
          return a.isBoulderingGym ? -1 : 1;
        }
        return a.name.compareTo(b.name);
      });
  }
}
