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

## 認証（Firebase Authentication）— 2026-09 SNS ログインへ移行

- プロバイダ: **Google / Apple の2つ**（メール/パスワードは撤廃・LINE は導入しない）。dev プロジェクト `bouldering-app-dev` で有効化済み（2026-09-03）。prod は本番切替時に同じ設定を行う
- Firebase コンソールの設定値（dev）: Google「プロジェクトの公開名」= `イワノボリタイ(dev)`（prod は `イワノボリタイ`）、サポートメール = km.solo.developer@gmail.com。Apple は追加入力なし（サービス ID / OAuth コードフローは Web/Android と退会時トークン失効用で今は未設定）。設定 → ユーザーアカウントのリンク = **「ID プロバイダごとに複数のアカウントを作成」**（同じメールの Google/Apple は別アカウント）
- Apple Developer: dev App ID `com.km.boulderingapp.dev` に Sign In with Apple capability を App Store Connect API で追加済み（2026-09-03）。Xcode 側は `ios/Runner/Runner.entitlements`（`com.apple.developer.applesignin`）を全 Configuration の `CODE_SIGN_ENTITLEMENTS` に設定
- Google ログインの戻り先 URL スキーム（`REVERSED_CLIENT_ID`）は Run Script「Inject Google Sign-In URL Scheme」が、flavor ごとの `GoogleService-Info.plist` から読んでビルド成果物の Info.plist に注入する（Info.plist に直書きしない。plist は Google 有効化後に `firebase apps:sdkconfig IOS <appId> --project <project>` で再取得したもの＝`CLIENT_ID`/`REVERSED_CLIENT_ID` を含む）
- メールアドレス: 認証には使わない。設定画面から任意登録（初期値空）。登録は Firebase の確認メール（`verifyBeforeUpdateEmail`）で本人確認 → バックエンドは body を信用せず Firebase トークンの `email`（`email_verified`）だけを保存。`users.email` は NULL 許容・UNIQUE（1アカウント:1メール、重複は 409）
- 既存のメール/パスワードアカウント（開発者のみ）は切替後ログイン不可（了承済み）

## 時刻の基準（JST 固定・2026-09-05 決定）

- サービスは日本向けなので、**「今日」「今月」「営業中か」の判断は日本時間（UTC+9・夏時間なし）で行う**。端末やサーバーのタイムゾーンに依存させない
- 保存は UTC のまま（TIMESTAMPTZ）。**DATE 列**（`tweets.visited_date` / `users.birthday` / `users.boul_start_date`）は「日付だけ」の値として `'YYYY-MM-DD'` で受け渡す。pg の DATE 型パーサを文字列返しに設定済み（`database-supabase.ts`）。JS の Date に変換すると UTC 深夜の時刻付きになり、日本では 09:00 と解釈されて日付がずれる（2026-09-05 に「登録当日の午前中に保存が失敗する」バグとして顕在化）
- 共通部品: バックエンド `backend/src/utils/jstTime.ts`（`jstToday` / `isAfterJstToday` / `jstMonthRange`）、アプリ `lib/shared/utils/app_clock.dart`（`AppClock.nowJst` / `todayJst` / `parseDateOnly` / `formatDateOnly` / `isAfterToday`）。**新しく「今日」や日付を扱うコードは必ずこれらを使う**（`DateTime.now()` / `new Date()` / `CURRENT_DATE` を判断に直接使わない）
- 投稿時刻（`tweeted_date`）のような「瞬間」は UTC 保存＋端末ローカル表示のままでよい

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

## Web アプリ（webapp/ — Next.js 16 / Cloud Run / Firebase Hosting）2026-09-05 追加

iOS と同じバックエンド API を使う Web 版。Next.js を `output: "standalone"` でコンテナ化して Cloud Run に置き、
Firebase Hosting の rewrite（`firebase.json` の `hosting`）で **独自ドメイン + SSL + CDN** を被せる構成。
公開手順（ドメイン購入〜AdSense）は `web-domain-setup.md`、コマンドは `commands.md`「Web アプリ」。

