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
  /// [newEmail] 登録するメールアドレス。null なら未登録に戻す
  /// 
  /// 例外:
  /// [ValidationException] 形式エラー、または別アカウントで登録済み（code: EMAIL_ALREADY_REGISTERED）
  /// [DataSaveException] データ保存エラー
  Future<bool> execute(String userId, String? newEmail) async {
    // バリデーション
    if (userId.trim().isEmpty) {
      throw const ValidationException(
        message: 'ユーザーIDが必要です',
        errors: {'userId': 'ユーザーIDは必須です'},
        code: 'EMPTY_USER_ID',
      );
    }

    final trimmed = newEmail?.trim();
    if (trimmed != null) {
      if (trimmed.isEmpty) {
        throw const ValidationException(
          message: 'メールアドレスを入力してください',
          errors: {'email': 'メールアドレスが空です'},
          code: 'EMPTY_EMAIL',
        );
      }
      // メールアドレス形式チェック
      final emailRegExp = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
      if (!emailRegExp.hasMatch(trimmed)) {
        throw const ValidationException(
          message: '正しいメールアドレス形式で入力してください',
          errors: {'email': 'メールアドレスの形式が正しくありません'},
          code: 'INVALID_EMAIL_FORMAT',
        );
      }
    }

    try {
      // DB のメールアドレスを更新（null = 未登録に戻す）
      final result = await _userRepository.updateUserEmail(userId, trimmed);
      return result;
    } catch (e) {
      if (e is ValidationException) {
        rethrow;
      }
      // 1アカウント:1メールの制約に当たった（別のアカウントが同じメールを登録済み）
      if (e.toString().contains('Status 409')) {
        throw const ValidationException(
          message: 'このメールアドレスは別のアカウントで登録済みです',
          errors: {'email': '別のアカウントで登録済み'},
          code: 'EMAIL_ALREADY_REGISTERED',
        );
      }
      throw DataSaveException(
        message: 'メールアドレス更新に失敗しました',
        originalError: e,
      );
    }
  }
}
/// 通知用メールアドレスの登録申請ユースケース
///
/// バックエンドが確認メール（Brevo）を送り、ユーザーがリンクを押した時点で DB に確定する。
/// Firebase の認証は関与しないので、再認証もログアウトも起きない。
class RequestEmailVerificationUseCase {
  final UserRepository _userRepository;

  RequestEmailVerificationUseCase(this._userRepository);

  /// 返り値: 'sent' / 'already_registered'
  ///
  /// 例外:
  /// [ValidationException] 形式エラー / 別アカウントで登録済み（EMAIL_ALREADY_REGISTERED）/
  ///   連打（TOO_MANY_REQUESTS）
  /// [DataSaveException] 送信基盤が未設定（EMAIL_VERIFICATION_UNAVAILABLE）/ 送信失敗（MAIL_SEND_FAILED）
  Future<String> execute(String userId, String email) async {
    final trimmed = email.trim();
    if (userId.trim().isEmpty) {
      throw const ValidationException(
        message: 'ユーザーIDが必要です',
        errors: {'userId': 'ユーザーIDは必須です'},
        code: 'EMPTY_USER_ID',
      );
    }
    final emailRegExp = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (trimmed.isEmpty || !emailRegExp.hasMatch(trimmed)) {
      throw const ValidationException(
        message: '正しいメールアドレス形式で入力してください',
        errors: {'email': 'メールアドレスの形式が正しくありません'},
        code: 'INVALID_EMAIL_FORMAT',
      );
    }

    try {
      return await _userRepository.requestEmailVerification(userId, trimmed);
    } catch (e) {
      final s = e.toString();
      if (s.contains('Status 409')) {
        throw const ValidationException(
          message: 'このメールアドレスは別のアカウントで登録済みです',
          errors: {'email': '別のアカウントで登録済み'},
          code: 'EMAIL_ALREADY_REGISTERED',
        );
      }
      if (s.contains('Status 429')) {
        throw const ValidationException(
          message: '確認メールを送ったばかりです。1分ほど待ってからもう一度お試しください',
          errors: {'email': '再送は1分後'},
          code: 'TOO_MANY_REQUESTS',
        );
      }
      if (s.contains('Status 503')) {
        throw DataSaveException(
          message: 'メールアドレス登録は現在準備中です',
          code: 'EMAIL_VERIFICATION_UNAVAILABLE',
          originalError: e,
        );
      }
      if (s.contains('Status 502')) {
        throw DataSaveException(
          message: '確認メールを送信できませんでした。時間をおいてお試しください',
          code: 'MAIL_SEND_FAILED',
          originalError: e,
        );
      }
      throw DataSaveException(message: 'メールアドレスの登録申請に失敗しました', originalError: e);
    }
  }
}
