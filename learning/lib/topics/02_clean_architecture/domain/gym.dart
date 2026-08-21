/// ドメイン層: エンティティ
///
/// 本体の対応箇所: lib/domain/entities/gym.dart
///
/// 要点:
/// - ビジネスの関心事（ジムとは何か）だけを持つ
/// - Flutter にも HTTP にも DB にも依存しない「純粋な Dart」
/// - JSON変換（fromJson）をここに置くかは流派が分かれる。
///   本体は infrastructure 層の datasource がマッピングを担当している
class Gym {
  const Gym({
    required this.id,
    required this.name,
    required this.prefecture,
    required this.isBoulderingGym,
  });

  final int id;
  final String name;
  final String prefecture;
  final bool isBoulderingGym;
}
