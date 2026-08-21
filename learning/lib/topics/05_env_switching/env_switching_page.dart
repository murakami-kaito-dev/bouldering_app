import 'package:flutter/material.dart';

import 'env_config.dart';

/// ============================================================
/// トピック05: 環境切替（dev/prod）
///
/// 本体の対応箇所:
///   lib/main_dev.dart / lib/main_prod.dart（エントリポイント）
///   lib/shared/config/environment_config.dart（接続先の分岐）
///   lib/shared/config/app_env.dart（--dart-define の読み取りと整合性検証）
///   ios/ の Flavor 設定（Runner Dev / Runner Prod）
///
/// 本体の環境切替は「3点セット」:
///   ①エントリポイント（--target lib/main_dev.dart）
///       → API接続先・Firebaseプロジェクトが決まる
///   ②--dart-define=ENVIRONMENT=dev
///       → GCSバケット・鍵パスが決まる（コンパイル時定数）
///   ③--flavor "Runner Dev"
///       → Bundle ID・GoogleService-Info.plist が決まる（iOSビルド設定）
///
/// ③はXcodeの設定なのでこのミニアプリでは再現できない（README参照）。
/// ①②を再現し、「ズレると何が起きるか」を画面で確認できる。
///
/// 試し方:
///   flutter run                                     … dev一致（正常）
///   flutter run --dart-define=ENVIRONMENT=prod      … ミスマッチを体験
///   flutter run -t lib/main_prod.dart --dart-define=ENVIRONMENT=prod … prod一致
/// ============================================================
class EnvSwitchingPage extends StatelessWidget {
  const EnvSwitchingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final entryEnv = EnvConfig.env; // ①エントリポイントで確定した環境
    const defineEnv = AppEnv.environment; // ②--dart-define（コンパイル時定数）
    final consistent = AppEnv.isConsistentWith(entryEnv);

    return Scaffold(
      appBar: AppBar(title: const Text('05 環境切替')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: consistent ? Colors.green.shade50 : Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    consistent ? '✅ 環境は一致している' : '⚠️ 環境がミスマッチ！',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Text('① エントリポイント由来: ${entryEnv.name}\n'
                      '   → API接続先: ${EnvConfig.apiBaseUrl}'),
                  const SizedBox(height: 8),
                  const Text('② --dart-define=ENVIRONMENT 由来: $defineEnv\n'
                      '   → 本体ではGCSバケットと鍵の選択に使われる'),
                  const SizedBox(height: 8),
                  const Text('③ --flavor（Bundle ID等）はXcode設定のため'
                      'このデモでは対象外'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('ミスマッチだと何が起きるか（本体で実際にあり得る事故）',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            '例: flutter run -t lib/main_prod.dart だけ実行して\n'
            '--dart-define を付け忘れると、\n'
            '  ・API接続先: 本番（①はprod）\n'
            '  ・GCSバケット: 開発用（②はデフォルトのdev）\n'
            'という混在状態になる。本番の投稿画像が開発バケットに\n'
            '保存される事故につながる。\n\n'
            'だから本体では fdev / fprod エイリアスで\n'
            '3点セットを必ず同時に指定する運用にしている。',
          ),
          const SizedBox(height: 16),
          const Text('試し方', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.black87,
            child: const Text(
              '# dev一致（正常）\n'
              'flutter run\n\n'
              '# ②だけprodにしてミスマッチを体験\n'
              'flutter run --dart-define=ENVIRONMENT=prod\n\n'
              '# prod一致（正常）\n'
              'flutter run -t lib/main_prod.dart \\\n'
              '  --dart-define=ENVIRONMENT=prod',
              style: TextStyle(
                  color: Colors.greenAccent, fontFamily: 'Menlo', fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
