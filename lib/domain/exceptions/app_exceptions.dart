library app_exceptions;

/// アプリケーション固有の例外クラス
/// 
/// 役割:
/// - ドメイン層でのエラーハンドリングの統一
/// - 具体的なエラー情報の提供
/// - 外部ライブラリの例外から独立したエラー表現

/// 基底例外クラス
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException({
    required this.message,
    this.code,
    this.originalError,
  });

  @override
  String toString() => 'AppException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// ビジネスルール違反例外
class BusinessRuleException extends AppException {
  const BusinessRuleException({
    required super.message,
    super.code,
    super.originalError,
  });
}

/// 認証例外
class AuthenticationException extends AppException {
  const AuthenticationException({
    required super.message,
    super.code,
    super.originalError,
  });
}

/// データ取得例外
class DataFetchException extends AppException {
  const DataFetchException({
    required super.message,
    super.code,
    super.originalError,
  });
}

/// データ保存例外
class DataSaveException extends AppException {
  const DataSaveException({
    required super.message,
    super.code,
    super.originalError,
  });
}

/// バリデーション例外
class ValidationException extends AppException {
  final Map<String, String> errors;

  const ValidationException({
    required super.message,
    required this.errors,
    super.code,
    super.originalError,
  });

  @override
  String toString() {
    final errorDetails = errors.entries
        .map((e) => '${e.key}: ${e.value}')
        .join(', ');
    return 'ValidationException: $message ($errorDetails)';
  }
}

/// ネットワーク例外
class NetworkException extends AppException {
  final int? statusCode;

  const NetworkException({
    required super.message,
    this.statusCode,
    super.code,
    super.originalError,
  });

  @override
  String toString() => 'NetworkException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

/// 設定例外
class ConfigurationException extends AppException {
  const ConfigurationException({
    required super.message,
    super.code,
    super.originalError,
  });
}

/// 権限例外
class PermissionException extends AppException {
  const PermissionException({
    required super.message,
    super.code,
    super.originalError,
  });
}

/// 例外ユーティリティクラス
class ExceptionUtils {
  /// よく使用される例外の定義
  static const invalidUserId = BusinessRuleException(
    message: '無効なユーザーIDです',
    code: 'INVALID_USER_ID',
  );

  static const invalidGymId = BusinessRuleException(
    message: '無効なジムIDです',
    code: 'INVALID_GYM_ID',
  );

  static const invalidTweetId = BusinessRuleException(
    message: '無効なツイートIDです',
    code: 'INVALID_TWEET_ID',
  );

  static const loginRequired = AuthenticationException(
    message: 'ログインが必要です',
    code: 'LOGIN_REQUIRED',
  );

  static const networkUnavailable = NetworkException(
    message: 'ネットワークに接続できません',
    code: 'NETWORK_UNAVAILABLE',
  );

  static const serverError = NetworkException(
    message: 'サーバーエラーが発生しました',
    code: 'SERVER_ERROR',
  );

  /// 例外からユーザー向けメッセージを生成
  static String getDisplayMessage(dynamic error) {
    if (error is AppException) {
      return error.message;
    }
    
    // その他の例外は一般的なメッセージを返す
    return '予期しないエラーが発生しました';
  }

  /// 例外をログ用の詳細な文字列に変換
  static String getLogMessage(dynamic error, StackTrace? stackTrace) {
    final buffer = StringBuffer();
    
    if (error is AppException) {
      buffer.writeln('AppException Details:');
      buffer.writeln('  Type: ${error.runtimeType}');
      buffer.writeln('  Message: ${error.message}');
      if (error.code != null) {
        buffer.writeln('  Code: ${error.code}');
      }
      if (error.originalError != null) {
        buffer.writeln('  Original Error: ${error.originalError}');
      }
    } else {
      buffer.writeln('Unhandled Exception: $error');
    }
    
    if (stackTrace != null) {
      buffer.writeln('StackTrace:');
      buffer.writeln(stackTrace.toString());
    }
    
    return buffer.toString();
  }
}