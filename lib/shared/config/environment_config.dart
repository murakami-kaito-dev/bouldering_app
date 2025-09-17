import 'package:flutter/foundation.dart';

/// 環境設定管理クラス
///
/// 役割:
/// - 開発環境・本番環境の設定を管理
/// - API エンドポイント、データベース接続情報、外部サービス設定の切り替え
/// - アプリケーション起動時に環境を設定
///
/// 使用方法:
/// - 開発版: EnvironmentConfig.setEnvironment(Environment.development)
/// - 本番版: EnvironmentConfig.setEnvironment(Environment.production)
///
/// 外部システム接続情報:
/// - プレースホルダ値を使用（実際の値は新システム構築時に設定）
/// - コメントで必要な設定項目を明記

/// 環境の種類を定義
enum Environment {
  development, // 開発環境
  production, // 本番環境
}

/// 環境設定を管理するクラス
class EnvironmentConfig {
  static Environment _currentEnvironment = Environment.development;

  /// 現在の環境を設定
  ///
  /// [environment] 設定する環境（development または production）
  ///
  /// アプリケーション起動時（main.dart）で呼び出す
  static void setEnvironment(Environment environment) {
    _currentEnvironment = environment;
  }

  /// 現在の環境を取得
  ///
  /// 返り値:
  /// [Environment] 現在設定されている環境
  static Environment get currentEnvironment => _currentEnvironment;

  /// 開発環境かどうかを判定
  ///
  /// 返り値:
  /// [bool] 開発環境の場合はtrue
  static bool get isDevelopment =>
      _currentEnvironment == Environment.development;

  /// 本番環境かどうかを判定
  ///
  /// 返り値:
  /// [bool] 本番環境の場合はtrue
  static bool get isProduction => _currentEnvironment == Environment.production;

  // ==================== API エンドポイント設定 ====================

  /// 開発環境のAPIエンドポイント
  ///
  /// 統合RESTful APIエンドポイント（ユーザー・ツイート・ジム・お気に入り機能）
  /// 全てのリソースが同一のCloud Runサービスで提供される
  /// Cloud Run: https://bouldering-api-dev-cdd6zxnioq-an.a.run.app/api
  static const String _developmentApiEndpoint =
      'https://bouldering-api-dev-cdd6zxnioq-an.a.run.app/api';

  /// 本番環境のAPIエンドポイント
  ///
  /// 統合RESTful APIエンドポイント（ユーザー・ツイート・ジム・お気に入り機能）
  /// 全てのリソースが同一のCloud Runサービスで提供される
  /// 本番Cloud Run: https://bouldering-api-prod-3cjechiypq-an.a.run.app/api
  static const String _productionApiEndpoint =
      'https://bouldering-api-prod-3cjechiypq-an.a.run.app/api';

  /// 現在の環境に応じたAPIエンドポイントを取得
  ///
  /// 返り値:
  /// [String] 現在の環境のAPIエンドポイントURL
  static String get apiEndpoint {
    switch (_currentEnvironment) {
      case Environment.development:
        return _developmentApiEndpoint;
      case Environment.production:
        return _productionApiEndpoint;
    }
  }

  // ==================== Google Cloud Storage設定 ====================

  /// 開発環境のGCSバケット名
  ///
  /// ツイート投稿時の画像・動画保存用バケット
  /// 例: bouldering-app-media-dev
  static const String _developmentGcsBucket = 'bouldering-app-media-dev';

  /// 本番環境のGCSバケット名
  ///
  /// ツイート投稿時の画像・動画保存用バケット
  /// 例: bouldering-app-media-prod
  static const String _productionGcsBucket = 'bouldering-app-media-prod';

  /// 現在の環境に応じたGCSバケット名を取得
  ///
  /// 返り値:
  /// [String] 現在の環境のGCSバケット名
  static String get gcsBucketName {
    switch (_currentEnvironment) {
      case Environment.development:
        return _developmentGcsBucket;
      case Environment.production:
        return _productionGcsBucket;
    }
  }

  // ==================== データベース設定 ====================