| 項目 | dev | prod（未構築） |
|---|---|---|
| GCP / Firebase プロジェクト | `bouldering-app-dev` | `bouldering-app-prod-ca5d7` |
| Cloud Run サービス | `bouldering-web-dev`（512Mi / 1 CPU / min 0 / max 3 / :8080） | `bouldering-web-prod`（max 5） |
| イメージ | `asia-northeast1-docker.pkg.dev/bouldering-app-dev/bouldering-app-docker-dev/web:dev-YYYYMMDD-<sha>` | `.../bouldering-app-docker-prod/web:prod-YYYYMMDD-<sha>` |
| Artifact Registry | backend と共用 `bouldering-app-docker-dev`（イメージ名 `web` で区別） | `bouldering-app-docker-prod` |
| Firebase Hosting サイト | `bouldering-app-dev` → https://bouldering-app-dev.web.app（rewrite `**` → Cloud Run） | 未作成（案: `bouldering-app-prod`）+ 独自ドメイン |
| 公開 URL（`NEXT_PUBLIC_SITE_URL`） | `https://bouldering-app-dev.web.app`（`X-Robots-Tag: noindex` 付き） | `https://<独自ドメイン>`（取得後） |
| Firebase Web アプリ | `boulderingapp-dev-web`（App ID `1:946765315089:web:b969a44a1490e1b4e8c5b0`） | 未作成 |
| Google Maps ブラウザキー | 「Web Maps API Key - Dev」（HTTP リファラ: `localhost:3000` / `bouldering-app-dev.web.app` / `.firebaseapp.com`） | 「Web Maps API Key - Prod」未作成 |
| ビルド | Cloud Build `webapp/deploy/cloudbuild.yaml`（E2_HIGHCPU_8、Docker build-arg で `NEXT_PUBLIC_*` を埋め込み） | 同左 |
| デプロイスクリプト | `webapp/deploy/deploy-dev.sh` | `webapp/deploy/deploy-prod.sh`（独自ドメイン設定までは実行拒否） |
| 環境変数ファイル（Git 管理外） | `webapp/.env.local` | `webapp/.env.prod.local` |
| リージョン | asia-northeast1（Hosting → Cloud Run rewrite 対応リージョン） | 同左 |

### Web の環境変数（全て `NEXT_PUBLIC_*` = 公開値。`webapp/src/lib/env.ts`）

`NEXT_PUBLIC_API_BASE_URL` `NEXT_PUBLIC_SITE_URL` `NEXT_PUBLIC_GOOGLE_MAPS_API_KEY`
`NEXT_PUBLIC_FIREBASE_API_KEY` `NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN` `NEXT_PUBLIC_FIREBASE_PROJECT_ID`
`NEXT_PUBLIC_FIREBASE_APP_ID` `NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID` `NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET`
`NEXT_PUBLIC_ADSENSE_CLIENT` `NEXT_PUBLIC_APP_ENV` `NEXT_PUBLIC_APP_STORE_URL` `NEXT_PUBLIC_APP_STORE_ID`

- **すべて `next build` 時に JS へ埋め込まれる**（Next.js の仕様）。Cloud Run の `--set-env-vars` では反映されない → 値を変えたら再ビルド。
  Dockerfile は build-arg で受け、空文字は「未設定」扱い（`env.ts` の既定値が生きる）。
- 秘密（DB・サービスアカウント・Brevo 等）は Web に一切置かない。Web は常にバックエンド API 経由。
- `deploy-dev.sh` は `NEXT_PUBLIC_SITE_URL` / `NEXT_PUBLIC_APP_ENV` を強制上書きし、`NEXT_PUBLIC_API_BASE_URL` が dev API でなければ中断する（環境混在防止）。

### Hosting rewrite の制約（Firebase 公式 docs より。2026-09-05 確認）

- rewrite 先の Cloud Run は **同一 GCP プロジェクト**・**未認証呼び出し許可**が必要。`asia-northeast1` は対応リージョン。
- `public`（`webapp/hosting-public`、意図的に空）に実ファイルがあればそちらが優先され、無いものだけ rewrite される。
- **Cookie は `__session` 以外 Cloud Run に届かない**（Hosting が剥がす）。現状の Web は Firebase Auth をブラウザ側で扱い
  サーバー Cookie を使わないため影響なし。将来 SSR でセッション Cookie を使うなら名前を `__session` にすること。
- 動的レスポンスの CDN キャッシュは `Cache-Control: public, s-maxage=…` を返したものだけ（Next の `revalidate` ページは該当）。
  `/_next/static/**` は `firebase.json` の `headers` で `immutable` を明示。
- Hosting の予約パス `/__/*`（Auth の `/__/auth/handler` 等）は rewrite より先に Hosting が処理する。

### 依存関係・要注意点

- **バックエンド `ALLOWED_ORIGINS`**: `bouldering-api-dev` は未設定（既定 `http://localhost:3000` のみ）。ブラウザから直接 API を叩く機能
  （ログイン後の投稿・マイページ）を Web で動かすには `https://bouldering-app-dev.web.app` を追加して API を再デプロイする必要がある
  （`gcloud run services update bouldering-api-dev --region asia-northeast1 --project bouldering-app-dev --update-env-vars ALLOWED_ORIGINS=http://localhost:3000,https://bouldering-app-dev.web.app`）。サーバー側 fetch は Origin を送らないので不要。
- Cloud Build の実行 SA は `946765315089@cloudbuild.gserviceaccount.com`（`roles/cloudbuild.builds.builder`。backend のビルドで実績あり）。
  `gcloud run deploy` は操作者本人の権限で実行（Owner）。Web 用に専用 Cloud Run SA は作らず既定の Compute SA で動く（秘密にアクセスしないため）。
- `webapp/.gcloudignore` は Git 管理外（`.gitignore:104`）。`deploy-dev.sh` が無ければ生成し、`.env*` 除外を必ず検証する。
