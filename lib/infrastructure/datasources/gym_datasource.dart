import 'dart:async';
import 'dart:math' as math;
import '../services/api_client.dart';
import '../services/gym_cache_service.dart';
import '../services/gym_photos_cache_service.dart';
import '../../domain/entities/gym.dart';
import '../../domain/entities/gym_photo.dart';
// TODO: 本番環境では以下のインポートをコメントアウトする
// import '../../shared/data/mock_data.dart';

/// ジムデータソースクラス
/// 
/// 役割:
/// - ジム関連のAPI通信を担当
/// - APIレスポンスとDomainエンティティ間の変換
/// - ジム情報、営業時間、統計データの取得処理
/// 
/// クリーンアーキテクチャにおける位置づけ:
/// - Infrastructure層のデータソースコンポーネント
/// - 外部API（ジム情報API）との通信窓口
/// - Repository実装から呼び出される
class GymDataSource {
  final ApiClient _apiClient;

  /// ジム全件の永続キャッシュ（null なら常にAPI取得＝従来動作）
  final GymCacheService? _cacheService;

  /// ジム写真の永続キャッシュ（null なら常にAPI取得＝従来動作）
  final GymPhotosCacheService? _photosCacheService;

  /// コンストラクタ
  ///
  /// [_apiClient] API通信クライアント
  /// [cacheService] ジム全件データの永続キャッシュ
  /// [photosCacheService] ジム写真URLリストの永続キャッシュ
  GymDataSource(
    this._apiClient, {
    GymCacheService? cacheService,
    GymPhotosCacheService? photosCacheService,
  })  : _cacheService = cacheService,
        _photosCacheService = photosCacheService;

  /// ジム写真セット取得
  ///
  /// 処理フロー:
  /// 1. REST API: GET /api/gyms/{gymId}/photos
  ///    バックエンドが「自前写真（GCS） or Google Places API」を判定して返す
  /// 2. 取得失敗時は例外を上位へ伝播する（Provider側が一定時間後の再試行を管理。
  ///    以前は空セットに丸めていたため、オフライン時の取得失敗が「写真なし」として
  ///    アプリ再起動まで固定される不具合があった）
  Future<GymPhotoSet> getGymPhotos(int gymId) async {
    // 永続キャッシュ優先（cache-first + stale-while-revalidate）。
    // オフラインや通信不安定時でも、一度表示したジムの写真リストを出せるようにする
    final cached = await _photosCacheService?.read(gymId);
    if (cached != null) {
      if (!cached.isFresh) {
        // TTL超過: キャッシュを即返しつつ、裏でファイルだけ更新
        unawaited(_refreshPhotosInBackground(gymId));
      }
      return GymPhotoSet.fromJson(cached.data);
    }

    final data = await _fetchGymPhotosRaw(gymId);
    if (data != null) {
      return GymPhotoSet.fromJson(data);
    }
    return GymPhotoSet.empty;
  }

  /// 写真セットの生JSONをAPIから取得し、キャッシュへ保存する
  Future<Map<String, dynamic>?> _fetchGymPhotosRaw(int gymId) async {
    final response = await _apiClient.get(
      endpoint: '/gyms/$gymId/photos',
      requireAuth: false,
    );
    final data = response['data'];
    if (data is Map<String, dynamic>) {
      await _photosCacheService?.write(gymId, data);
      return data;
    }
    return null;
  }

  /// TTL超過キャッシュの裏更新（ファイルのみ更新。失敗は無視＝オフライン耐性）
  Future<void> _refreshPhotosInBackground(int gymId) async {
    try {
      await _fetchGymPhotosRaw(gymId);
    } catch (_) {}
  }

  /// 全ジム情報取得
  ///
  /// 返り値:
  /// [List<Gym>] 全ジムのリスト
  ///
  /// 処理フロー:
  /// 1. REST API: GET /api/gyms で全ジム情報取得（基本情報+イキタイ数+投稿数含む）
  Future<List<Gym>> getAllGyms() async {
    // 永続キャッシュ優先（cache-first + stale-while-revalidate）。
    // ジム情報の大半（名前・住所・座標・営業時間・料金）は数日で変わらないため、
    // 431件×約1MBの取得を毎回行わない。イキタイ/ボル活数の鮮度は
    // 詳細画面の個別API（getGymById）が担保する。
    final cached = await _cacheService?.read();
    if (cached != null) {
      if (!cached.isFresh) {
        // TTL超過: キャッシュを即返しつつ、裏でファイルだけ更新（次回起動で反映）
        unawaited(_refreshCacheInBackground());
      }
      return _mapRawGymList(cached.data);
    }

    // キャッシュなし: APIから取得して保存
    return _fetchAndCacheAllGyms();
  }