  /// 開発環境のデータベース設定
  ///
  /// 開発環境のデータベース接続情報に変更
  static const Map<String, String> _developmentDatabaseConfig = {
    'host': '/cloudsql/bouldering-app-dev:asia-northeast1:bouldering-db-dev',
    'port': '5432',
    'database': 'bouldering_app_dev',
    'username': 'postgres',
    'password': 'b)!105)pPo',
  };

  /// 本番環境のデータベース設定
  ///
  /// 本番環境のデータベース接続情報に変更
  static const Map<String, String> _productionDatabaseConfig = {
    'host':
        '/cloudsql/bouldering-app-prod-ca5d7:asia-northeast1:bouldering-db-prod',
    'port': '5432',
    'database': 'bouldering_app_prod',
    'username': 'postgres',
    'password': 'b)!105)pPo',
  };

  /// 現在の環境に応じたデータベース設定を取得
  ///
  /// 返り値:
  /// [Map<String, String>] データベース接続設定
  static Map<String, String> get databaseConfig {
    switch (_currentEnvironment) {
      case Environment.development:
        return _developmentDatabaseConfig;
      case Environment.production:
        return _productionDatabaseConfig;
    }
  }

  // ==================== Firebase設定 ====================

  /// Firebase設定ファイルのパス
  ///
  /// 新しいFirebaseプロジェクトの設定ファイルに変更
  static String get firebaseConfigPath {
    switch (_currentEnvironment) {
      case Environment.development:
        // 開発環境用Firebase設定ファイルのパスを設定
        return 'lib/shared/config/firebase_options_dev.dart';
      case Environment.production:
        // 本番環境用Firebase設定ファイルのパスを設定
        return 'lib/shared/config/firebase_options_prod.dart';
    }
  }

  // ==================== その他の設定 ====================

  /// APIリクエストタイムアウト時間（秒）
  ///
  /// 環境に応じてタイムアウト時間を調整可能
  static int get apiTimeoutSeconds {
    switch (_currentEnvironment) {
      case Environment.development:
        return 60; // 開発環境は長めに設定（デバッグ用）
      case Environment.production:
        return 30; // 本番環境は短めに設定
    }
  }

  /// ログレベル設定
  ///
  /// 開発環境では詳細ログ、本番環境では最小限のログ
  static String get logLevel {
    switch (_currentEnvironment) {
      case Environment.development:
        return 'DEBUG';
      case Environment.production:
        return 'ERROR';
    }
  }

  /// アプリバージョン表示用
  ///
  /// 開発環境では環境名も表示
  static String get appVersionSuffix {
    switch (_currentEnvironment) {
      case Environment.development:
        return '-dev';
      case Environment.production:
        return '';
    }
  }

  // ==================== 設定検証メソッド ====================

  /// 設定値の検証
  ///
  /// アプリケーション起動時に設定値が正しく設定されているかチェック
  /// プレースホルダが残っている場合は警告を出力
  ///
  /// 返り値:
  /// [List<String>] 問題のある設定項目のリスト
  static List<String> validateConfiguration() {
    final issues = <String>[];

    // APIエンドポイントの検証
    if (apiEndpoint.contains('PLACEHOLDER')) {
      issues.add('APIエンドポイントにプレースホルダが含まれています: $apiEndpoint');
    }

    // GCSバケット名の検証
    if (gcsBucketName.contains('PLACEHOLDER')) {
      issues.add('GCSバケット名にプレースホルダが含まれています: $gcsBucketName');
    }

    // データベース設定の検証
    final dbConfig = databaseConfig;
    for (final entry in dbConfig.entries) {
      if (entry.value.contains('PLACEHOLDER')) {
        issues.add('データベース設定「${entry.key}」にプレースホルダが含まれています: ${entry.value}');
      }
    }

    return issues;
  }

  /// 設定情報を出力（デバッグ用）
  ///
  /// 開発環境でのみ呼び出し、設定値を確認するために使用
  /// パスワードなどの機密情報は出力しない
  static void printConfiguration() {
    if (!isDevelopment) return;

    debugPrint('=== 環境設定情報 ===');
    debugPrint('環境: $_currentEnvironment');
    debugPrint('APIエンドポイント: $apiEndpoint');
    debugPrint('GCSバケット: $gcsBucketName');
    debugPrint('タイムアウト: ${apiTimeoutSeconds}秒');
    debugPrint('ログレベル: $logLevel');
    debugPrint('=================');
  }
}
