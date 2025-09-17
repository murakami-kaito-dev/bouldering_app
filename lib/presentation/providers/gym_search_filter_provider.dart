import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/gym.dart';
import '../../shared/constants/prefecture_constants.dart';

/// ジム検索フィルター状態クラス
class GymSearchFilterState {
  final Map<String, bool> selectedPrefectures;
  final Map<String, bool> selectedGymTypes;
  final List<Gym> filteredGyms;
  final bool isLoading;

  const GymSearchFilterState({
    required this.selectedPrefectures,
    required this.selectedGymTypes,
    required this.filteredGyms,
    this.isLoading = false,
  });

  GymSearchFilterState copyWith({
    Map<String, bool>? selectedPrefectures,
    Map<String, bool>? selectedGymTypes,
    List<Gym>? filteredGyms,
    bool? isLoading,
  }) {
    return GymSearchFilterState(
      selectedPrefectures: selectedPrefectures ?? this.selectedPrefectures,
      selectedGymTypes: selectedGymTypes ?? this.selectedGymTypes,
      filteredGyms: filteredGyms ?? this.filteredGyms,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// ジム検索フィルターStateNotifier
/// 
/// 役割:
/// - 検索条件の状態管理
/// - フィルタリングロジックの実行
/// - UIとビジネスロジックの分離
/// 
/// クリーンアーキテクチャにおける位置づけ:
/// - Presentation層の状態管理
/// - 単一責任の原則に従った専用Provider
class GymSearchFilterNotifier extends StateNotifier<GymSearchFilterState> {
  GymSearchFilterNotifier() : super(_initialState());

  static GymSearchFilterState _initialState() {
    // 全都道府県を初期化
    final prefectureMap = <String, bool>{};
    for (var prefecture in PrefectureConstants.allPrefectures) {
      prefectureMap[prefecture] = false;
    }

    // ジムタイプを初期化
    const gymTypeMap = <String, bool>{
      "ボルダリング": false,
      "リード": false,
      "スピード": false,
    };

    return GymSearchFilterState(
      selectedPrefectures: prefectureMap,
      selectedGymTypes: gymTypeMap,
      filteredGyms: [],
    );
  }

  /// 都道府県選択更新
  void updatePrefectureSelection(Map<String, bool> selectedPrefectures) {
    state = state.copyWith(selectedPrefectures: selectedPrefectures);
  }

  /// ジムタイプ選択更新
  void updateGymTypeSelection(Map<String, bool> selectedGymTypes) {
    state = state.copyWith(selectedGymTypes: selectedGymTypes);
  }

  /// フィルタリング実行
  void applyFilter(List<Gym> allGyms) {
    state = state.copyWith(isLoading: true);

    final selectedPrefs = state.selectedPrefectures.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toSet();
    
    final selectedTypes = state.selectedGymTypes.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toSet();

    final filteredGyms = allGyms.where((gym) {
      // 都道府県フィルター
      final matchesPref = selectedPrefs.isEmpty || selectedPrefs.contains(gym.prefecture);

      // ジムタイプフィルター
      final matchesType = selectedTypes.isEmpty ||
          (selectedTypes.contains('ボルダリング') && gym.isBoulderingGym) ||
          (selectedTypes.contains('リード') && gym.isLeadGym) ||
          (selectedTypes.contains('スピード') && gym.isSpeedGym);

      return matchesPref && matchesType;
    }).toList();

    state = state.copyWith(
      filteredGyms: filteredGyms,
      isLoading: false,
    );
  }

  /// フィルターリセット
  void resetFilter() {
    state = _initialState();
  }

  /// 選択された条件の数を取得
  int get selectedConditionCount {
    final prefCount = state.selectedPrefectures.values.where((v) => v).length;
    final typeCount = state.selectedGymTypes.values.where((v) => v).length;
    return prefCount + typeCount;
  }

  /// フィルターが適用されているかどうか
  bool get hasActiveFilter => selectedConditionCount > 0;
}

/// ジム検索フィルターProvider
final gymSearchFilterProvider = StateNotifierProvider<GymSearchFilterNotifier, GymSearchFilterState>(
  (ref) => GymSearchFilterNotifier(),
);