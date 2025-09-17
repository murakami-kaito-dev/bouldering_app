import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/gym.dart';
import '../../domain/usecases/gym_usecases.dart';
import 'dependency_injection.dart';

/// ジム情報状態管理Provider
/// 
/// 役割:
/// - 全ジム情報のキャッシュと管理
/// - ジム検索・フィルタリング機能
/// - 位置情報による近隣ジム検索
/// 
/// クリーンアーキテクチャにおける位置づけ:
/// - Presentation層の状態管理
/// - Domain層のUseCaseを呼び出し
/// - UIコンポーネントから参照される

/// ジム検索条件
class GymSearchFilter {
  final String? prefecture;
  final String? city;
  final String? name;
  final List<String>? climbingTypes;

  const GymSearchFilter({
    this.prefecture,
    this.city,
    this.name,
    this.climbingTypes,
  });

  /// 検索条件をコピーして新しいインスタンスを作成
  GymSearchFilter copyWith({
    String? prefecture,
    String? city,
    String? name,
    List<String>? climbingTypes,
  }) {
    return GymSearchFilter(
      prefecture: prefecture ?? this.prefecture,
      city: city ?? this.city,
      name: name ?? this.name,
      climbingTypes: climbingTypes ?? this.climbingTypes,
    );
  }

  /// 検索条件が空かどうか判定
  bool get isEmpty => 
      prefecture == null && 
      city == null && 
      name == null && 
      (climbingTypes == null || climbingTypes!.isEmpty);
}

/// ジム一覧状態を管理するStateNotifier
class GymListNotifier extends StateNotifier<AsyncValue<List<Gym>>> {
  final SearchGymsUseCase _searchGymsUseCase;
  final GetPopularGymsUseCase _getPopularGymsUseCase;
  final GetNearbyGymsUseCase _getNearbyGymsUseCase;
  
  GymSearchFilter _currentFilter = const GymSearchFilter();

  /// コンストラクタ
  /// 
  /// [_searchGymsUseCase] ジム検索ユースケース
  /// [_getPopularGymsUseCase] 人気ジム取得ユースケース
  /// [_getNearbyGymsUseCase] 近隣ジム取得ユースケース
  GymListNotifier(
    this._searchGymsUseCase,
    this._getPopularGymsUseCase,
    this._getNearbyGymsUseCase,
  ) : super(const AsyncValue.loading()) {
    // 初期化時に全ジムを読み込み
    loadAllGyms();
  }

  /// 現在の検索フィルタを取得
  GymSearchFilter get currentFilter => _currentFilter;

