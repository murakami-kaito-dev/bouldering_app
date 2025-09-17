import '../../domain/repositories/favorite_repository.dart';
import '../datasources/favorite_datasource.dart';

/// お気に入り関係リポジトリ実装クラス
///
/// 役割:
/// - Domainレイヤーで定義されたFavoriteRepositoryインタフェースの実装
/// - データソースとDomainレイヤー間の橋渡し
/// - お気に入りユーザーとイキタイジムの関係管理ビジネスロジック実装
///
/// クリーンアーキテクチャにおける位置づけ:
/// - Infrastructure層のRepository実装
/// - Domain層のRepository抽象クラスに依存（依存関係逆転の原則）
/// - UseCase層から使用される
class FavoriteRepositoryImpl implements FavoriteRepository {
  final FavoriteDataSource _dataSource;

  /// コンストラクタ
  ///
  /// [_dataSource] お気に入り関係データソース
  FavoriteRepositoryImpl(this._dataSource);

  /// お気に入りユーザーID一覧取得
  ///
  /// [userId] 基準となるユーザーID
  ///
  /// 返り値:
  /// [List<String>] お気に入りに登録しているユーザーIDリスト
  ///
  /// ビジネスルール:
  /// - ユーザーIDは空文字不可
  /// - 結果はユーザーID順でソート
  /// - 重複は除外
  @override
  Future<List<String>> getFavoriteUserIds(String userId) async {
    if (userId.trim().isEmpty) {
      throw ArgumentError('ユーザーIDは必須です');
    }

    try {
      final favoriteUserIds = await _dataSource.getFavoriteUserIds(userId);

      // 重複除去とソート
      final uniqueIds = favoriteUserIds.toSet().toList();
      uniqueIds.sort();

      return uniqueIds;
    } catch (e) {
      rethrow;
    }
  }

  /// 自分をお気に入りに登録しているユーザーID一覧取得
  ///
  /// [userId] 基準となるユーザーID
  ///
  /// 返り値:
  /// [List<String>] 自分をお気に入りに登録しているユーザーIDリスト
  ///
  /// ビジネスルール:
  /// - ユーザーIDは空文字不可
  /// - 結果はユーザーID順でソート
  /// - 重複は除外
  @override
  Future<List<String>> getFavoritedByUserIds(String userId) async {
    if (userId.trim().isEmpty) {
      throw ArgumentError('ユーザーIDは必須です');
    }

    try {
      final favoritedByUserIds =
          await _dataSource.getFavoritedByUserIds(userId);

      // 重複除去とソート
      final uniqueIds = favoritedByUserIds.toSet().toList();
      uniqueIds.sort();

      return uniqueIds;
    } catch (e) {
      rethrow;
    }
  }

  /// お気に入りユーザー追加
  ///
  /// [likerUserId] お気に入りを追加するユーザーID
  /// [likeeUserId] お気に入りに追加されるユーザーID
  ///
  /// 返り値:
  /// [bool] 追加成功時はtrue、失敗時はfalse
  ///
  /// ビジネスルール:
  /// - 自分自身をお気に入りに追加することは不可
  /// - 既にお気に入り関係が存在する場合は処理をスキップ
  /// - ユーザーIDは空文字不可
  @override
  Future<bool> addFavoriteUser(String likerUserId, String likeeUserId) async {
    if (likerUserId.trim().isEmpty || likeeUserId.trim().isEmpty) {
      throw ArgumentError('ユーザーIDは必須です');
    }

    if (likerUserId == likeeUserId) {
      throw ArgumentError('自分自身をお気に入りに追加することはできません');
    }

    try {
      // 既存関係の確認
      final isAlreadyFavorite = await _dataSource.isFavoriteUser(
        likerUserId,
        likeeUserId,
      );

      if (isAlreadyFavorite) {
        return true; // 既に関係が存在するため成功として扱う
      }

      return await _dataSource.addFavoriteUser(likerUserId, likeeUserId);
    } catch (e) {
      rethrow;
    }
  }

  /// お気に入りユーザー削除
  ///
  /// [likerUserId] お気に入りを削除するユーザーID
  /// [likeeUserId] お気に入りから削除されるユーザーID
  ///
  /// 返り値:
  /// [bool] 削除成功時はtrue、失敗時はfalse
  ///
  /// ビジネスルール:
  /// - ユーザーIDは空文字不可
  /// - お気に入り関係が存在しない場合も成功として扱う
  @override
  Future<bool> removeFavoriteUser(
      String likerUserId, String likeeUserId) async {
    if (likerUserId.trim().isEmpty || likeeUserId.trim().isEmpty) {
      throw ArgumentError('ユーザーIDは必須です');
    }

    try {
      return await _dataSource.removeFavoriteUser(likerUserId, likeeUserId);
    } catch (e) {
      rethrow;
    }
  }

