import '../entities/user.dart';
import '../repositories/user_repository.dart';
import '../exceptions/app_exceptions.dart';

/// Firebase の uid でアプリ側のユーザー情報（DB）を取得する
class LoginUseCase {
  final UserRepository _userRepository;

  LoginUseCase(this._userRepository);

  /// 例外: DB にまだ行が無いときは code 'USER_NOT_FOUND'（初回ログイン＝未登録）
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

/// アプリ側のユーザー情報（DB の行）を作る
///
/// SNS ログインでは「初めてログインしたとき」が登録。メールアドレスは持たない
/// （設定画面から任意で登録する）
class SignUpUseCase {
  final UserRepository _userRepository;

  SignUpUseCase(this._userRepository);

  Future<bool> execute(String userId) async {
    try {
      if (userId.trim().isEmpty) {
        throw const ValidationException(
          message: 'ユーザーIDが入力されていません',
          errors: {'userId': 'ユーザーIDは必須です'},
          code: 'EMPTY_USER_ID',
        );
      }

      final created = await _userRepository.createUser(userId);
      if (!created) {
        throw const DataSaveException(
          message: 'ユーザー情報の作成に失敗しました',
          code: 'USER_CREATE_FAILED',
        );
      }
      return true;
    } catch (e) {
      if (e is AppException) rethrow;
      throw DataSaveException(
        message: 'ユーザー情報の作成に失敗しました',
        originalError: e,
      );
    }
  }
}
