import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'shared/config/environment_config.dart';
import 'shared/config/app_env.dart';
import 'shared/config/firebase_options_prod.dart';
import 'presentation/pages/app.dart';

/// 本番版アプリケーションエントリーポイント
///
/// 使用方法:
/// flutter run -t lib_new/main_prod.dart --release
///
/// または、リリースビルド時:
/// flutter build apk -t lib_new/main_prod.dart
/// flutter build ipa -t lib_new/main_prod.dart
///
/// 本番環境の特徴:
/// - 本番用API・データベースサーバーに接続
/// - エラーログのみ出力（デバッグログは無効）
/// - 短めのタイムアウト設定（パフォーマンス重視）
/// - 設定検証は実行するが詳細出力は行わない
void main() async {
  // Flutter フレームワークの初期化
  WidgetsFlutterBinding.ensureInitialized();

  // フォントは assets/google_fonts に同梱（初回起動が圏外でも書体が揃う。
  // ランタイム取得を無効化し、OFLライセンスをライセンス画面に登録）
  GoogleFonts.config.allowRuntimeFetching = false;
  LicenseRegistry.addLicense(() async* {
    final zen = await rootBundle
        .loadString('assets/google_fonts/OFL-ZenKakuGothicNew.txt');
    yield LicenseEntryWithLineBreaks(['google_fonts'], zen);
    final barlow = await rootBundle
        .loadString('assets/google_fonts/OFL-BarlowCondensed.txt');
    yield LicenseEntryWithLineBreaks(['google_fonts'], barlow);
  });

  // 画像メモリキャッシュ上限を明示（既定100MB→50MB）。
  // バックグラウンド時にiOSへプロセスを終了されにくくするためのメモリ削減策
  PaintingBinding.instance.imageCache.maximumSizeBytes = 50 << 20;

  // 環境設定の整合性チェック（ENVIRONMENTとFLUTTER_APP_FLAVORの一致確認）
  AppEnv.validateConsistency();

  // Firebaseの初期化
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 本番環境に設定
  EnvironmentConfig.setEnvironment(Environment.production);

  // アプリケーション起動
  runApp(
    // Riverpod による依存関係注入を有効化
    const ProviderScope(
      child: BoulderingApp(),
    ),
  );
}
