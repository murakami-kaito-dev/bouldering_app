import 'gym.dart';

/// ドメイン層: リポジトリ「インターフェース」
///
/// 本体の対応箇所: lib/domain/repositories/gym_repository.dart
///
/// 要点（依存性逆転の原則 = DIP）:
/// - 「データをどう取るか」の契約だけを定義し、実装は infrastructure 層に置く
/// - usecase はこの抽象にだけ依存する。
///   → API を Fake に差し替えてもドメイン層は1行も変わらない
abstract class GymRepository {
  Future<List<Gym>> getGyms();
}
