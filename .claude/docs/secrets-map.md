# 秘密情報の所在マップ（secrets-map）

**このファイルに秘密の値は一切書かない。** 場所・用途・扱い方のみ記録する。
Claudeは秘密ファイルの中身を読まない・コミットしない（グローバルルール + PreToolUseフックで機械ブロック済み）。

## Git管理外の秘密ファイル（ローカルに実在）

| パス | 種別 | 用途 |
|---|---|---|
| `backend/.env.dev` / `backend/.env.prod` | 環境変数 | ローカル開発用DB接続情報（DATABASE_URL等）・FIREBASE_PROJECT_ID。実デプロイはCloud Runの`--set-env-vars`で注入するのでこれらは参照されない |
| `assets/keys/gcs_storage_dev.json` / `gcs_storage_prod.json` | GCPサービスアカウント鍵 | フロントからGCSへ直接アップロードするための鍵。**pubspec.yamlのassetsとしてアプリに同梱される**（要注意点 → infrastructure.md） |
| `ios/Runner/Config.plist` | APIキー格納plist | `GOOGLE_MAPS_IOS_DEV_API_KEY` / `GOOGLE_MAPS_IOS_PROD_API_KEY` の2キー（Bundle ID制限付き） |
| `ios/Runner/Firebase/dev/GoogleService-Info.plist` / `prod/...` | Firebase設定 | ビルド時にRun Scriptで `ios/Runner/GoogleService-Info.plist` へコピーされる |
| `lib/shared/config/firebase_options_dev.dart` / `_prod.dart` | Firebase設定(Dart) | FlutterFire生成。エントリポイントからimport |
| `.local/remote-control.sh` | ローカルスクリプト | モバイルからのリモート操作起動用（セッション名 `boulder`） |
| `docs/` 全体 | ドキュメント | **平文の機密が多数残存**（下記） |

## クラウド側の秘密管理

- GCP Secret Manager: `db-password-dev/prod`, `firebase-admin-key-dev/prod`（Cloud Runの `--set-secrets` で参照）
- Cloud Run 環境変数: `DATABASE_URL`（Supabase接続文字列、パスワード込み）等はデプロイコマンドで直接注入

## ⚠️ 既知の問題（許可があるまで未対応。refactor-candidates.md 参照）

1. `lib/shared/config/environment_config.dart` に**DBパスワードが平文ハードコード**（Git追跡下！ 当該コードは未使用のため削除自体は容易だが、Git履歴に残っているためパスワードローテーション要検討）
2. `backend/.dockerignore` の除外漏れで `.env.dev`/`.env.prod` が**Dockerイメージに焼き込まれる**
3. ローカル `docs/` 内の平文機密（Git非管理だが残存）:
   - `docs/setup/supabase_migration_guide.md` … Supabase/Cloud SQLのDBパスワード・接続文字列
   - `docs/deployment/cloud-run-deployment-guide.md` … DATABASE_URL内パスワード
   - `docs/setup/google_cloud_setup_private.txt` … DBパスワード、Maps APIキー、**クレジットカード番号・CVV・氏名・自宅住所**
   - `docs/deployment/app_store_submission.md` … Maps本番APIキー
   - `docs/gym_information_data/scraping/get_geo_position.py` … Geocoding APIキーがソース内ハードコード
4. 公開ドキュメント `docs_public/` は**サニタイズ済みを確認済み**（APIキー形式・DBパスワードの残存0件）

## クローン直後にビルドを通すために必要なもの（Git管理外のため手動配置）

`ios/Runner/Firebase/{dev,prod}/GoogleService-Info.plist`、`ios/Runner/Config.plist`、`lib/shared/config/firebase_options_{dev,prod}.dart`、`assets/keys/gcs_storage_{dev,prod}.json`、（バックエンドローカル実行時）`backend/.env`
