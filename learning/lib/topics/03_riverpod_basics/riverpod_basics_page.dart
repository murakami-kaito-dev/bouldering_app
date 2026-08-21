import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ============================================================
/// トピック03: Riverpod 状態管理入門
///
/// 本体の対応箇所:
///   lib/presentation/providers/ 配下の22ファイル
///   （StateNotifierProvider が中心。family / autoDispose も多用）
///
/// 本体で使われている Provider の種類と使い分け:
///   Provider                 … DI（UseCase等の生成）。値は不変
///   StateProvider            … 単純な値1つ（本体ではほぼ未使用）
///   StateNotifierProvider    … 状態+操作のセット（本体の主役）
///   FutureProvider           … 非同期取得を AsyncValue で表現
///   .family                  … パラメータ付き（ユーザーIDごとの状態など）
///   .autoDispose             … 画面を離れたら状態を破棄
/// ============================================================

/// ---- (1) Provider: DI用。不変の依存を提供する ----
final greetingServiceProvider = Provider((ref) => GreetingService());

class GreetingService {
  String greet(String name) => 'こんにちは、$name さん';
}

/// ---- (2) StateProvider: 単純な値1つ ----
final counterProvider = StateProvider<int>((ref) => 0);

/// ---- (3) StateNotifierProvider: 状態クラス + 操作（本体の主役パターン）----
/// 本体例: blockProvider, favoriteUserProvider など
class TodoListNotifier extends StateNotifier<List<String>> {
  TodoListNotifier() : super(const []);

  // 状態は「不変オブジェクトの差し替え」で更新する（state.add() はNG）
  void add(String item) => state = [...state, item];
  void removeAt(int i) =>
      state = [...state]..removeAt(i);
}

final todoListProvider =
    StateNotifierProvider<TodoListNotifier, List<String>>(
        (ref) => TodoListNotifier());

/// ---- (4) FutureProvider + AsyncValue: 非同期の3状態 ----
/// 本体例: userProvider, gymListProvider(gym_provider.dart)
final serverTimeProvider = FutureProvider.autoDispose<String>((ref) async {
  await Future.delayed(const Duration(seconds: 1));
  return DateTime.now().toIso8601String().substring(11, 19);
});

/// ---- (5) family: パラメータ付きProvider ----
/// 本体例: otherUserTweetsProvider(family: userId), gymTweetsProvider(family: gymId)
final squareProvider = Provider.family<int, int>((ref, n) => n * n);

/// ---- (6) autoDispose の観察用 ----
/// この画面を閉じると dispose ログが（デバッグコンソールに）出る。
/// 本体例: generalTweetsProvider（タイムラインを離れたら状態破棄）
final disposableProvider = Provider.autoDispose<String>((ref) {
  ref.onDispose(() => debugPrint('>>> disposableProvider が破棄された'));
  return '画面を閉じると破棄されるProvider';
});

/// ---- 画面 ----
class RiverpodBasicsPage extends ConsumerWidget {
  const RiverpodBasicsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // watch = 変化を購読して再ビルド / read = その場で1回読むだけ
    final counter = ref.watch(counterProvider);
    final todos = ref.watch(todoListProvider);
    final timeAsync = ref.watch(serverTimeProvider);
    final square = ref.watch(squareProvider(counter));

    return Scaffold(
      appBar: AppBar(title: const Text('03 Riverpod 入門')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section('(1) Provider（DI）',
              ref.read(greetingServiceProvider).greet('クライマー')),
          const Divider(),
          _section('(2) StateProvider + (5) family',
              'カウンタ: $counter / familyで二乗: $square'),
          Row(
            children: [
              FilledButton(
                onPressed: () => ref.read(counterProvider.notifier).state++,
                child: const Text('+1'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () =>
                    ref.invalidate(counterProvider), // 初期値に戻す
                child: const Text('リセット'),
              ),
            ],
          ),
          const Divider(),
          _section('(3) StateNotifierProvider（本体の主役）',
              '状態は不変リストの差し替えで更新する'),
          Row(
            children: [
              FilledButton(
                onPressed: () => ref
                    .read(todoListProvider.notifier)
                    .add('課題 ${todos.length + 1}'),
                child: const Text('追加'),
              ),
            ],
          ),
          for (var i = 0; i < todos.length; i++)
            ListTile(
              dense: true,
              title: Text(todos[i]),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () =>
                    ref.read(todoListProvider.notifier).removeAt(i),
              ),
            ),
          const Divider(),
          _section('(4) FutureProvider + AsyncValue', 'when で3状態を描き分ける'),
          timeAsync.when(
            loading: () => const Text('loading…（1秒かかる）'),
            error: (e, _) => Text('error: $e'),
            data: (t) => Text('data: サーバ時刻 $t'),
          ),
          TextButton(
            onPressed: () => ref.invalidate(serverTimeProvider),
            child: const Text('再取得（invalidate）'),
          ),
          const Divider(),
          _section('(6) autoDispose', ref.watch(disposableProvider)),
          const Text(
            'この画面を閉じるとデバッグコンソールに破棄ログが出る。\n'
            '本体ではタイムラインの状態を画面離脱で破棄するのに使っている。',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, String body) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(body),
          ],
        ),
      );
}
