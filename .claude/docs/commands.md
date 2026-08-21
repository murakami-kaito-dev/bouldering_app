# 重要コマンド集（commands）

このプロジェクト固有の開発・ビルド・デプロイコマンドのまとめ。
最終更新: 2026-08-21

## Flutter（フロントエンド）— zshエイリアス

定義場所: `~/.zshrc`（「Flutter Bouldering App エイリアス」セクション）

| エイリアス | 実体 | 用途 |
|---|---|---|
| `fdev` | `flutter run --flavor "Runner Dev" --dart-define=ENVIRONMENT=dev --target lib/main_dev.dart` | **開発版を実行**（日常開発はこれ） |
| `fbdev` | `flutter build ios --flavor "Runner Dev" --dart-define=ENVIRONMENT=dev --target lib/main_dev.dart` | 開発版 iOS ビルド |
| `fprod` | `flutter run --flavor "Runner Prod" --dart-define=ENVIRONMENT=prod --target lib/main_prod.dart` | 本番版を実行（リリース確認時のみ） |
| `fbprod` | `flutter build ios --flavor "Runner Prod" --dart-define=ENVIRONMENT=prod --target lib/main_prod.dart` | **本番版 iOS ビルド**（リリース時のみ） |
| `fclean` | `flutter clean` | ビルドキャッシュ削除 |
| `fpod` | `cd ios && pod install && cd ..` | CocoaPods 再インストール |
| `fdevlogout` | `flutter run --flavor "Runner Dev" -t lib/main_force_logout_dev.dart` | 開発版で強制ログアウト起動 |
| `fprodlogout` | `flutter run --flavor "Runner Prod" -t lib/main_force_logout_prod.dart` | 本番版で強制ログアウト起動 |

> 注: ユーザーが記憶していた `forks` というコマンドは存在しない（2026-08-21 調査時点で `~/.zshrc` に定義なし・シェルにも未定義）。おそらく `fprod` / `fbprod` の記憶違い。

## バックエンド（Docker ビルド / デプロイ — Cloud Run 手動デプロイ運用）

出典: `docs/deployment/cloud-run-deployment-guide.md`（cloudbuild.yaml等の自動化はなし。全て手打ち）。
`DATABASE_URL` 等の秘密値はデプロイガイド参照（このファイルには書かない）。

```bash
# 事前準備
gcloud config set project bouldering-app-dev          # dev
gcloud config set project bouldering-app-prod-ca5d7   # prod
gcloud auth configure-docker asia-northeast1-docker.pkg.dev

# ビルド & プッシュ（例: prod + Supabase。devは bouldering-app-dev / bouldering-app-docker-dev）
cd backend
docker build --platform linux/amd64 \
  -t asia-northeast1-docker.pkg.dev/bouldering-app-prod-ca5d7/bouldering-app-docker-prod/backend:supabase-vX.Y.Z .
docker push asia-northeast1-docker.pkg.dev/bouldering-app-prod-ca5d7/bouldering-app-docker-prod/backend:supabase-vX.Y.Z

# デプロイ（主要オプション。env一式はデプロイガイドの完全版コマンドを使うこと）
gcloud run deploy bouldering-api-prod \
  --image asia-northeast1-docker.pkg.dev/.../backend:supabase-vX.Y.Z \
  --platform managed --region asia-northeast1 --allow-unauthenticated \
  --service-account cloud-run-backend-prod@bouldering-app-prod-ca5d7.iam.gserviceaccount.com \
  --set-env-vars NODE_ENV=production,DB_PROVIDER=supabase,... \
  --memory 1Gi --timeout=900          # devは512Mi

# 動作確認
curl https://bouldering-api-dev-cdd6zxnioq-an.a.run.app/health
curl https://bouldering-api-prod-3cjechiypq-an.a.run.app/health
gcloud run services logs read bouldering-api-dev --limit=50
```

- イメージタグ運用: 本番は `supabase-v1.0.0` 形式。App Storeリジェクト時は `-reject1`, `-reject2` と採番し、承認後に通常タグへ戻す。
- ローカル開発: `cd backend && npm run dev`（nodemon + ts-node）。`npm run build`（tsc）/ `npm start` / `npm test`（テスト0件）/ `npm run lint` / `npm run format`

## リリースビルド（iOS）

```bash
# 本番リリースビルド（= fbprod + --release）
flutter build ios --flavor "Runner Prod" --dart-define=ENVIRONMENT=prod --target lib/main_prod.dart --release
# その後 Xcode で「Runner Prod」スキーム → Product → Archive → App Store Connect へ
```

アップデート時の完全手順: `flutter clean` → `flutter pub get` → 上記ビルド → Archive（`docs/deployment/app_store_submission.md` L1790〜）。
実機デバッグ: `flutter run -d <device-id> --flavor "Runner Dev" --dart-define=ENVIRONMENT=dev --target lib/main_dev.dart`（`docs/deployment/ios_device_build.md`）。

## メモ

- 環境切替は「Flavor（Runner Dev / Runner Prod）」×「`--dart-define=ENVIRONMENT=dev|prod`」×「エントリポイント（main_dev.dart / main_prod.dart）」の3点セット。
- 日常開発は dev 系のみ使用。prod 系はリリース時のみ。
