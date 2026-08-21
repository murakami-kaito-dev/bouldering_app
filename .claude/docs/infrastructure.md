# インフラ構成（infrastructure）

2026-08-21 調査（コード + `docs/deployment/` + `docs/setup/` を突合）。値が秘密のものは記載しない（→ secrets-map.md）。

## dev / prod 対応表

| 項目 | dev（日常開発） | prod（リリース時のみ） |
|---|---|---|
| Firebase / GCP プロジェクトID | `bouldering-app-dev` | `bouldering-app-prod-ca5d7` |
| iOS Bundle ID | `com.km.boulderingapp.dev` | `com.km.boulderingapp` |
| iOS PRODUCT_NAME | Bouldering App Dev | Bouldering App |
| ホーム画面表示名 | イワノボリタイ（**dev/prod共通**。Info.plistのCFBundleDisplayNameがハードコードのため、docsが言う表示名分離は効いていない） | イワノボリタイ |
| Cloud Run サービス | `bouldering-api-dev` | `bouldering-api-prod` |
| Cloud Run URL | `https://bouldering-api-dev-cdd6zxnioq-an.a.run.app` | `https://bouldering-api-prod-3cjechiypq-an.a.run.app` |
| Artifact Registry | `bouldering-app-docker-dev` | `bouldering-app-docker-prod` |
| Cloud Run SA | `cloud-run-backend-dev@...` | `cloud-run-backend-prod@...` |
| Cloud Tasks キュー / SA | `gcs-delete-queue-dev` / `tasks-caller-dev@...` | `gcs-delete-queue-prod` / `tasks-caller-prod@...` |
| GCSバケット | `bouldering-app-media-dev` | `boulderingapp_tweets_media`（Supabase版デプロイガイド準拠。旧記述の`bouldering-app-media-prod`とは不一致） |
| Supabase プロジェクト | `bouldering-app-dev` | `bouldering-app-prod` |
| Secret Manager | `db-password-dev`, `firebase-admin-key-dev` | `db-password-prod`, `firebase-admin-key-prod` |
| Cloud Run メモリ | 512Mi | 1Gi |
| リージョン | asia-northeast1（共通） | 同左 |

- Supabase: Organization `Murakami Company`、Tokyoリージョン。2026-01-07 に Compute を MEDIUM→FREE にダウングレード（コスト最適化）。
- Cloud SQL: Supabase移行済み。移行ガイドのチェックリストに「Cloud SQL停止」あり（実際に停止済みかは要確認）。コード上は `DB_PROVIDER=cloudsql` でロールバック可能な分岐が残る。
- Apple: Team ID `XX24WCN326`。審査メタデータは `docs/deployment/app_store_submission.md` に一式。

## バックエンドの環境変数（Cloud Run `--set-env-vars` で注入）

コードが参照する変数（`backend/src/config/environment.ts` ほか）:
`PORT` `NODE_ENV` `DB_PROVIDER` `DATABASE_URL` `DB_HOST/PORT/NAME/USER/PASSWORD` `INSTANCE_CONNECTION_NAME` `DB_SSL` `DB_POOL_MAX` `FIREBASE_PROJECT_ID`(必須) `ALLOWED_ORIGINS` `LOG_LEVEL` `GCS_BUCKET_NAME` `GCP_PROJECT` `TASKS_LOCATION` `TASKS_QUEUE_ID` `TASKS_HANDLER_URL` `TASKS_SA_EMAIL`

- `dotenv` は `.env` のみ読む。`.env.dev` / `.env.prod` はローカル参照用で、実際の注入はデプロイコマンドの `--set-env-vars`。
- Firebase Admin は ADC（Cloud RunのSA）で認証。鍵ファイル読み込みは実装されていない。

## iOS ビルド構成

- Xcode Build Configuration 6種（`Debug/Release/Profile` × `Runner Dev`/`Runner Prod`。標準のDebug/Release/Profileは削除済み）
- 共有スキーム: `Runner Dev` / `Runner Prod`（+ 壊れた旧 `Runner` スキーム）
- GoogleService-Info.plist 切替: Run Script「Setup Firebase Config」が `ios/Runner/Firebase/{dev,prod}/GoogleService-Info.plist` を `ios/Runner/GoogleService-Info.plist` にコピー（該当ファイルがないと exit 1 → **新規クローン直後はビルド不可**。`.gitignore` が `ios/Runner/Firebase/` を除外しているため）
- Android: **事実上未整備**（flavorなし、applicationId が `com.example.bouldering_app` のまま、release署名がdebug鍵、google-services.json なし、`.gitignore` で `/android/*` 丸ごと除外）

## ⚠️ 調査で判明した重要な要注意点（未修正・許可があるまで触らない）

セキュリティ・環境事故に直結するもの。詳細と根拠は refactor-candidates.md 参照。

1. **`POST /api/reports` に認証がない**（`reporter_user_id` をボディで受けるため、なりすまし通報が可能）
2. **`/internal/tasks/gcs-delete-prefix` の認証が実質ザル**（OIDC検証がTODOのまま。外部から任意プレフィックスのGCS一括削除を叩ける）
3. **`backend/.dockerignore` に `.env.dev`/`.env.prod` が入っておらず、DockerイメージにDBパスワード入りenvが焼き込まれる**
4. **`lib/shared/config/environment_config.dart` にDBパスワードが平文ハードコード**（しかもGit追跡下。当該コードは未使用なので削除可能だが、Git履歴に残るためローテーション要検討）
5. **GCSサービスアカウント鍵（assets/keys/*.json）がアプリバイナリに同梱**される設計（pubspec.yamlのassets登録。抽出可能）
6. `GCS_BUCKET_NAME` 未設定時のフォールバックが**devバケット名にハードコード**（prodで設定漏れするとdevバケットを操作）
7. ローカルの `docs/` 配下に平文のDBパスワード・APIキー・**クレジットカード番号・自宅住所**が残存（Git非管理だがローカルに存在。`docs/setup/google_cloud_setup_private.txt` 等）。公開版 `docs_public/` はサニタイズ済みで漏洩なしを確認済み
8. `sslmode` が資料間で不一致（移行ガイド=require、実デプロイコマンド=disable）
