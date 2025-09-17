import '../repositories/favorite_repository.dart';
import '../exceptions/app_exceptions.dart';

/// 他ユーザーのイキタイジム詳細取得UseCase
/// 
/// 役割:
/// - 他ユーザーのお気に入りジム（イキタイジム）の詳細情報を取得
/// - 公開情報として認証なしでアクセス可能
/// 
/// クリーンアーキテクチャにおける位置づけ:
/// - Domain層のUseCase
/// - 他ユーザープロフィール表示機能で使用
class GetUserFavoriteGymsUseCase {
  final FavoriteRepository _favoriteRepository;

  GetUserFavoriteGymsUseCase(this._favoriteRepository);

  /// イキタイジム詳細情報を取得
  /// 
  /// [userId] 取得対象のユーザーID
  /// 
  /// 返り値:
  /// ジム詳細情報のリスト（名前、住所、営業時間等を含む）
  Future<List<Map<String, dynamic>>> execute(String userId) async {
    try {
      if (userId.trim().isEmpty) {
        throw const ValidationException(
          message: 'ユーザーIDは必須です',
          errors: {'userId': 'ユーザーIDを指定してください'},
          code: 'EMPTY_USER_ID',
        );
      }

      return await _favoriteRepository.getFavoriteGyms(userId);
    } catch (e) {
      if (e is AppException) rethrow;
      throw DataFetchException(
        message: 'イキタイジム詳細取得に失敗しました',
        originalError: e,
      );
    }
  }
}