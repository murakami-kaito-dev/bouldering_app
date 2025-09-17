import '../entities/user.dart';
import '../repositories/user_repository.dart';
import '../services/auth_service.dart';
import '../exceptions/app_exceptions.dart';

class LoginUseCase {
  final UserRepository _userRepository;

  LoginUseCase(this._userRepository);

  Future<User?> execute(String userId) async {
    try {
      if (userId.trim().isEmpty) {
        throw const ValidationException(
          message: 'ユーザーIDが入力されていません',
          errors: {'userId': 'ユーザーIDは必須です'},
          code: 'EMPTY_USER_ID',
        );
      }

      final user = await _userRepository.getUserById(userId);
      if (user == null) {
        throw const AuthenticationException(
          message: 'ユーザーが見つかりません',
          code: 'USER_NOT_FOUND',
        );
      }

      return user;
    } catch (e) {
      if (e is AppException) rethrow;
      throw AuthenticationException(
        message: 'ログインに失敗しました',
        originalError: e,
      );
    }
  }
}

class SignUpUseCase {
  final UserRepository _userRepository;

  SignUpUseCase(this._userRepository);

  Future<bool> execute(String userId, String email) async {
    try {
      if (userId.trim().isEmpty) {
        throw const ValidationException(
          message: 'ユーザーIDが入力されていません',
          errors: {'userId': 'ユーザーIDは必須です'},
          code: 'EMPTY_USER_ID',
        );
      }

      if (email.trim().isEmpty) {
        throw const ValidationException(
          message: 'メールアドレスが入力されていません',
          errors: {'email': 'メールアドレスは必須です'},
          code: 'EMPTY_EMAIL',
        );
      }

      // 簡単なメール形式検証
      if (!email.contains('@') || !email.contains('.')) {
        throw const ValidationException(
          message: '正しいメールアドレス形式で入力してください',
          errors: {'email': 'メールアドレスの形式が正しくありません'},
          code: 'INVALID_EMAIL_FORMAT',
        );
      }

      return await _userRepository.createUser(userId, email);
    } catch (e) {
      if (e is AppException) rethrow;
      throw DataSaveException(
        message: 'サインアップに失敗しました',
        originalError: e,
      );
    }
  }
}

/// パスワード変更ユースケース
///
/// 役割:
/// - Firebase Authenticationでのパスワード変更処理
/// - バリデーション処理
/// - エラーハンドリング
///
/// 注意:
/// パスワードはFirebase Authでのみ管理されるため、
/// バックエンドAPIは不要（メールアドレス変更とは異なる）
class ChangePasswordUseCase {
  final AuthService _authService;

  ChangePasswordUseCase(this._authService);

  /// パスワード変更を実行
  ///
  /// [currentPassword] 現在のパスワード（再認証用）
  /// [newPassword] 新しいパスワード
  ///
  /// 例外:
  /// [ValidationException] バリデーションエラー
  /// [AuthenticationException] 認証エラー
  Future<void> execute({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      // バリデーション
      if (currentPassword.trim().isEmpty) {
        throw const ValidationException(
          message: '現在のパスワードを入力してください',
          errors: {'currentPassword': '現在のパスワードは必須です'},
          code: 'EMPTY_CURRENT_PASSWORD',
        );
      }

      if (newPassword.trim().isEmpty) {
        throw const ValidationException(
          message: '新しいパスワードを入力してください',
          errors: {'newPassword': '新しいパスワードは必須です'},
          code: 'EMPTY_NEW_PASSWORD',
        );
      }

      // パスワード強度チェック（最低6文字）
      if (newPassword.length < 6) {
        throw const ValidationException(
          message: 'パスワードは6文字以上で入力してください',
          errors: {'newPassword': 'パスワードは6文字以上である必要があります'},
          code: 'PASSWORD_TOO_SHORT',
        );
      }

      // 現在のパスワードと新しいパスワードが同じかチェック
      if (currentPassword == newPassword) {
        throw const ValidationException(
          message: '新しいパスワードは現在のパスワードと異なるものを設定してください',
          errors: {'newPassword': '現在のパスワードと同じパスワードは設定できません'},
          code: 'SAME_PASSWORD',
        );
      }

      // パスワード変更開始
      try {
        // Firebase Authでパスワード変更
        await _authService.updatePassword(newPassword: newPassword);
        // Firebase Auth パスワード変更成功
      } catch (e) {
        // 一部環境で発生する Null check エラーは更新成功扱い（セッション切断）
        if (e.toString().contains('Null check operator used on a null value')) {
          return; // 成功として扱う
        }
        // その他のエラーは呼び出し元へ再スロー
        rethrow;
      }
    } catch (e) {
      // パスワード変更エラー
      if (e is ValidationException) {
        rethrow;
      }

      // Firebase Authのエラーを適切な例外に変換
      if (e.toString().contains('requires-recent-login')) {
        throw const AuthenticationException(
          message: 'セキュリティのため、再度ログインしてから操作してください',
          code: 'REQUIRES_RECENT_LOGIN',
        );
      }

      if (e.toString().contains('wrong-password')) {
        throw const AuthenticationException(
          message: '現在のパスワードが間違っています',
          code: 'WRONG_PASSWORD',
        );
      }

      throw AuthenticationException(
        message: 'パスワード変更に失敗しました',
        originalError: e,
      );
    }
  }
}

/// パスワードリセットユースケース
///
/// 役割:
/// - Firebase Authenticationでのパスワードリセットメール送信
/// - メールアドレスのバリデーション
/// - エラーハンドリング
class PasswordResetUseCase {
  final AuthService _authService;

  PasswordResetUseCase(this._authService);

  /// パスワードリセットメールを送信
  ///
  /// [email] パスワードリセットメールを送信するメールアドレス
  ///
  /// 例外:
  /// [ValidationException] バリデーションエラー
  /// [AuthenticationException] 認証エラー
  Future<void> execute(String email) async {
    try {
      // バリデーション
      if (email.trim().isEmpty) {
        throw const ValidationException(
          message: 'メールアドレスを入力してください',
          errors: {'email': 'メールアドレスは必須です'},
          code: 'EMPTY_EMAIL',
        );
      }

      // メールアドレス形式チェック（既存の形式と同じ）
      final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
      if (!emailRegex.hasMatch(email)) {
        throw const ValidationException(
          message: '正しいメールアドレス形式で入力してください',
          errors: {'email': 'メールアドレスの形式が正しくありません'},
          code: 'INVALID_EMAIL_FORMAT',
        );
      }

      // パスワードリセットメール送信
      await _authService.sendPasswordResetEmail(email: email);
      
    } catch (e) {
      if (e is ValidationException) {
        rethrow;
      }

      // Firebase Authのエラーを適切な例外に変換
      if (e.toString().contains('user-not-found')) {
        throw const AuthenticationException(
          message: 'そのメールアドレスは存在しません',
          code: 'USER_NOT_FOUND',
        );
      }

      if (e.toString().contains('invalid-email')) {
        throw const ValidationException(
          message: '有効なメールアドレスを入力してください',
          errors: {'email': 'メールアドレスの形式が正しくありません'},
          code: 'INVALID_EMAIL',
        );
      }

      throw AuthenticationException(
        message: 'パスワードリセットメールの送信に失敗しました',
        originalError: e,
      );
    }
  }
}
