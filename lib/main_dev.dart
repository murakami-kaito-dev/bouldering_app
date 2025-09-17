import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'shared/config/environment_config.dart';
import 'shared/config/app_env.dart';
import 'shared/config/firebase_options_dev.dart';
import 'presentation/pages/app.dart';

/// 開発版アプリケーションエントリーポイント
///
/// 使用方法:
/// flutter run -t lib_new/main_dev.dart
///
/// または、IDEの実行設定で main_dev.dart を指定
///
/// 開発環境の特徴:
/// - 開発用API・データベースサーバーに接続
/// - デバッグログを詳細に出力
/// - 長めのタイムアウト設定
/// - 設定検証を実行してプレースホルダをチェック
void main() async {
  // Flutter フレームワークの初期化
  WidgetsFlutterBinding.ensureInitialized();

  // 環境設定の整合性チェック（ENVIRONMENTとFLUTTER_APP_FLAVORの一致確認）
  AppEnv.validateConsistency();

  // Firebaseの初期化
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 開発環境に設定
  EnvironmentConfig.setEnvironment(Environment.development);

  // 開発環境での設定情報出力（デバッグ用）
  EnvironmentConfig.printConfiguration();

  // 設定値の検証（プレースホルダチェック）
  final configIssues = EnvironmentConfig.validateConfiguration();
  if (configIssues.isNotEmpty) {
    debugPrint('⚠️ 設定に問題があります:');
    for (final issue in configIssues) {
      debugPrint('  - $issue');
    }
    debugPrint('※ 新しい外部システム構築後に適切な値に変更してください');
  }

  // アプリケーション起動
  runApp(
    // Riverpod による依存関係注入を有効化
    const ProviderScope(
      child: BoulderingApp(),
    ),
  );
}
