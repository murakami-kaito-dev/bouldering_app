import '../repositories/user_repository.dart';
import '../exceptions/app_exceptions.dart';

/// ユーザープロフィール更新ユースケース
/// 
/// 複数のプロフィール情報を一括更新
class UpdateUserProfileUseCase {
  final UserRepository _userRepository;

  UpdateUserProfileUseCase(this._userRepository);

  Future<bool> execute({
    required String userId,
    String? userName,
    String? userIntroduce,
    String? favoriteGym,
    int? gender,
    DateTime? birthday,
    DateTime? boulStartDate,
    int? homeGymId,
  }) async {
    try {
      bool success = true;
      
      // ユーザー名の更新
      if (userName != null) {
        final result = await _userRepository.updateUserName(userId, userName);
        success &= result;
      }
      
      // 自己紹介・お気に入りジム情報の更新
      // "-"が渡された場合はクリアとして処理
      if (userIntroduce != null || favoriteGym != null) {
        final result = await _userRepository.updateUserProfile(
          userId: userId,
          userIntroduce: userIntroduce,
          favoriteGym: favoriteGym,
        );
        success &= result;
      }
      
      // 性別の更新
      if (gender != null) {
        final result = await _userRepository.updateUserGender(userId, gender);
        success &= result;
      }
      
      // 誕生日・ボルダリング開始日の更新
      if (birthday != null || boulStartDate != null) {
        final result = await _userRepository.updateUserDates(
          userId: userId,
          birthday: birthday,
          boulStartDate: boulStartDate,
        );
        success &= result;
      }
      
      // ホームジムの更新（0が渡された場合は「選択なし」として処理）
      if (homeGymId != null) {
        final result = await _userRepository.updateHomeGym(userId, homeGymId);
        success &= result;
      }
      
      return success;
    } catch (e) {
      throw DataSaveException(
        message: 'プロフィール更新に失敗しました',
        originalError: e,
      );
    }
  }
}

/// ユーザーアイコン更新ユースケース
/// 
/// 画像をアップロードしてアイコンURLを更新
class UpdateUserIconUseCase {
  final UserRepository _userRepository;

  UpdateUserIconUseCase(this._userRepository);

  Future<bool> execute(String userId, String imagePath) async {
    try {
      // 画像をストレージにアップロード
      final iconUrl = await _userRepository.uploadUserIcon(userId, imagePath);
      
      if (iconUrl == null) {
        // アップロード失敗
        return false;
      }
      
      // DBのアイコンURLを更新
      final updateResult = await _userRepository.updateUserIconUrl(userId, iconUrl);
      
      return updateResult;
    } catch (e) {
      throw DataSaveException(
        message: 'アイコン更新に失敗しました',
        originalError: e,
      );
    }
  }
}

/// ユーザー削除ユースケース
/// 
/// Cloud SQLからユーザー情報を削除
class DeleteUserUseCase {
  final UserRepository _userRepository;

  DeleteUserUseCase(this._userRepository);

  Future<bool> execute(String userId) async {
    try {
      return await _userRepository.deleteUser(userId);
    } catch (e) {
      throw DataSaveException(
        message: 'ユーザー削除に失敗しました',
        originalError: e,
      );
    }
  }
}

/// メールアドレス変更ユースケース
/// 
/// 役割:
/// - Cloud SQLでのメールアドレス更新処理
/// - バリデーション処理
/// 
/// 注意:
/// Firebase Authでのメール変更は AuthProvider で実行
class UpdateUserEmailUseCase {
  final UserRepository _userRepository;

  UpdateUserEmailUseCase(this._userRepository);

  /// メールアドレス更新を実行
  /// 
  /// [userId] ユーザーID
  /// [newEmail] 新しいメールアドレス
  /// 
  /// 例外:
  /// [ValidationException] バリデーションエラー
  /// [DataSaveException] データ保存エラー
  Future<bool> execute(String userId, String newEmail) async {
    // バリデーション
    if (userId.trim().isEmpty) {
      throw const ValidationException(
        message: 'ユーザーIDが必要です',
        errors: {'userId': 'ユーザーIDは必須です'},
        code: 'EMPTY_USER_ID',
      );
    }
    
    if (newEmail.trim().isEmpty) {
      throw const ValidationException(
        message: '新しいメールアドレスを入力してください',
        errors: {'email': '新しいメールアドレスは必須です'},
        code: 'EMPTY_EMAIL',
      );
    }

    // メールアドレス形式チェック
    final emailRegExp = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegExp.hasMatch(newEmail.trim())) {
      throw const ValidationException(
        message: '正しいメールアドレス形式で入力してください',
        errors: {'email': 'メールアドレスの形式が正しくありません'},
        code: 'INVALID_EMAIL_FORMAT',
      );
    }

    try {
      // Cloud SQLのメールアドレスを更新
      final result = await _userRepository.updateUserEmail(userId, newEmail.trim());
      return result;
    } catch (e) {
      if (e is ValidationException) {
        rethrow;
      }
      throw DataSaveException(
        message: 'メールアドレス更新に失敗しました',
        originalError: e,
      );
    }
  }
}