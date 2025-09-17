import '../repositories/favorite_repository.dart';
import '../repositories/user_repository.dart';
import '../entities/user.dart';
import '../exceptions/app_exceptions.dart';

/// お気に入りユーザー管理ユースケース
/// 
/// お気に入りユーザーの追加・削除・取得を管理
class ManageFavoriteUserUseCase {
  final FavoriteRepository _favoriteRepository;

  ManageFavoriteUserUseCase(this._favoriteRepository);

  /// お気に入りユーザーを追加
  Future<bool> addFavorite(String likerUserId, String likeeUserId) async {
    try {
      // 自分自身をお気に入りに追加できないことをチェック
      if (likerUserId == likeeUserId) {
        throw const BusinessRuleException(
          message: '自分自身をお気に入りに追加することはできません',
          code: 'SELF_FAVORITE_NOT_ALLOWED',
        );
      }

      // 既にお気に入りに追加されているかチェック
      final isAlreadyFavorite = await _favoriteRepository.isFavoriteUser(
        likerUserId,
        likeeUserId,
      );

      if (isAlreadyFavorite) {
        throw const BusinessRuleException(
          message: '既にお気に入りに追加されています',
          code: 'ALREADY_FAVORITE',
        );
      }

      // お気に入り関係を追加
      final result = await _favoriteRepository.addFavoriteUser(
          likerUserId, likeeUserId);
      return result;
    } catch (e) {
      if (e is AppException) rethrow;
      throw DataSaveException(
        message: 'お気に入り追加に失敗しました',
        originalError: e,
      );
    }
  }

  /// お気に入りユーザーを削除
  Future<bool> removeFavorite(String likerUserId, String likeeUserId) async {
    try {
      return await _favoriteRepository.removeFavoriteUser(
          likerUserId, likeeUserId);
    } catch (e) {
      if (e is AppException) rethrow;
      throw DataSaveException(
        message: 'お気に入り削除に失敗しました',
        originalError: e,
      );
    }
  }

  /// お気に入りユーザー一覧を取得
  Future<List<String>> getFavoriteUsers(String userId) async {
    try {
      return await _favoriteRepository.getFavoriteUserIds(userId);
    } catch (e) {
      if (e is AppException) rethrow;
      throw DataFetchException(
        message: 'お気に入りユーザー取得に失敗しました',
        originalError: e,
      );
    }
  }
}

/// お気に入りユーザーの詳細情報取得UseCase
/// 
/// 役割:
/// - お気に入りユーザーのID一覧を取得
/// - 各ユーザーの詳細情報を取得して統合
/// 
/// クリーンアーキテクチャにおける位置づけ:
/// - Domain層のUseCase
/// - 複数のRepositoryを協調させて複雑なビジネスロジックを実行
class GetFavoriteUserDetailsUseCase {
  final FavoriteRepository _favoriteRepository;
  final UserRepository _userRepository;

  GetFavoriteUserDetailsUseCase(this._favoriteRepository, this._userRepository);

  /// お気に入りユーザーの詳細情報を取得
  /// 
  /// [userId] 基準となるユーザーID
  /// 
  /// 返り値:
  /// お気に入りユーザーの詳細情報リスト
  Future<List<User>> getFavoriteUsersWithDetails(String userId) async {
    try {
      // まずお気に入りユーザーのID一覧を取得
      final favoriteUserIds = await _favoriteRepository.getFavoriteUserIds(userId);
      
      if (favoriteUserIds.isEmpty) {
        return [];
      }

      // 各ユーザーの詳細情報を取得（他ユーザーのプロフィール）
      final List<User> favoriteUsers = [];
      for (final favoriteUserId in favoriteUserIds) {
        try {
          final user = await _userRepository.getUserProfile(favoriteUserId);
          if (user != null) {
            favoriteUsers.add(user);
          }
        } catch (e) {
          // 個別のユーザー取得に失敗しても他のユーザーは取得を続ける
          // エラーログは上位層（Provider）で処理
        }
      }

      return favoriteUsers;
    } catch (e) {
      if (e is AppException) rethrow;
      throw DataFetchException(
        message: 'お気に入りユーザー詳細取得に失敗しました',
        originalError: e,
      );
    }
  }
}

