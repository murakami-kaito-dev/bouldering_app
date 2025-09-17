import 'dart:math' as math;
import '../services/api_client.dart';
import '../../domain/entities/gym.dart';
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

  /// コンストラクタ
  /// 
  /// [_apiClient] API通信クライアント
  GymDataSource(this._apiClient);

  /// 全ジム情報取得
  /// 
  /// 返り値:
  /// [List<Gym>] 全ジムのリスト
  /// 
  /// 処理フロー:
  /// 1. REST API: GET /api/gyms で全ジム情報取得（基本情報+イキタイ数+投稿数含む）
  Future<List<Gym>> getAllGyms() async {
    try {
      // REST APIで全ジム情報を取得（認証不要）
      final response = await _apiClient.get(
        endpoint: '/gyms',
        requireAuth: false,
      );
      
      // APIレスポンスからジムデータを抽出
      final List<dynamic> gymsData = response['data'] ?? [];
      
      if (gymsData.isEmpty) {
        return [];
      }
      
      // APIレスポンスをGymエンティティに変換
      final gyms = gymsData
          .where((item) => item != null)
          .map((item) => _mapToGymEntity(
                item,
                ikitaiCount: _parseInt(item['ikitai_count']) ?? 0,
                boulCount: _parseInt(item['boul_count']) ?? 0,
              ))
          .toList();
      
      return gyms;
    } catch (e) {
      throw Exception('ジム一覧の取得に失敗しました: $e');
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
      isBoulderingGym: gymData['is_bouldering_type'] ?? true,
      isLeadGym: gymData['is_lead_gym'] ?? false,
      isSpeedGym: gymData['is_speed_gym'] ?? false,
      hours: _mapToGymHours(gymData),
      photoUrls: _parsePhotoUrls(gymData['gym_photos']),
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

  /// 写真URLリストをパース
  /// 
  /// [photoData] 写真データ
  /// 
  /// 返り値:
  /// [List<String>] 写真URLリスト
  List<String> _parsePhotoUrls(dynamic photoData) {
    if (photoData == null) return [];
    if (photoData is List) {
      return photoData.map((url) => url.toString()).toList();
    }
    return [];
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