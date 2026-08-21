import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

/// プレゼンテーション層: 画面
///
/// 本体の対応箇所: lib/presentation/pages/gym_search_result_page.dart 等
///
/// 要点:
/// - 画面は Provider を watch するだけ。API・JSON・並び順の知識を持たない
/// - 依存の全体像（このミニアプリで再現している形）:
///     presentation ──▶ domain ◀── infrastructure
///   ドメインが中心で、外側の層が内側に向かって依存する
class GymListPage extends ConsumerWidget {
  const GymListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gymsAsync = ref.watch(gymListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('02 Clean Architecture')),
      body: gymsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('エラー: $e')),
        data: (gyms) => ListView(
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                '画面 → UseCase → Repository(抽象) → RepositoryImpl → DataSource\n'
                'の順で呼ばれ、JSONはinfrastructure層でエンティティに変換される。\n'
                '並び順（ボルダリング優先→名前順）はUseCaseのビジネスルール。',
                style: TextStyle(fontSize: 12),
              ),
            ),
            for (final g in gyms)
              ListTile(
                leading: Icon(
                  g.isBoulderingGym ? Icons.terrain : Icons.hiking,
                  color: g.isBoulderingGym ? Colors.indigo : Colors.grey,
                ),
                title: Text(g.name),
                subtitle: Text(g.prefecture),
                trailing: Text(g.isBoulderingGym ? 'ボルダリング' : 'リードのみ'),
              ),
          ],
        ),
      ),
    );
  }
}
