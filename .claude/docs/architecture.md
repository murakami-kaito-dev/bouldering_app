# アーキテクチャ（architecture）

コードを正として全ファイル調査（2026-08-21、main = b7fb9d1 時点）から確認した事実。
アプリ名: **イワノボリタイ**（ボルダリングジム検索・ボル活記録SNS）。iOS配信済み（v1.0.1+2）。

## 全体構成

```
Flutter (iOS)  ──HTTP+Firebase IDトークン──▶  Cloud Run (Express/TS)  ──pg──▶  Supabase (PostgreSQL)
   │                                              │
   ├── Firebase Auth（認証・直接接続）             ├── Firebase Admin SDK（トークン検証、ADC）
   └── GCS（画像アップロード・直接接続★）          ├── GCS（画像削除、Cloud Tasks経由の非同期）
                                                  └── Cloud Tasks（メディア削除キュー）
```

★フロントはGCSへ**直接**アップロードする（サービスアカウント鍵をアセット同梱、後述の要注意点）。

- **DBはSupabase**（`DB_PROVIDER`環境変数で切替、デフォルト`supabase`）。Cloud SQL用コードはロールバック用の**生きた分岐**として意図的に残置（`backend/src/config/database-cloudsql.ts`）。
- **Supabaseへの直接接続はフロントに一切ない**（supabaseパッケージ未使用）。全データアクセスはバックエンドAPI経由。
- Pub/Subは未使用。非同期処理は**Cloud Tasks**のみ（`storageCleanupPublisher`という名前はPub/Sub時代の名残）。

## フロントエンド（Flutter）

Clean Architecture + MVVM（Riverpod）。`lib/` 150ファイル。

```
lib/
├── main_dev.dart / main_prod.dart          # エントリポイント（環境ごと）
├── main_force_logout_dev.dart / _prod.dart # 強制ログアウト用の使い捨てアプリ
├── domain/          # entities(9) / repositories IF(8) / usecases(25クラス) / services IF(3) / exceptions
├── infrastructure/  # datasources(6+mock) / repositories実装(7) / services(ApiClient, FirebaseAuth, GCS, NGワード)
├── presentation/    # pages(23画面) / components(5グループ) / providers(22ファイル, Riverpod)
├── shared/          # config(環境設定・Firebase options) / constants / utils / services
└── view/assets/     # SVG/PNGアセットのみ（Dartコードなし。旧構造の名前だけ残ったアセット置き場）
```

### 環境切替の仕組み（3点セット）

| 要素 | dev | prod | 決まるもの |
|---|---|---|---|
| エントリポイント | `main_dev.dart` | `main_prod.dart` | API接続先・Firebaseプロジェクト（import する firebase_options で確定） |
| `--dart-define=ENVIRONMENT` | `dev` | `prod` | GCSバケット・GCSサービスアカウント鍵パス（`dependency_injection.dart:87-114`） |
| `--flavor` | `Runner Dev` | `Runner Prod` | Bundle ID・GoogleService-Info.plist（Xcode Run Scriptでコピー） |

- 接続先定義: `lib/shared/config/environment_config.dart`（dev: `bouldering-api-dev-cdd6zxnioq-an.a.run.app` / prod: `bouldering-api-prod-3cjechiypq-an.a.run.app`）
- **注意**: 3点は独立しており、`AppEnv.validateConsistency()` は ENVIRONMENT と FLUTTER_APP_FLAVOR の一致しか検証しない。エントリポイントだけ変えて dart-define を忘れると**環境が混在する**。必ず `fdev`/`fprod` 等のエイリアス（3点セット済み）を使うこと。

### 主要機能（コードから確認）

- ジム: 条件検索（都道府県×種別）、名前/住所検索、Google Maps地図検索、詳細（営業時間・料金・イキタイ）
- ボル活（ツイート）: 投稿（写真5枚まで、GCSアップロード）・編集・削除、タイムライン5種（全体/お気に入り/ジム別/自分/他人）
- ユーザー: **SNS ログイン（Google / Apple。2026-09 にメール+パスワード認証を撤廃）**、初回ログイン＝登録（`POST /users` は要認証・本人 uid のみ）、プロフィール編集、お気に入りユーザー、月次統計、通知用メールアドレスの任意登録（確認メールで本人確認・DB UNIQUE）、退会（同じプロバイダで再認証）
- 安全対策（App Store審査対応）: ブロック、通報、NGワードフィルタ（端末内判定）、利用規約同意ゲート