  /// APIから全ジムを取得し、成功時に生JSONを永続キャッシュへ保存する
  Future<List<Gym>> _fetchAndCacheAllGyms() async {
    try {
      // REST APIで全ジム情報を取得（認証不要）
      final response = await _apiClient.get(
        endpoint: '/gyms',
        requireAuth: false,
      );

      final List<dynamic> gymsData = response['data'] ?? [];
      if (gymsData.isEmpty) {
        return [];
      }

      await _cacheService?.write(gymsData);
      return _mapRawGymList(gymsData);
    } catch (e) {
      throw Exception('ジム一覧の取得に失敗しました: $e');
    }
  }

  /// 生JSONリスト→Gymエンティティ変換（API直・キャッシュ読み出しの共通処理）
  List<Gym> _mapRawGymList(List<dynamic> gymsData) {
    return gymsData
        .where((item) => item != null)
        .map((item) => _mapToGymEntity(
              item,
              ikitaiCount: _parseInt(item['ikitai_count']) ?? 0,
              boulCount: _parseInt(item['boul_count']) ?? 0,
            ))
        .toList();
  }

  /// stale時の裏更新。失敗してもUIに影響させない（オフライン耐性）
  Future<void> _refreshCacheInBackground() async {
    try {
      await _fetchAndCacheAllGyms();
    } catch (_) {
      // 裏更新の失敗は無視（キャッシュ表示は継続、次回また試行される）
    }
  }

  /// ジムID指定による単一ジム情報取得
  /// 
  /// [gymId] 取得対象のジムID
  /// 
  /// 返り値:
  /// [Gym?] ジムエンティティ、存在しない場合はnull
  /// 
  /// 処理フロー:
  /// 1. REST API: GET /api/gyms/{gymId} で単一ジム情報取得
  Future<Gym?> getGymById(int gymId) async {
    try {
      // REST APIで単一ジム情報を取得（認証不要）
      final response = await _apiClient.get(
        endpoint: '/gyms/$gymId',
        requireAuth: false,
      );

      // APIレスポンスからジムデータを抽出
      final gymData = response['data'];
      if (gymData == null) {
        return null;
      }

      // APIレスポンスをGymエンティティに変換
      return _mapToGymEntity(
        gymData,
        ikitaiCount: _parseInt(gymData['ikitai_count']) ?? 0,
        boulCount: _parseInt(gymData['boul_count']) ?? 0,
      );
    } catch (e) {
      throw Exception('ジム詳細の取得に失敗しました: $e');
    }
  }

  /// ジム検索（複数条件）
  /// 
  /// [prefecture] 都道府県名（オプション）
  /// [city] 市区町村名（オプション）
  /// [name] ジム名（部分一致、オプション）
  /// [climbingTypes] クライミングタイプリスト（オプション）
  /// 
  /// 返り値:
  /// [List<Gym>] 検索条件に合致するジムリスト
  Future<List<Gym>> searchGyms({
    String? prefecture,
    String? city,
    String? name,
    List<String>? climbingTypes,
  }) async {
    try {
      // 全ジムデータを取得してフィルタリングを実行
      final allGyms = await getAllGyms();
      
      // 指定された条件でジムをフィルタリング
      return allGyms.where((gym) {
        // 都道府県フィルタ
        if (prefecture != null && !gym.prefecture.contains(prefecture)) {
          return false;
        }
        
        // 市区町村フィルタ
        if (city != null && !gym.city.contains(city)) {
          return false;
        }
        
        // ジム名フィルタ（部分一致）
        if (name != null && !gym.name.toLowerCase().contains(name.toLowerCase())) {
          return false;
        }
        
        // クライミングタイプフィルタ
        if (climbingTypes != null && climbingTypes.isNotEmpty) {
          final gymTypes = gym.climbingTypes;
          if (!climbingTypes.any((type) => gymTypes.contains(type))) {
            return false;
          }
        }
        
        return true;
      }).toList();
    } catch (e) {
      throw Exception('ジム検索に失敗しました: $e');
    }
  }

