import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/gym_provider.dart';
import '../providers/gym_search_filter_provider.dart';
import '../components/gym/prefecture_selector.dart';
import '../components/gym/gym_type_selector.dart';
import 'gym_selection_page.dart';
import 'gym_search_result_page.dart';

/// ジム検索ページ
///
/// 役割:
/// - 都道府県、ジム種別による条件検索
/// - 検索条件の選択UI提供
/// - 検索結果件数の表示
/// - 検索結果ページへの遷移
///
/// クリーンアーキテクチャにおける位置づけ:
/// - Presentation層のUIコンポーネント
/// - 専用Providerによる状態管理
/// - 再利用可能なコンポーネント構成
class GymSearchPage extends ConsumerWidget {
  const GymSearchPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gymListState = ref.watch(gymListProvider);
    final filterState = ref.watch(gymSearchFilterProvider);
    final filterNotifier = ref.read(gymSearchFilterProvider.notifier);

    // ジムデータが読み込まれたらフィルタを適用
    gymListState.whenData((gyms) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        filterNotifier.applyFilter(gyms);
      });
    });

    return Scaffold(
      backgroundColor: const Color(0xFFFEF7FF),
      appBar: AppBar(
        elevation: 0.0,
        backgroundColor: const Color(0xFFFEF7FF),
        surfaceTintColor: const Color(0xFFFEF7FF),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'ジム検索',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // フィルターリセットボタン
          if (filterNotifier.hasActiveFilter)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: () {
                filterNotifier.resetFilter();
                gymListState.whenData((gyms) {
                  filterNotifier.applyFilter(gyms);
                });
              },
              tooltip: 'フィルターをリセット',
            ),
        ],
      ),
      body: Column(
        children: [
          // 検索ボックス
          _buildSearchBox(context),

          // ジムタイプ選択
          GymTypeSelector(
            selectedTypes: filterState.selectedGymTypes,
            onTypeChanged: (types) {
              filterNotifier.updateGymTypeSelection(types);
              gymListState.whenData((gyms) {
                filterNotifier.applyFilter(gyms);
              });
            },
          ),
          const SizedBox(height: 8),

          // 都道府県選択
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: PrefectureSelector(
                  selectedPrefectures: filterState.selectedPrefectures,
                  onPrefectureChanged: (prefectures) {
                    filterNotifier.updatePrefectureSelection(prefectures);
                    gymListState.whenData((gyms) {
                      filterNotifier.applyFilter(gyms);
                    });
                  },
                ),
              ),
            ),
          ),

          // 検索結果表示部分
          _buildSearchResultSection(context, ref, gymListState, filterState),
        ],
      ),
    );
  }

  /// 検索ボックス構築
  Widget _buildSearchBox(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        readOnly: true,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const GymSelectionPage(),
            ),
          );
        },
        decoration: InputDecoration(
          hintText: '施設名',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(32),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          prefixIcon: const Icon(Icons.search),
        ),
      ),
    );
  }

  /// 検索結果セクション構築
  Widget _buildSearchResultSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue gymListState,
    GymSearchFilterState filterState,
  ) {
    return Container(
      width: double.infinity,
      // 条件表示の有無に関わらず一定の高さを確保
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 条件表示エリア（常に高さを確保）
          Container(
            height: 18,
            child: ref.read(gymSearchFilterProvider.notifier).hasActiveFilter
                ? Text(
                    '${ref.read(gymSearchFilterProvider.notifier).selectedConditionCount}個の条件で絞り込み中',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // 件数 + 検索ボタン
          Row(
            children: [
              // 件数表示
              Text(
                gymListState.when(
                  loading: () => '検索中...',
                  error: (_, __) => '0 件',
                  data: (_) => filterState.isLoading
                      ? '検索中...'
                      : '${filterState.filteredGyms.length} 件',
                ),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),

              // 検索ボタン
              Expanded(
                child: ElevatedButton(
                  onPressed: filterState.filteredGyms.isEmpty
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GymSearchResultPage(
                                gyms: filterState.filteredGyms,
                              ),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: filterState.filteredGyms.isEmpty
                        ? Colors.grey
                        : Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '検　索',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