### 状態管理・ルーティング

- Riverpod 2.6（StateNotifierProvider中心、手書きcopyWith。freezed/riverpod_generator不使用）
- DI: `lib/presentation/providers/dependency_injection.dart`（40超のProviderで手動バインド）
- ルーティング: `MaterialApp.routes` + `Navigator.pushNamed`（`AppRoutes`定数）。go_router/auto_routeはpubspecにあるが**未使用**。NavigationHelper / NavigationService / MaterialPageRoute直書きの3方式が混在（→ refactor-candidates.md）

## バックエンド（Node.js/TypeScript, Cloud Run）

Express 4 + 生SQL（ORMなし、パラメータ化済み）。Clean Architecture 4層。`backend/src/` 45ファイル。

```
backend/src/
├── index.ts              # Express起動、/health、グレースフルシャットダウン
├── config/               # environment(環境変数集約) / database(プロバイダ切替) / database-supabase / database-cloudsql / firebase
├── middleware/           # auth(Firebase IDトークン検証) / error / validation
├── routes/               # users(688行) / tweets / gyms / reports / blocks / internal_tasks
├── services/             # userService, tweetService, gymService, favoriteService, blockService, reportService ほか
├── domain/               # repositories IF / services IF / events(TweetDeletedEvent)
├── infrastructure/       # repositories(Postgres実装6) / events(InMemoryEventBus) / handlers / setup(dependencies.ts=手書きDI)
└── models/types.ts
```

- 認証: `authenticate`（必須）/ `optionalAuthenticate`（公開エンドポイント）。認可は各ハンドラ内で `req.user.uid === user_id` を比較。
- APIベースパス: `/api/users` `/api/tweets` `/api/gyms` `/api/reports` `/api/blocks` `/internal/tasks`（全ルート一覧はバックエンド調査レポート参照。主要: ユーザーCRUD+お気に入り、ツイートCRUD、ジム一覧/詳細/ジム別ツイート、ブロック4種、通報POST）
- ツイート削除→画像削除フロー: `TweetDeletedEvent` → InMemoryEventBus → Cloud Tasksへ投入 → 同一サービスの `/internal/tasks/gcs-delete-prefix` がGCS削除（単一サービス構成）
- GCSパス構造: `v1/public/users/{userId}/posts/{yyyy}/{mm}/{postUuid}/{assetUuid}/original.{ext}`
- tsconfig: `strict: false`（型安全性ほぼ無効）。テストは0件（jest設定のみ存在）。

## DB（Supabase PostgreSQL）

- テーブル7: `users`, `gyms`, `gym_hours`, `tweets`, `tweet_media`, `user_favorites`, `gym_favorites`（旧Cloud SQL時代の `boul_log_tweet`/`gym_info`/`boulder`/`wanna_go_relation` からリネーム移行）
- `user_id VARCHAR(28)` = Firebase UID
- 接続: Transaction pooler（ポート6543/PgBouncer）、`DB_POOL_MAX=10`。DDL・移行時はDirect connection(5432)
- 移行資料: `docs/setup/supabase_migration_guide.md`、旧DBダンプは `docs/gcloud_sql_data/`

## ドキュメントの正確性について（コードとの乖離）

調査で判明した「docsを鵜呑みにできない」箇所。**常にコードを正とする**。

- `lib/README.md` は2025年7月時点の古い内容（`lib_new/` 表記、firebase_optionsの場所違い等）
- `docs/README.md` のリンクは旧ディレクトリ名で全て切れている
- `firebase.json` の dev 出力先 `lib/firebase_options.dart` は実在しない（実際は `lib/shared/config/firebase_options_dev.dart`）
- ルート `README.md` の Android flavor ビルドコマンドは**動かない**（Androidはflavor未設定・事実上未整備）
- prod GCSバケット名が資料間で不一致: 実運用は `boulderingapp_tweets_media`（Supabase版デプロイガイド）、旧記述は `bouldering-app-media-prod`
