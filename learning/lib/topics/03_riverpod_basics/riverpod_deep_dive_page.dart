import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ============================================================
/// トピック03+: Riverpod 深掘りデモ（autoDispose / family を体験する）
///
/// 解説ドキュメント: 同フォルダの riverpod_deep_dive.md
/// 本体での対応: PR #27 でタイムラインの autoDispose を外した修正
///
/// このデモで体験できること:
///   (1) autoDispose の有無で「画面を閉じたとき」の挙動がどう変わるか
///       → 本体の「タブを開くたびに再取得」バグの正体そのもの
///   (2) family が「引数ごとに独立した状態」を持つこと
/// ============================================================

/// --- (A) autoDisposeなし: 誰も見ていなくても状態がアプリ生存中ずっと残る ---
/// 本体の対応: 修正後の generalTweetsProvider / myTweetsProvider
final keepAliveCounterProvider = StateProvider<int>((ref) => 0);

/// --- (B) autoDisposeあり: 誰も見なくなった瞬間に破棄され、次は初期値から ---
/// 本体の対応: 修正前の generalTweetsProvider（これが再取得バグの原因だった）
final autoDisposeCounterProvider = StateProvider.autoDispose<int>((ref) => 0);

/// --- (C) family: 引数（ここではユーザーID）ごとに独立した状態を持つ ---
/// 本体の対応: favoriteUserTweetsProvider(userId) / myTweetsProvider(userId)
final familyCounterProvider =
    StateProvider.family<int, String>((ref, userId) => 0);

/// メイン画面（実験の説明と入口）
class RiverpodDeepDivePage extends ConsumerStatefulWidget {
  const RiverpodDeepDivePage({super.key});

  @override
  ConsumerState<RiverpodDeepDivePage> createState() =>
      _RiverpodDeepDivePageState();
}

class _RiverpodDeepDivePageState extends ConsumerState<RiverpodDeepDivePage> {
  String _selectedUser = 'ユーザーA';

  @override
  Widget build(BuildContext context) {
    // family: 選択中ユーザーのカウンターだけを watch する
    final familyCount = ref.watch(familyCounterProvider(_selectedUser));

    return Scaffold(
      appBar: AppBar(title: const Text('03+ Riverpod 深掘りデモ')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---------- 実験1: autoDispose ----------
          Text('実験1: autoDispose の有無',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          const Text(
            '手順: ①下のボタンでカウンター画面を開く → ②両方のカウンターを増やす → '
            '③戻る → ④もう一度開く。\n'
            '→ autoDisposeあり側だけ 0 に戻っている（画面を閉じた瞬間に状態が破棄されたため）。\n'
            '本体アプリで「タブを開くたびにDB再取得」になっていたのは、まさにこの挙動。',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            icon: const Icon(Icons.science),
            label: const Text('カウンター画面を開く（何度も出入りしてみる）'),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const _CounterDemoPage()),
            ),
          ),
          const Divider(height: 32),

          // ---------- 実験2: family ----------
          Text('実験2: family（引数ごとに独立した状態）',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          const Text(
            'ユーザーを切り替えて +1 してみる。カウントはユーザーごとに別々に保持される。\n'
            '= familyCounterProvider("ユーザーA") と ("ユーザーB") は完全に別のプロバイダ。',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final user in ['ユーザーA', 'ユーザーB', 'ユーザーC'])
                ChoiceChip(
                  label: Text(user),
                  selected: _selectedUser == user,
                  onSelected: (_) => setState(() => _selectedUser = user),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              title: Text('$_selectedUser のカウント: $familyCount'),
              subtitle: const Text('familyCounterProvider(選択中ユーザー) を watch'),
              trailing: FilledButton(
                onPressed: () => ref
                    .read(familyCounterProvider(_selectedUser).notifier)
                    .state++,
                child: const Text('+1'),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'ヒント: この画面自体を閉じても family のカウントは残る（autoDisposeを付けていないため）。\n'
            '本体の favoriteUserTweetsProvider は「family あり・autoDispose なし」＝この構成。',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

/// 実験1用のサブ画面。
/// この画面を閉じると autoDispose 側のプロバイダは「誰にも watch されていない」状態になり破棄される。
class _CounterDemoPage extends ConsumerWidget {
  const _CounterDemoPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keep = ref.watch(keepAliveCounterProvider);
    final auto = ref.watch(autoDisposeCounterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('カウンター画面')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _counterCard(
              context,
              title: 'autoDispose なし',
              subtitle: '本体の修正後タイムラインと同じ。閉じても値が残る',
              value: keep,
              color: Colors.green,
              onIncrement: () =>
                  ref.read(keepAliveCounterProvider.notifier).state++,
            ),
            const SizedBox(height: 12),
            _counterCard(
              context,
              title: 'autoDispose あり',
              subtitle: '本体の修正前タイムラインと同じ。閉じると破棄→次回0から',
              value: auto,
              color: Colors.red,
              onIncrement: () =>
                  ref.read(autoDisposeCounterProvider.notifier).state++,
            ),
            const SizedBox(height: 16),
            const Text(
              '両方増やしてから「戻る」→ もう一度開いてみる。\n'
              '（もしこれがカウンターではなく「DBから取得したツイート一覧」だったら？\n'
              '　→ autoDispose側は戻るたびに再取得＝ローディングが走る、が本体で起きていたこと）',
              style: TextStyle(fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _counterCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required int value,
    required Color color,
    required VoidCallback onIncrement,
  }) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Text('$value', style: TextStyle(color: color)),
        ),
        title: Text(title),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: FilledButton(onPressed: onIncrement, child: const Text('+1')),
      ),
    );
  }
}
