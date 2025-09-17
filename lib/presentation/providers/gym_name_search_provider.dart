import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/gym.dart';

/// ジム名検索状態クラス
class GymNameSearchState {
  final String searchQuery;
  final List<Gym> allGyms;
  final List<Gym> filteredGyms;
  final bool isLoading;

  const GymNameSearchState({
    required this.searchQuery,
    required this.allGyms,
    required this.filteredGyms,
    this.isLoading = false,
  });

  GymNameSearchState copyWith({
    String? searchQuery,
    List<Gym>? allGyms,
    List<Gym>? filteredGyms,
    bool? isLoading,
  }) {
    return GymNameSearchState(
      searchQuery: searchQuery ?? this.searchQuery,
      allGyms: allGyms ?? this.allGyms,
      filteredGyms: filteredGyms ?? this.filteredGyms,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// ジム名検索StateNotifier
/// 
/// 役割:
/// - ジム名での検索状態管理
/// - リアルタイム検索フィルタリング
/// - 検索結果の管理
/// 
/// クリーンアーキテクチャにおける位置づけ:
/// - Presentation層の状態管理
/// - 単一責任の原則に従った専用Provider
class GymNameSearchNotifier extends StateNotifier<GymNameSearchState> {
  GymNameSearchNotifier() : super(const GymNameSearchState(
    searchQuery: '',
    allGyms: [],
    filteredGyms: [],
  ));

  /// ジムデータを設定
  void setGyms(List<Gym> gyms) {
    state = state.copyWith(
      allGyms: gyms,
      filteredGyms: gyms,
    );
  }

  /// 検索クエリを更新してフィルタリング実行
  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    _performSearch();
  }

  /// 検索実行
  void _performSearch() {
    final query = state.searchQuery.toLowerCase().trim();
    
    if (query.isEmpty) {
      // 検索クエリが空の場合は全ジムを表示
      state = state.copyWith(filteredGyms: state.allGyms);
    } else {
      // ジム名で部分一致検索
      final filtered = state.allGyms.where((gym) {
        final gymName = gym.name.toLowerCase();
        final gymAddress = '${gym.prefecture}${gym.city}${gym.addressLine}'.toLowerCase();
        
        // ジム名または住所に検索クエリを含むかチェック
        return gymName.contains(query) || gymAddress.contains(query);
      }).toList();
      
      // 関連度順でソート（ジム名に含まれるものを優先）
      filtered.sort((a, b) {
        final aNameMatch = a.name.toLowerCase().contains(query);
        final bNameMatch = b.name.toLowerCase().contains(query);
        
        if (aNameMatch && !bNameMatch) return -1;
        if (!aNameMatch && bNameMatch) return 1;
        
        // 両方ともジム名にマッチするか両方ともしない場合は、文字列順
        return a.name.compareTo(b.name);
      });
      
      state = state.copyWith(filteredGyms: filtered);
    }
  }

  /// 検索クリア
  void clearSearch() {
    state = state.copyWith(
      searchQuery: '',
      filteredGyms: state.allGyms,
    );
  }

  /// 検索結果が空かどうか
  bool get hasResults => state.filteredGyms.isNotEmpty;
  
  /// 検索中かどうか
  bool get isSearching => state.searchQuery.isNotEmpty;
}

/// ジム名検索Provider
final gymNameSearchProvider = StateNotifierProvider<GymNameSearchNotifier, GymNameSearchState>(
  (ref) => GymNameSearchNotifier(),
);