  /// 位置情報による近隣ジム取得
  /// 
  /// [latitude] 緯度
  /// [longitude] 経度
  /// [radiusKm] 検索半径（キロメートル）
  /// 
  /// 返り値:
  /// [List<Gym>] 指定範囲内のジムリスト（距離順）
  Future<List<Gym>> getGymsByLocation({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {
    try {
      // 全ジムデータを取得
      final allGyms = await getAllGyms();
      
      // 各ジムとの距離を計算し、指定半径内のジムをフィルタリング
      final nearbyGyms = allGyms
          .map((gym) => {
                'gym': gym,
                'distance': _calculateDistance(
                  latitude,
                  longitude,
                  gym.latitude,
                  gym.longitude,
                ),
              })
          .where((item) => (item['distance'] as double) <= radiusKm)
          .toList();
      
      // 距離順でソート
      nearbyGyms.sort((a, b) => 
          (a['distance'] as double).compareTo(b['distance'] as double));
      
      return nearbyGyms.map((item) => item['gym'] as Gym).toList();
    } catch (e) {
      throw Exception('近隣ジムの取得に失敗しました: $e');
    }
  }

  /// 人気ジム取得
  /// 
  /// [limit] 取得件数の上限
  /// 
  /// 返り値:
  /// [List<Gym>] 人気順でソートされたジムリスト
  Future<List<Gym>> getPopularGyms({int limit = 10}) async {
    try {
      // 全ジムデータを取得
      final allGyms = await getAllGyms();
      
      // 人気度でソート（イキタイ数 + 投稿数を基準）
      allGyms.sort((a, b) => b.popularityScore.compareTo(a.popularityScore));
      
      // 指定件数で制限して返却
      return allGyms.take(limit).toList();
    } catch (e) {
      throw Exception('人気ジムの取得に失敗しました: $e');
    }
  }

  /// APIレスポンスからGymエンティティにマッピング
  /// 
  /// [gymData] APIから取得したジムデータ
  /// [ikitaiCount] イキタイ数
  /// [boulCount] 投稿数
  /// 
  /// 返り値:
  /// [Gym] ジムエンティティ
  Gym _mapToGymEntity(
    Map<String, dynamic> gymData, {
    required int ikitaiCount,
    required int boulCount,
  }) {
    return Gym(
      id: _parseInt(gymData['gym_id']) ?? 0,
      name: gymData['gym_name'] ?? '-',
      hpLink: gymData['hp_link'] ?? '-',
      prefecture: gymData['prefecture'] ?? '-',
      city: gymData['city'] ?? '-',
      addressLine: gymData['address_line'] ?? '-',
      latitude: _parseDouble(gymData['latitude']) ?? 0.0,
      longitude: _parseDouble(gymData['longitude']) ?? 0.0,
      telNo: gymData['tel_no'] ?? '-',
      fee: gymData['fee'] ?? '-',
      minimumFee: _parseInt(gymData['minimum_fee']) ?? 0,
      equipmentRentalFee: gymData['equipment_rental_fee'] ?? '-',
      ikitaiCount: ikitaiCount,
      boulCount: boulCount,
      // 注意: APIの実キーは is_bouldering_gym（旧実装は存在しない 'is_bouldering_type' を
      // 読んでおり、?? true により全ジムがボルダリング可と誤判定されていた）
      isBoulderingGym: gymData['is_bouldering_gym'] ?? true,
      isLeadGym: gymData['is_lead_gym'] ?? false,
      isSpeedGym: gymData['is_speed_gym'] ?? false,
      hours: _mapToGymHours(gymData),
    );
  }

  /// 営業時間データをGymHoursエンティティにマッピング
  /// 
  /// [gymData] ジムデータ
  /// 
  /// 返り値:
  /// [GymHours] 営業時間エンティティ
  GymHours _mapToGymHours(Map<String, dynamic> gymData) {
    return GymHours(
      sunOpen: gymData['sun_open'],
      sunClose: gymData['sun_close'],
      monOpen: gymData['mon_open'],
      monClose: gymData['mon_close'],
      tueOpen: gymData['tue_open'],
      tueClose: gymData['tue_close'],
      wedOpen: gymData['wed_open'],
      wedClose: gymData['wed_close'],
      thuOpen: gymData['thu_open'],
      thuClose: gymData['thu_close'],
      friOpen: gymData['fri_open'], // 注意: APIのキー名確認が必要（'fir_open'の可能性）
      friClose: gymData['fri_close'],
      satOpen: gymData['sat_open'],
      satClose: gymData['sat_close'],
    );
  }

  /// 文字列をintに安全に変換
  /// 
  /// [value] 変換対象の値
  /// 
  /// 返り値:
  /// [int?] 変換結果、失敗時はnull
  int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// 文字列をdoubleに安全に変換
  /// 
  /// [value] 変換対象の値
  /// 
  /// 返り値:
  /// [double?] 変換結果、失敗時はnull
  double? _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// 2点間の距離を計算（ハーバーシン公式）
  /// 
  /// [lat1] 地点1の緯度
  /// [lon1] 地点1の経度
  /// [lat2] 地点2の緯度
  /// [lon2] 地点2の経度
  /// 
  /// 返り値:
  /// [double] 距離（キロメートル）
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371.0; // 地球の半径（km）
    
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);
    
    final double a = 
        (dLat / 2) * (dLat / 2) +
        _cos(_toRadians(lat1)) * _cos(_toRadians(lat2)) *
        (dLon / 2) * (dLon / 2);
    
    final double c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));
    
    return earthRadius * c;
  }

  /// 度をラジアンに変換
  double _toRadians(double degree) => degree * (3.14159265359 / 180);
  
  /// 数学関数のヘルパー
  double _cos(double x) => math.cos(x);
  double _sqrt(double x) => math.sqrt(x);
  double _atan2(double y, double x) => math.atan2(y, x);
}