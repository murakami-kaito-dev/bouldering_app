import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/gym_name_search_provider.dart';
import '../providers/gym_provider.dart';
import '../../shared/services/navigation_service.dart';

/// ジム名検索ページ
/// 
/// 役割:
/// - ジム名での検索UI提供
/// - リアルタイム検索結果表示
/// - 選択されたジムの詳細ページへの遷移
/// - 選択モード時はジム情報を返す
/// 
/// クリーンアーキテクチャにおける位置づけ:
/// - Presentation層のUI
/// - GymNameSearchProviderを使用した状態管理
/// - 単一責任の原則に従った専用ページ
class GymSelectionPage extends ConsumerStatefulWidget {
  /// 選択モード（true: ジム情報を返す, false: ジム詳細ページへ遷移）
  final bool selectionMode;
  
  const GymSelectionPage({
    super.key,
    this.selectionMode = false,
  });

  @override
  ConsumerState<GymSelectionPage> createState() => _GymSelectionPageState();
}

class _GymSelectionPageState extends ConsumerState<GymSelectionPage> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGyms();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// ジムデータを読み込んでProviderに設定
  void _loadGyms() {
    final gymState = ref.read(gymListProvider);
    gymState.when(
      data: (gyms) {
        // フィルタリング済みのジムリストをProviderに設定
        final validGyms = gyms
            .where((gym) => 
                gym.name.isNotEmpty && 
                gym.prefecture.isNotEmpty && 
                gym.city.isNotEmpty)
            .toList();
        
        ref.read(gymNameSearchProvider.notifier).setGyms(validGyms);
      },
      loading: () => {
        // ローディング状態は自動でStateに反映される
      },
      error: (error, stack) => {
        // エラーハンドリングは必要に応じて実装
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ジム情報の取得に失敗しました: $error')),
        )
      },
    );
  }

  /// 検索クエリ更新
  void _onSearchChanged(String query) {
    ref.read(gymNameSearchProvider.notifier).updateSearchQuery(query);
  }

  /// 検索クリア
  void _onClearSearch() {
    _controller.clear();
    ref.read(gymNameSearchProvider.notifier).clearSearch();
  }

  /// ジム選択時の処理
  void _onGymSelected(int gymId, String gymName) {
    if (widget.selectionMode) {
      // 選択モード: ジム情報を返す
      Navigator.pop(context, {
        'gymId': gymId,
        'gymName': gymName,
      });
    } else {
      // 通常モード: ジム詳細ページへ遷移
      NavigationService.navigateToGymDetail(
        context: context,
        gymId: gymId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(gymNameSearchProvider);
    final gymListState = ref.watch(gymListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ジム検索', style: TextStyle(color: Colors.black)),
        elevation: 0.0,
        backgroundColor: const Color(0x00FEF7FF),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // 検索ボックス
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: '施設名',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(32),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      prefixIcon: const Icon(Icons.search),
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ),
                TextButton(
                  onPressed: _onClearSearch,
                  child: const Text('クリア', style: TextStyle(color: Colors.blue)),
                ),
              ],
            ),
          ),

          // ジムリスト表示
          Expanded(
            child: gymListState.when(
              data: (_) => _buildGymList(searchState),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 48, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'ジム情報の取得に失敗しました',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _loadGyms,
                      child: const Text('再読み込み'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ジムリストウィジェット構築
  Widget _buildGymList(searchState) {
    if (searchState.filteredGyms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              searchState.searchQuery.isEmpty 
                  ? Icons.search 
                  : Icons.search_off,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              searchState.searchQuery.isEmpty
                  ? 'ジム名を入力して検索してください'
                  : '該当するジムが見つかりません',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: searchState.filteredGyms.length,
      itemBuilder: (context, index) {
        final gym = searchState.filteredGyms[index];
        return ListTile(
          title: Text(
            gym.name,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text('${gym.prefecture}${gym.city}'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => _onGymSelected(gym.id, gym.name),
        );
      },
    );
  }
}