/// お気に入られユーザーの詳細情報取得UseCase
/// 
/// 役割:
/// - 自分をお気に入り登録しているユーザーのID一覧を取得
/// - 各ユーザーの詳細情報を取得して統合
/// 
/// クリーンアーキテクチャにおける位置づけ:
/// - Domain層のUseCase
/// - 複数のRepositoryを協調させて複雑なビジネスロジックを実行
class GetFavoritedByUserDetailsUseCase {
  final FavoriteRepository _favoriteRepository;
  final UserRepository _userRepository;

  GetFavoritedByUserDetailsUseCase(this._favoriteRepository, this._userRepository);

  /// 自分をお気に入り登録しているユーザーの詳細情報を取得
  /// 
  /// [userId] 基準となるユーザーID（自分）
  /// 
  /// 返り値:
  /// 自分をお気に入り登録しているユーザーの詳細情報リスト
  Future<List<User>> getFavoritedByUsersWithDetails(String userId) async {
    try {
      // まず自分をお気に入り登録しているユーザーのID一覧を取得
      final favoritedByUserIds = await _favoriteRepository.getFavoritedByUserIds(userId);
      
      if (favoritedByUserIds.isEmpty) {
        return [];
      }

      // 各ユーザーの詳細情報を取得（他ユーザーのプロフィール）
      final List<User> favoritedByUsers = [];
      for (final favoritedByUserId in favoritedByUserIds) {
        try {
          final user = await _userRepository.getUserProfile(favoritedByUserId);
          if (user != null) {
            favoritedByUsers.add(user);
          }
        } catch (e) {
          // 個別のユーザー取得に失敗しても他のユーザーは取得を続ける
          // エラーログは上位層（Provider）で処理
        }
      }

      return favoritedByUsers;
    } catch (e) {
      if (e is AppException) rethrow;
      throw DataFetchException(
        message: 'お気に入られユーザー詳細取得に失敗しました',
        originalError: e,
      );
    }
  }
}

/// お気に入りジム管理ユースケース
/// 
/// イキタイジムの追加・削除・取得を管理
class ManageFavoriteGymUseCase {
  final FavoriteRepository _favoriteRepository;

  ManageFavoriteGymUseCase(this._favoriteRepository);

  /// イキタイジムを追加
  Future<bool> addFavoriteGym(String userId, int gymId) async {
    try {
      // 既にイキタイジムに追加されているかチェック
      final isAlreadyFavorite =
          await _favoriteRepository.isFavoriteGym(userId, gymId);

      if (isAlreadyFavorite) {
        throw const BusinessRuleException(
          message: '既にイキタイジムに追加されています',
          code: 'ALREADY_FAVORITE',
        );
      }

      // イキタイジムに追加
      return await _favoriteRepository.addFavoriteGym(userId, gymId);
    } catch (e) {
      if (e is AppException) rethrow;
      throw DataSaveException(
        message: 'イキタイジム追加に失敗しました',
        originalError: e,
      );
    }
  }

  /// イキタイジムを削除
  Future<bool> removeFavoriteGym(String userId, int gymId) async {
    try {
      return await _favoriteRepository.removeFavoriteGym(userId, gymId);
    } catch (e) {
      if (e is AppException) rethrow;
      throw DataSaveException(
        message: 'イキタイジム削除に失敗しました',
        originalError: e,
      );
    }
  }

  /// イキタイジム一覧を取得
  Future<List<int>> getFavoriteGyms(String userId) async {
    try {
      return await _favoriteRepository.getFavoriteGymIds(userId);
    } catch (e) {
      if (e is AppException) rethrow;
      throw DataFetchException(
        message: 'イキタイジム取得に失敗しました',
        originalError: e,
      );
    }
  }
}
