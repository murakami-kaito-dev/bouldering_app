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

### イメージタグ運用ルール（2026-08-29 制定。詳細と経緯は deployment-log.md）

- **prod**: `supabase-vX.Y.Z` 形式（アプリのバージョンと一致）。App Storeリジェクト時は `-rejected1`, `-rejected2` と採番し、承認後に正規タグへ付け替える。
- **dev**: push のたびに **`dev-YYYYMMDD-<git短縮SHA>`**（例: `dev-20260829-c1c6294`）。タグなし・`:latest` での push は禁止。デプロイもこの明示タグを指定する。
  ```bash
  TAG="dev-$(date +%Y%m%d)-$(git rev-parse --short HEAD)"
  docker build --platform linux/amd64 -t asia-northeast1-docker.pkg.dev/bouldering-app-dev/bouldering-app-docker-dev/backend:$TAG .
  docker push asia-northeast1-docker.pkg.dev/bouldering-app-dev/bouldering-app-docker-dev/backend:$TAG
  ```
- push 後はタグ付与を確認し、`deployment-log.md` に記録する:
  ```bash
  gcloud artifacts docker images list asia-northeast1-docker.pkg.dev/bouldering-app-dev/bouldering-app-docker-dev --include-tags --sort-by=~UPDATE_TIME | head -3
  ```

### iOS の TestFlight ビルド（証明書を API で更新した後の手順・2026-10-03 確立）

`flutter build ipa` は Xcode 管理プロファイルを再生成できず（API キーにクラウド署名権限が無い）失敗するため、3 段に分ける。

```bash
# ① Flutter 側のビルド（署名なし。--build-number は release-log の採番に従う）
flutter build ios --flavor "Runner Dev" --dart-define=ENVIRONMENT=dev --target lib/main_dev.dart --release --no-codesign --build-number=N
# ② アーカイブ（開発プロファイルは ASC API キー認証で自動再生成される）
cd ios && xcodebuild -workspace Runner.xcworkspace -scheme "Runner Dev" -configuration "Release-Runner Dev" \
  -destination 'generic/platform=iOS' -archivePath ../build/ios/archive/RunnerDev.xcarchive archive \
  -allowProvisioningUpdates -allowProvisioningDeviceRegistration \
  -authenticationKeyPath ../.local/asc/AuthKey_B5TW9QHTS7.p8 -authenticationKeyID B5TW9QHTS7 -authenticationKeyIssuerID <issuer> \
  CODE_SIGN_STYLE=Automatic DEVELOPMENT_TEAM=XX24WCN326
# ③ 書き出しは手動署名（App Store プロファイルは ASC API で作成してローカルに配置済みのものを名前で指定）
xcodebuild -exportArchive -archivePath build/ios/archive/RunnerDev.xcarchive -exportPath build/ios/ipa \
  -exportOptionsPlist <signingStyle=manual, provisioningProfiles: com.km.boulderingapp.dev → "Bouldering App Dev AppStore">
xcrun altool --upload-app --type ios -f build/ios/ipa/bouldering_app.ipa --apiKey B5TW9QHTS7 --apiIssuer <issuer>
```

- prod は scheme "Runner Prod" / configuration "Release-Runner Prod"、プロファイル「Bouldering App Distribution v2」（証明書が変わるたびに ASC API で再作成）
- 証明書・鍵の所在と更新手順は `.local/credentials-locations.md` と自動メモリ `apple-signing-certificates`

### バックエンドのローカル起動（必要なときだけ）

```bash
cd backend
cp .env.dev .env     # devの接続設定で .env を上書き（唯一 .env.dev が使われる場面）
npm run dev          # nodemon + ts-node で起動 → http://localhost:8080/health で確認
```

- `.env` 系ファイルが関与するのは**このローカル起動だけ**。Dockerビルド・Cloud Runデプロイには一切使われない（デプロイ時の環境変数は `--set-env-vars` で注入）。
- `.env.prod` は**意図的に未使用**（本番をローカルで動かす運用は無い。誤って本番DBに繋がない安全弁として現状維持）。
- その他: `npm run build`（tsc）/ `npm start` / `npm test`（テスト0件）/ `npm run lint` / `npm run format`

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
