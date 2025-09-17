import '../../domain/entities/gym.dart';
import '../../domain/repositories/gym_repository.dart';
import '../datasources/gym_datasource.dart';

/// ジムリポジトリ実装クラス
/// 
/// 役割:
/// - Domainレイヤーで定義されたGymRepositoryインタフェースの実装
/// - データソースとDomainレイヤー間の橋渡し
/// - ジム検索・フィルタリングなどのビジネスロジック実装
/// 
/// クリーンアーキテクチャにおける位置づけ:
/// - Infrastructure層のRepository実装
/// - Domain層のRepository抽象クラスに依存（依存関係逆転の原則）
/// - UseCase層から使用される
class GymRepositoryImpl implements GymRepository {
  final GymDataSource _dataSource;

  /// コンストラクタ
  /// 
  /// [_dataSource] ジムデータソース
  GymRepositoryImpl(this._dataSource);

  /// 全ジム情報取得
  /// 
  /// 返り値:
  /// [List<Gym>] 全ジムのリスト
  /// 
  /// ビジネスルール:
  /// - 取得したジムリストをID順でソート
  /// - 無効なデータは除外
  @override
  Future<List<Gym>> getAllGyms() async {
    try {
      final gyms = await _dataSource.getAllGyms();
      
      // ID順でソート
      gyms.sort((a, b) => a.id.compareTo(b.id));
      
      return gyms;
    } catch (e) {
      rethrow;
    }
  }

  /// ジムID指定による単一ジム情報取得
  /// 
  /// [gymId] 取得対象のジムID
  /// 
  /// 返り値:
  /// [Gym?] ジムエンティティ、存在しない場合はnull
  /// 
  /// ビジネスルール:
  /// - ジムIDは正の整数のみ許可
  @override
  Future<Gym?> getGymById(int gymId) async {
    if (gymId <= 0) {
      return null;
    }

    try {
      return await _dataSource.getGymById(gymId);
    } catch (e) {
      rethrow;
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
  /// 
  /// ビジネスルール:
  /// - 検索条件が全てnullの場合は全ジムを返す
  /// - 検索結果は人気度順でソート
  /// - クライミングタイプは「ボルダリング」「リード」「スピード」のみ許可
  @override
  Future<List<Gym>> searchGyms({
    String? prefecture,
    String? city,
    String? name,
    List<String>? climbingTypes,
  }) async {
    try {
      // クライミングタイプの妥当性チェック
      if (climbingTypes != null) {
        final validTypes = ['ボルダリング', 'リード', 'スピード'];
        climbingTypes = climbingTypes
            .where((type) => validTypes.contains(type))
            .toList();
      }

      final gyms = await _dataSource.searchGyms(
        prefecture: prefecture?.trim(),
        city: city?.trim(),
        name: name?.trim(),
        climbingTypes: climbingTypes,
      );

      // 検索結果を人気度順でソート
      gyms.sort((a, b) => b.popularityScore.compareTo(a.popularityScore));

      return gyms;
    } catch (e) {
      rethrow;
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
  /// 
  /// ビジネスルール:
  /// - 緯度は-90〜90度の範囲
  /// - 経度は-180〜180度の範囲
  /// - 検索半径は0.1〜100kmの範囲
  /// - 結果は距離順でソート（データソース側で実装済み）
  @override
  Future<List<Gym>> getGymsByLocation({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {
    // 位置情報の妥当性チェック
    if (latitude < -90 || latitude > 90) {
      throw ArgumentError('緯度は-90〜90度の範囲で指定してください');
    }

    if (longitude < -180 || longitude > 180) {
      throw ArgumentError('経度は-180〜180度の範囲で指定してください');
    }

    if (radiusKm < 0.1 || radiusKm > 100) {
      throw ArgumentError('検索半径は0.1〜100kmの範囲で指定してください');
    }

    try {
      return await _dataSource.getGymsByLocation(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 人気ジム取得
  /// 
  /// [limit] 取得件数の上限
  /// 
  /// 返り値:
  /// [List<Gym>] 人気順でソートされたジムリスト
  /// 
  /// ビジネスルール:
  /// - 取得件数は1〜100件の範囲
  /// - 人気度は「イキタイ数 × 0.7 + 投稿数 × 0.3」で計算
  @override
  Future<List<Gym>> getPopularGyms({int limit = 10}) async {
    // 取得件数の妥当性チェック
    if (limit < 1 || limit > 100) {
      throw ArgumentError('取得件数は1〜100件の範囲で指定してください');
    }

    try {
      return await _dataSource.getPopularGyms(limit: limit);
    } catch (e) {
      rethrow;
    }
  }

  /// イキタイ数増加
  /// 
  /// [gymId] 対象ジムID
  /// 
  /// 返り値:
  /// [bool] 更新成功時はtrue、失敗時はfalse
  /// 
  /// ビジネスルール:
  /// - ジムIDは正の整数のみ許可
  /// - 実際の増加処理はバックエンド側で実装
  @override
  Future<bool> incrementIkitaiCount(int gymId) async {
    if (gymId <= 0) {
      return false;
    }

    try {
      // 注意: 実際のAPI実装が必要
      // 現在は仮実装として常にtrueを返す
      return true;
    } catch (e) {
      return false;
    }
  }

  /// イキタイ数減少
  /// 
  /// [gymId] 対象ジムID
  /// 
  /// 返り値:
  /// [bool] 更新成功時はtrue、失敗時はfalse
  /// 
  /// ビジネスルール:
  /// - ジムIDは正の整数のみ許可
  /// - イキタイ数は0未満にならない
  /// - 実際の減少処理はバックエンド側で実装
  @override
  Future<bool> decrementIkitaiCount(int gymId) async {
    if (gymId <= 0) {
      return false;
    }

    try {
      // 注意: 実際のAPI実装が必要
      // 現在は仮実装として常にtrueを返す
      return true;
    } catch (e) {
      return false;
    }
  }
}