  /// 全ジム情報を読み込み
  /// 
  /// アプリ起動時や更新時に実行
  Future<void> loadAllGyms() async {
    state = const AsyncValue.loading();

    try {
      final gyms = await _searchGymsUseCase.execute();
      state = AsyncValue.data(gyms);
      _currentFilter = const GymSearchFilter(); // フィルタをリセット
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// ジム検索実行
  /// 
  /// [filter] 検索条件
  /// 
  /// 検索条件に基づいてジム一覧をフィルタリング
  Future<void> searchGyms(GymSearchFilter filter) async {
    state = const AsyncValue.loading();
    _currentFilter = filter;

    try {
      final gyms = await _searchGymsUseCase.execute(
        prefecture: filter.prefecture,
        city: filter.city,
        name: filter.name,
        climbingTypes: filter.climbingTypes,
      );
      
      state = AsyncValue.data(gyms);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// 人気ジム取得
  /// 
  /// [limit] 取得件数（デフォルト: 10件）
  /// 
  /// イキタイ数と投稿数に基づく人気ジムを取得
  Future<void> loadPopularGyms({int limit = 10}) async {
    state = const AsyncValue.loading();

    try {
      final gyms = await _getPopularGymsUseCase.execute(limit: limit);
      state = AsyncValue.data(gyms);
      _currentFilter = const GymSearchFilter(); // フィルタをリセット
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// 近隣ジム検索
  /// 
  /// [latitude] 緯度
  /// [longitude] 経度
  /// [radiusKm] 検索半径（キロメートル、デフォルト: 10km）
  /// 
  /// 指定位置から半径内のジムを距離順で取得
  Future<void> searchNearbyGyms({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
  }) async {
    state = const AsyncValue.loading();

    try {
      final gyms = await _getNearbyGymsUseCase.execute(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      );
      
      state = AsyncValue.data(gyms);
      _currentFilter = const GymSearchFilter(); // フィルタをリセット
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// 検索フィルタをクリア
  /// 
  /// 全ジム表示に戻す
  Future<void> clearFilter() async {
    if (_currentFilter.isEmpty) return; // 既にクリアされている場合はスキップ
    
    await loadAllGyms();
  }

  /// ジム一覧を手動更新
  /// 
  /// プルリフレッシュなどで使用
  Future<void> refresh() async {
    if (_currentFilter.isEmpty) {
      await loadAllGyms();
    } else {
      await searchGyms(_currentFilter);
    }
  }
}

/// ジム詳細状態を管理するStateNotifier
class GymDetailNotifier extends StateNotifier<AsyncValue<Gym?>> {
  final GetGymDetailsUseCase _getGymDetailsUseCase;

  /// コンストラクタ
  /// 
  /// [_getGymDetailsUseCase] ジム詳細取得ユースケース
  GymDetailNotifier(this._getGymDetailsUseCase) : super(const AsyncValue.data(null));

  /// ジム詳細情報を取得
  /// 
  /// [gymId] 取得対象のジムID
  /// 
  /// 指定されたジムの詳細情報を取得
  Future<void> loadGymDetail(int gymId) async {
    if (gymId <= 0) {
      state = AsyncValue.error(
        ArgumentError('無効なジムIDです'),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncValue.loading();

    try {
      final gym = await _getGymDetailsUseCase.execute(gymId);
      state = AsyncValue.data(gym);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// ジム詳細をクリア
  /// 
  /// ページ遷移時などに使用
  void clearGymDetail() {
    state = const AsyncValue.data(null);
  }
}

// ==================== Provider定義 ====================

/// ジム一覧状態管理Provider
/// 
/// アプリケーション全体でジム一覧を管理
final gymListProvider = StateNotifierProvider<GymListNotifier, AsyncValue<List<Gym>>>((ref) {
  final searchGymsUseCase = ref.read(searchGymsUseCaseProvider);
  final getPopularGymsUseCase = ref.read(getPopularGymsUseCaseProvider);
  final getNearbyGymsUseCase = ref.read(getNearbyGymsUseCaseProvider);

  return GymListNotifier(
    searchGymsUseCase,
    getPopularGymsUseCase,
    getNearbyGymsUseCase,
  );
});

/// ジム詳細状態管理Provider
/// 
/// 選択されたジムの詳細情報を管理
final gymDetailProvider = StateNotifierProvider<GymDetailNotifier, AsyncValue<Gym?>>((ref) {
  final getGymDetailsUseCase = ref.read(getGymDetailsUseCaseProvider);

  return GymDetailNotifier(getGymDetailsUseCase);
});

/// 現在の検索フィルタProvider
/// 
/// 現在適用されている検索条件を取得
final currentGymFilterProvider = Provider<GymSearchFilter>((ref) {
  final gymListNotifier = ref.read(gymListProvider.notifier);
  return gymListNotifier.currentFilter;
});

/// ジム検索状態Provider
/// 
/// 検索中かどうかの状態を判定
final isGymSearchingProvider = Provider<bool>((ref) {
  final gymListState = ref.watch(gymListProvider);
  return gymListState.maybeWhen(
    loading: () => true,
    orElse: () => false,
  );
});

/// フィルタ適用状態Provider
/// 
/// 検索フィルタが適用されているかどうかを判定
final isGymFilterAppliedProvider = Provider<bool>((ref) {
  final filter = ref.watch(currentGymFilterProvider);
  return !filter.isEmpty;
});

/// ジムマップProvider
/// 
/// ジムIDをキーとするジム情報のマップを提供
/// 他ユーザープロフィール表示などで使用
final gymMapProvider = Provider<Map<int, Gym>>((ref) {
  final gymListState = ref.watch(gymListProvider);
  
  return gymListState.maybeWhen(
    data: (gyms) {
      final Map<int, Gym> gymMap = {};
      for (final gym in gyms) {
        gymMap[gym.id] = gym;
      }
      return gymMap;
    },
    orElse: () => <int, Gym>{},
  );
});