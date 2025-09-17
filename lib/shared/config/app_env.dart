import 'package:flutter/foundation.dart';

/// 環境設定の整合性チェックユーティリティ
/// 
/// 役割:
/// - ENVIRONMENTとFLUTTER_APP_FLAVORの整合性を検証
/// - 環境設定のミスマッチを早期検出
/// - 本番事故を未然に防ぐセーフティネット
/// 
/// 使用方法:
/// - main関数の最初でvalidateConsistency()を呼び出す
/// - 環境判定は常にisProdEnvを使用（ENVIRONMENTベース）
/// - FLUTTER_APP_FLAVORは検証のみに使用
class AppEnv {
  /// 実装で使う"意図": --dart-defineで明示的に渡す値
  static const environment =
      String.fromEnvironment('ENVIRONMENT', defaultValue: 'dev');

  /// ネイティブがビルドした"事実": --flavorからFlutterが自動注入
  static const flutterAppFlavor =
      String.fromEnvironment('FLUTTER_APP_FLAVOR', defaultValue: '');

  /// 本番環境かどうか（ENVIRONMENT基準）
  /// アプリの分岐はこちらを使用
  static bool get isProdEnv =>
      environment.toLowerCase() == 'prod' || 
      environment.toLowerCase() == 'production';

  /// 本番Flavorかどうか（FLUTTER_APP_FLAVOR基準）
  /// 整合性チェックのみに使用
  static bool get isProdFlavor =>
      _normalize(flutterAppFlavor) == 'prod';

  /// Flavor文字列を正規化
  /// "Runner Prod" → "prod", "Runner Dev" → "dev"
  static String _normalize(String s) =>
      s.toLowerCase().replaceAll('runner', '').trim();

  /// 起動時に環境設定の整合性を検証
  /// 
  /// - ENVIRONMENTとFLUTTER_APP_FLAVORの不一致を検出
  /// - Debug: assertで即座に停止（開発時に即気づける）
  /// - Release: ログ出力のみ（本番は落とさない）
  static void validateConsistency() {
    // Web/テスト等でFLAVORが未設定の場合はスキップ
    if (flutterAppFlavor.isEmpty) {
      debugPrint('🔍 [ENV CHECK] FLUTTER_APP_FLAVOR is empty (Web/Test environment?)');
      return;
    }

    // 整合性チェック
    final mismatch = isProdEnv != isProdFlavor;
    
    // デバッグ情報を常に出力
    debugPrint('🔍 [ENV CHECK] ENVIRONMENT=$environment (isProd=$isProdEnv)');
    debugPrint('🔍 [ENV CHECK] FLUTTER_APP_FLAVOR=$flutterAppFlavor (isProd=$isProdFlavor)');
    debugPrint('🔍 [ENV CHECK] Consistency: ${mismatch ? "❌ MISMATCH!" : "✅ OK"}');
    
    if (!mismatch) return;

    // ミスマッチ検出時の警告メッセージ
    final msg = '''
    ⚠️ ENV/FLAVOR MISMATCH DETECTED ⚠️
    ENVIRONMENT=$environment (isProd=$isProdEnv)
    FLUTTER_APP_FLAVOR=$flutterAppFlavor (isProd=$isProdFlavor)
    
    This may cause:
    - Wrong API endpoints being used
    - Incorrect Firebase configuration
    - Production data corruption risks
    ''';

    if (kReleaseMode) {
      // 本番ビルドでは落とさずに警告のみ
      // TODO: Crashlytics等に記録する場合は以下を有効化
      // FirebaseCrashlytics.instance.log(msg);
      debugPrint('⚠️ WARNING: $msg');
    } else {
      // 開発/プロファイルビルドでは即座に停止
      assert(false, msg);
    }
  }
}