import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ============================================================
/// トピック07: 検索とフィルタリング
///
/// 本体の対応箇所:
///   lib/presentation/providers/gym_name_search_provider.dart（名前/住所検索+関連度ソート）
///   lib/presentation/providers/gym_search_filter_provider.dart（都道府県×種別フィルタ）
///   lib/presentation/pages/gym_selection_page.dart（インクリメンタル検索UI）
///
/// 要点:
///   1. デバウンス: 1文字ごとに検索処理を走らせない。
///      入力が300ms止まってから実行する（Timerをキャンセルして張り直す）
///   2. 関連度ソート: 「前方一致 > 部分一致」の順で並べる
///   3. 複数条件の合成: テキスト・都道府県・種別のANDを1つの
///      「純粋関数」に集約する（UIから分離するとテスト可能になる）
/// ============================================================

class MiniGym {
  const MiniGym(this.name, this.prefecture, this.type);
  final String name;
  final String prefecture;
  final String type; // 'ボルダリング' or 'リード'
}

const allGyms = [
  MiniGym('ロックランド新宿', '東京都', 'ボルダリング'),
  MiniGym('ロックビレッジ渋谷', '東京都', 'ボルダリング'),
  MiniGym('新宿クライミングパーク', '東京都', 'リード'),
  MiniGym('ボルダーパーク池袋', '東京都', 'ボルダリング'),
  MiniGym('大阪ロックジム', '大阪府', 'ボルダリング'),
  MiniGym('なんばウォール', '大阪府', 'リード'),
  MiniGym('ロッククライム梅田', '大阪府', 'ボルダリング'),
  MiniGym('博多ボルダリングベース', '福岡県', 'ボルダリング'),
  MiniGym('天神ロックスタジオ', '福岡県', 'ボルダリング'),
  MiniGym('札幌クライムベース', '北海道', 'リード'),
  MiniGym('すすきのロック', '北海道', 'ボルダリング'),
];

/// ---- フィルタ条件（不変オブジェクト）----
class SearchCondition {
  const SearchCondition({
    this.keyword = '',
    this.prefecture,
    this.type,
  });
  final String keyword;
  final String? prefecture; // null = 指定なし
  final String? type;

  SearchCondition copyWith({
    String? keyword,
    String? Function()? prefecture, // nullを設定できるようクロージャで渡す
    String? Function()? type,
  }) =>
      SearchCondition(
        keyword: keyword ?? this.keyword,
        prefecture: prefecture != null ? prefecture() : this.prefecture,
        type: type != null ? type() : this.type,
      );
}

/// ---- 要点3: 検索ロジックは「純粋関数」に切り出す ----
/// 入力(全件+条件)→出力(結果)だけの関数なのでユニットテストが容易。
/// 本体の gym_name_search_provider.dart の関連度ソートと同じ発想。
List<MiniGym> searchGyms(List<MiniGym> gyms, SearchCondition c) {
  final keyword = c.keyword.trim();
  var result = gyms.where((g) {
    final matchKeyword = keyword.isEmpty || g.name.contains(keyword);
    final matchPref = c.prefecture == null || g.prefecture == c.prefecture;
    final matchType = c.type == null || g.type == c.type;
    return matchKeyword && matchPref && matchType; // AND合成
  }).toList();

  // 要点2: 関連度ソート（前方一致を上に）
  if (keyword.isNotEmpty) {
    result.sort((a, b) {
      final aStarts = a.name.startsWith(keyword) ? 0 : 1;
      final bStarts = b.name.startsWith(keyword) ? 0 : 1;
      if (aStarts != bStarts) return aStarts - bStarts;
      return a.name.compareTo(b.name);
    });
  }
  return result;
}

final conditionProvider = StateProvider.autoDispose(
    (ref) => const SearchCondition());

/// 条件が変わるたびに自動で再計算される派生Provider
final searchResultProvider = Provider.autoDispose<List<MiniGym>>(
    (ref) => searchGyms(allGyms, ref.watch(conditionProvider)));

/// ---- 画面 ----
class SearchFilterPage extends ConsumerStatefulWidget {
  const SearchFilterPage({super.key});

  @override
  ConsumerState<SearchFilterPage> createState() => _SearchFilterPageState();
}

class _SearchFilterPageState extends ConsumerState<SearchFilterPage> {
  Timer? _debounce;
  int _searchRunCount = 0; // デバウンスの効果を見せるカウンタ

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  /// 要点1: デバウンス。前のタイマーをキャンセルして張り直す
  void _onKeywordChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => _searchRunCount++);
      ref.read(conditionProvider.notifier).state =
          ref.read(conditionProvider).copyWith(keyword: text);
    });
  }

  @override
  Widget build(BuildContext context) {
    final condition = ref.watch(conditionProvider);
    final results = ref.watch(searchResultProvider);
    const prefectures = ['東京都', '大阪府', '福岡県', '北海道'];
    const types = ['ボルダリング', 'リード'];

    return Scaffold(
      appBar: AppBar(title: const Text('07 検索とフィルタ')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'ジム名で検索（300msデバウンス）',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                helperText: '検索実行回数: $_searchRunCount 回'
                    '（デバウンスなしなら1文字ごとに走る）',
              ),
              onChanged: _onKeywordChanged,
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                for (final p in prefectures)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(p),
                      selected: condition.prefecture == p,
                      onSelected: (sel) =>
                          ref.read(conditionProvider.notifier).state =
                              condition.copyWith(
                                  prefecture: () => sel ? p : null),
                    ),
                  ),
                const VerticalDivider(),
                for (final t in types)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(t),
                      selected: condition.type == t,
                      onSelected: (sel) =>
                          ref.read(conditionProvider.notifier).state =
                              condition.copyWith(type: () => sel ? t : null),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: results.isEmpty
                ? const Center(child: Text('該当するジムがありません'))
                : ListView(
                    children: [
                      for (final g in results)
                        ListTile(
                          leading: Icon(g.type == 'ボルダリング'
                              ? Icons.terrain
                              : Icons.hiking),
                          title: Text(g.name),
                          subtitle: Text('${g.prefecture} / ${g.type}'),
                        ),
                    ],
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text('${results.length} 件ヒット'),
          ),
        ],
      ),
    );
  }
}