  /// お気に入りユーザー関係確認
  ///
  /// [likerUserId] お気に入りを確認するユーザーID
  /// [likeeUserId] お気に入りに登録されているか確認するユーザーID
  ///
  /// 返り値:
  /// [bool] お気に入り関係が存在する場合はtrue、しない場合はfalse
  ///
  /// ビジネスルール:
  /// - ユーザーIDは空文字不可
  /// - 自分自身への関係確認は常にfalse
  @override
  Future<bool> isFavoriteUser(String likerUserId, String likeeUserId) async {
    if (likerUserId.trim().isEmpty || likeeUserId.trim().isEmpty) {
      return false;
    }

    if (likerUserId == likeeUserId) {
      return false; // 自分自身は常にfalse
    }

    try {
      return await _dataSource.isFavoriteUser(likerUserId, likeeUserId);
    } catch (e) {
      return false; // エラー時はfalseを返す（安全側に倒す）
    }
  }

  /// イキタイジムID一覧取得
  ///
  /// [userId] 基準となるユーザーID
  ///
  /// 返り値:
  /// [List<int>] イキタイに登録しているジムIDリスト
  ///
  /// ビジネスルール:
  /// - ユーザーIDは空文字不可
  /// - 結果はジムID順でソート
  /// - 重複は除外
  /// - 無効なジムID（0以下）は除外
  @override
  Future<List<int>> getFavoriteGymIds(String userId) async {
    if (userId.trim().isEmpty) {
      throw ArgumentError('ユーザーIDは必須です');
    }

    try {
      final favoriteGymIds = await _dataSource.getFavoriteGymIds(userId);

      // 無効なIDを除外し、重複除去とソート
      final validIds = favoriteGymIds.where((id) => id > 0).toSet().toList();
      validIds.sort();

      return validIds;
    } catch (e) {
      rethrow;
    }
  }

  /// イキタイジム追加
  ///
  /// [userId] イキタイを追加するユーザーID
  /// [gymId] イキタイに追加するジムID
  ///
  /// 返り値:
  /// [bool] 追加成功時はtrue、失敗時はfalse
  ///
  /// ビジネスルール:
  /// - ユーザーIDは空文字不可
  /// - ジムIDは正の整数のみ許可
  /// - 既にイキタイ関係が存在する場合は処理をスキップ
  @override
  Future<bool> addFavoriteGym(String userId, int gymId) async {
    if (userId.trim().isEmpty) {
      throw ArgumentError('ユーザーIDは必須です');
    }

    if (gymId <= 0) {
      throw ArgumentError('ジムIDは正の整数で指定してください');
    }

    try {
      // 既存関係の確認
      final isAlreadyFavorite = await _dataSource.isFavoriteGym(userId, gymId);

      if (isAlreadyFavorite) {
        return true; // 既に関係が存在するため成功として扱う
      }

      return await _dataSource.addFavoriteGym(userId, gymId);
    } catch (e) {
      rethrow;
    }
  }

  /// イキタイジム削除
  ///
  /// [userId] イキタイを削除するユーザーID
  /// [gymId] イキタイから削除するジムID
  ///
  /// 返り値:
  /// [bool] 削除成功時はtrue、失敗時はfalse
  ///
  /// ビジネスルール:
  /// - ユーザーIDは空文字不可
  /// - ジムIDは正の整数のみ許可
  /// - イキタイ関係が存在しない場合も成功として扱う
  @override
  Future<bool> removeFavoriteGym(String userId, int gymId) async {
    if (userId.trim().isEmpty) {
      throw ArgumentError('ユーザーIDは必須です');
    }

    if (gymId <= 0) {
      throw ArgumentError('ジムIDは正の整数で指定してください');
    }

    try {
      return await _dataSource.removeFavoriteGym(userId, gymId);
    } catch (e) {
      rethrow;
    }
  }

  /// イキタイジム関係確認
  ///
  /// [userId] イキタイを確認するユーザーID
  /// [gymId] イキタイに登録されているか確認するジムID
  ///
  /// 返り値:
  /// [bool] イキタイ関係が存在する場合はtrue、しない場合はfalse
  ///
  /// ビジネスルール:
  /// - ユーザーIDは空文字不可
  /// - ジムIDは正の整数のみ許可
  @override
  Future<bool> isFavoriteGym(String userId, int gymId) async {
    if (userId.trim().isEmpty || gymId <= 0) {
      return false;
    }

    try {
      return await _dataSource.isFavoriteGym(userId, gymId);
    } catch (e) {
      return false; // エラー時はfalseを返す（安全側に倒す）
    }
  }

  /// 他ユーザーのお気に入りジム（イキタイジム）詳細情報を取得
  ///
  /// [userId] 取得対象のユーザーID
  ///
  /// 返り値:
  /// [List<Map<String, dynamic>>] お気に入りジム詳細情報リスト
  ///
  /// ビジネスルール:
  /// - ユーザーIDは空文字不可
  /// - 公開情報として認証なしでアクセス
  @override
  Future<List<Map<String, dynamic>>> getFavoriteGyms(String userId) async {
    if (userId.trim().isEmpty) {
      return [];
    }

    try {
      return await _dataSource.getFavoriteGyms(userId);
    } catch (e) {
      // エラー時は空リストを返す
      return [];
    }
  }
}
