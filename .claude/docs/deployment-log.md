# デプロイ・修正ログ（deployment-log）

**運用ルール（2026-08-29 ユーザー指示）**:
1. コード・設定を修正したら、**紐づくインフラで検証**する（フロント=Flutterビルド / バックエンド=Dockerビルド+起動確認 / DB=読み取り疎通）。
2. ビルド・デプロイで**バージョンが変わったら、修正内容とバージョンをこのログに記録**する（どのインフラでも同様）。
3. Artifact Registry（GCPのイメージ保存場所）の**タグが意図どおり変わったかを毎回確認**する。
4. アプリ（ストア）のバージョンは release-log.md、バックエンド・インフラはこのファイルが正。

新しいものを上に積む。確認コマンド:
`gcloud artifacts docker images list asia-northeast1-docker.pkg.dev/<project>/<repo> --include-tags`

## 2026-09-25 — Issue #89 対策 E: ジム写真キャッシュをメモリから Supabase（gym_photo_cache）へ（**dev・prod デプロイ済み**）

- **ブランチ** `feature/gym-photo-cache-db`。API の形は不変（`/api/gyms/:id/photos` の応答は同じ）なのでアプリの再申請は不要
- **migration** `backend/migrations/2026-09-25_gym_photo_cache.sql`: `gym_photo_cache(gym_id PK→gyms CASCADE, source google|none, photos JSONB, expires_at, updated_at)`＋`idx_gym_photo_cache_expires`。冪等・追加のみ。**dev DB に適用済み**（2026-09-25）。**prod DB は未適用**（デプロイ時に流す）
- **placesService.ts** を書き換え: L1 プロセス内メモリ（5 分・連打吸収）→ 自前写真 `gym_photos`（キャッシュしない）→ **L2 `gym_photo_cache`（成功 30 日 / 写真なし 1 時間）**→ Google Places。DB 読み書きに失敗しても写真機能は止めない（警告ログを出してメモリだけで動く）。dev 無効化（対策 B）の分岐は維持
- **検証（ローカル ts-node → dev DB）**: 初回呼び出しで `SELECT`（0 行）→ 解決 → `INSERT`（TTL 60 分の none 行）／同一プロセス 2 回目はメモリ／**プロセス再起動後**の呼び出しは DB の行（rows 1）を返して再解決なし。tsc 0 エラー。Docker ビルド成功（ローカルタグのみ・push なし）
- **その後の変更**: L1 メモリを 5 分 → **10 分**（ユーザー決定）。`expires_at` の索引は数百行では使われないため削除（dev DB からも DROP。残る索引は主キーのみ）
- **prod デプロイ（2026-09-25 18:00 JST）**: PR #93 を main（4bd6042）へマージ → prod DB に migration 適用（`gym_photo_cache` 作成・索引は主キーのみ）→ イメージ **`backend:supabase-v3.1.0-r2`**（アプリ 3.1.0 のまま バックエンドだけの更新なので `-r2` を付与）→ `bouldering-api-prod` **rev 00025 → 00026**（環境変数は引き継ぎ。`PLACES_API_KEY` あり・`PLACES_PHOTOS_ENABLED` 未設定＝有効）。検証: `/health` healthy／`GET /api/gyms/3/photos` 初回 `source:google` 5 枚（Google 解決）→ **prod DB に `gym_id=3, google, 5 枚, TTL 30.0 日` の行**／2 回目 55ms（メモリ）／`/api/gyms` 430 件・`/api/tweets`・`/api/announcements` 200
- **dev デプロイ**: 同じイメージに `dev-20260925-4bd6042` を付けて `bouldering-api-dev` **rev 00071 → 00072**（`PLACES_PHOTOS_ENABLED=false`・`PLACES_API_KEY` なしを維持）。検証: `/api/gyms/103/photos` → `none`（Google 呼び出しなし）、dev DB に `none` 行（TTL 60 分）
- **アプリ側の変更なし**（API の応答形式は不変）のため TestFlight・App Store の更新は不要
- **今後の観察点**: Google の写真 URL（photoUri）が 30 日以内に失効する場合、アプリでは「壊れた画像」アイコンになる。prod の `gym_photo_cache` の行が古くなった頃（10 月下旬）に実際の URL が開けるか確認する

## 2026-09-25 — Issue #89 対策 B: dev の Google 写真フォールバックを無効化（dev のみ・prod 不変）

- **背景（同日の再調査）**: 9/1〜9/25 の Photo Media 成功件数は dev 6,836・prod 2,990（概算 ¥8,700）。dev は誰も使っていない 9/25 も毎時 50〜110 件が続いており、呼び出し元は dev Web（`bouldering-web-dev` の BFF、UA `node`）。dev Web の `/gyms/{id}` は `google-proxy-*.google.com`（66.249.x 等・Google の取得基盤）から雑多なブラウザ UA・リファラ無しで毎時 10〜27 ページ巡回されている（9/16 から観測。9/19 まで規約サイトに dev URL を掲載していた期間に拾われたと推定）。prod の 9/24 855 件は TestFlight 検証（1 台の iPhone・173 ジム × 最大 5 枚）
- **コード**（ブランチ `fix/dev-disable-google-photos`）: `PLACES_PHOTOS_ENABLED`（既定 true）を `config.places.photosEnabled` として追加し、`placesService.resolvePhotos` が false なら Places に問い合わせず `source:'none'` を返す。自前写真（`gym_photos`）は従来どおり
- **ルール化**: `.claude/rules/places-photos-dev-prod.md`（dev/prod 差分は意図的・解消しない・経緯）
- **dev Cloud Run（デプロイ済み）**: ブランチのコード（a69a0f8）を `backend:dev-20260925-a69a0f8` としてビルド・push → `bouldering-api-dev` **rev 00070 → 00071**（`--update-env-vars PLACES_PHOTOS_ENABLED=false --remove-env-vars PLACES_API_KEY`・二重の安全弁）。検証: `/health` healthy／`/api/gyms/{3,103,143}/photos` → `source:none`・0 枚／`/api/gyms` 430 件／`/api/tweets` 200。prod は変更なし（PR #92 は main 未マージ。マージは「レビュー無しマージ」として自動モードに拒否されたためユーザー側）
- **未着手**: 対策 E（キャッシュを Supabase へ・30 日保持）は修正箇所の説明まで。D/F/G/H/I はユーザーの疑問に回答後に判断
## 2026-09-23 — v3.1.0 本番反映の準備（Firebase prod / prod DB / Places 上限確認）

- **Firebase Auth（prod・ユーザーがコンソールで実施）**: Google（公開名「イワノボリタイ」）・Apple を有効化、アカウントのリンクを「ID プロバイダごとに複数のアカウントを作成」に変更。メール/パスワードは既存のまま（旧 2 アカウントは残す方針）
- **prod `GoogleService-Info.plist` を再取得**（`firebase apps:sdkconfig IOS 1:1021741160508:ios:957f9fe813015c06c54b39 --project bouldering-app-prod-ca5d7`）→ `ios/Runner/Firebase/prod/` を差し替え。`CLIENT_ID` / `REVERSED_CLIENT_ID` が入った（Git 管理外）
- **DB（prod Supabase・psql・1 トランザクション）**: `ALTER TABLE users ALTER COLUMN email DROP NOT NULL`（UNIQUE `users_new_email_key` は維持）＋ `2026-09-06_likes.sql` → `comments.sql` → `notifications.sql` を適用。事後検証: `tweet_likes` / `tweet_comments` / `notifications` / `announcements` 存在、`tweets.comment_counts` 追加、索引 5 本存在、既存データ（users 2・tweets 1・gyms 430）不変。接続は prod Cloud Run の `DATABASE_URL` をシェル変数経由で使用（値は非表示）
- **Places 上限（prod）**: 実測で `GetPhotoMediaRequest` の日次上限 2,500 が有効（9/19 適用分）。dev は未変更（既定 175,000）
- **Apple Developer（確認のみ）**: prod App ID `com.km.boulderingapp`（N4D8TFU24J）には `APPLE_ID_AUTH`（Sign In with Apple）が dev 同様すでに付与済み → 追加作業なし。既存プロファイル「Bouldering App Distribution v2」は INVALID だが署名は自動管理（`-allowProvisioningUpdates`）のためアーカイブ時に再生成される
- **バックエンド（prod デプロイ済み）**: main（e853036）から `docker build --platform linux/amd64` → `backend:supabase-v3.1.0` を push → `bouldering-api-prod` **rev 00024 → 00025**（`--image` のみ指定。環境変数 14 個・シークレット・SA・1Gi は引き継ぎ。新規 env 不要）。検証: `/health` healthy／`GET /api/gyms` 430 件／`GET /api/gyms/3` 200／`GET /api/tweets` に `liked_by_me`・`comment_counts` あり／未認証の `POST /tweets/:id/like`・`POST /tweets/:id/comments`・`GET /users/:id/notifications`・`POST /users` → 401／`GET /tweets/:id/comments`・`GET /announcements` → 200
- **自動モードの分類器について**: 最初の push は「Production Deploy」として拒否 → ユーザーが `.claude/settings.local.json`（Git 管理外）に docker build/tag/push・`gcloud run deploy`（prod/dev）・`flutter build ios/ipa`・`xcrun altool` の許可ルールを作成して再開。9/1 の v2.0.0 でも同じ拒否が起きており、Claude Code 2.1.258 → 2.1.280 で判定が分類つき・厳格化した（環境側の変化なし）
- **iOS**: ブランチ `release/v3.1.0` を main から作成し `pubspec.yaml` を `3.1.0+14` に版上げ（未コミット）。`flutter build ipa`（Runner Prod）は**署名で失敗**: `Release-Runner Prod` だけ `CODE_SIGN_STYLE = Manual` で、プロファイル「Bouldering App Distribution v2」（ASC id D2B5V9XU3K・INVALID・cert S9HFN4J4U4）に Sign In with Apple が含まれない。他 5 構成（dev 全部・prod Debug/Profile）は Automatic。ASC API でのプロファイル削除・再作成は分類器に拒否 → ユーザー対応待ち
- **証明書の期限（要対応）**: 「Apple Distribution: Kaito Murakami」（S9HFN4J4U4）と Apple Development 系 2 枚が **2026-09-28 に期限切れ**。ローカル鍵付きの配布証明書はこの 1 枚のみ（「iOS Distribution」2 枚は Expo 管理で鍵なし）。9/28 以降は新規アーカイブ不可になるため、リリース前に更新が必要
- **iOS 署名の解決（2026-09-24）**: 許可ルールに ASC スクリプト（`.local/asc/tools/asc.py`）を追加後、INVALID の「Bouldering App Distribution v2」（D2B5V9XU3K）を削除し同名で再作成（**5NS3J2Q5QZ**・cert S9HFN4J4U4・Sign In with Apple 入り）→ `~/Library/Developer/Xcode/UserData/Provisioning Profiles/` と `~/Library/MobileDevice/Provisioning Profiles/` に配置。`flutter build ipa` 成功（3.1.0 / 14）→ altool で TestFlight へアップロード（Delivery UUID `b9a98dd1-e670-4365-8d41-f6a74fc5ba8a`）。詳細は release-log
- **旧アカウントの整理（2026-09-24・prod Firebase + DB）**: TestFlight 検証で「設定からのメール登録」の確認メールが届かない事象 → 原因は旧パスワード方式アカウントがそのメールを占有していると Firebase の `verifyBeforeUpdateEmail` が **200 を返しつつ送らない**（dev で 9/4 に実測済みの挙動）。対処: ①`gPJ43l…`（むらーん）のメールを mri.benkyochannel@gmail.com → **boulder@example.com** に変更（Firebase `accounts:update` と DB `users.email` の両方）②デモ用 `baMFxYD6…`（駆け出しボルダー・boulderingapplication@gmail.com・関連データ 0 件）を Firebase と DB から**削除**（ユーザー指示。必要時に再作成）。km.solo.developer@gmail.com のアカウントは prod に存在しなかった。変更後、検証アカウント `IWtCVc…` に mri.benkyochannel@gmail.com が登録できたことを DB で確認
- **App Store 申請（2026-09-24 17:33 JST）**: build 15 を 3.1.0 として審査提出（WAITING_FOR_REVIEW）。詳細は release-log。dev DB にはノボリタロウ（`MO83oq0j…`）向けの撮影用データ（投稿 2・いいね 4・コメント 3・通知 7）が残っている（dev のみ・削除不要）
- **次**: 審査結果待ち → 公開後に PR #91 を main へマージ（審査メモは「SNS ログイン（Google/Apple）・いいね・コメント・通知」の 4 点、スクショは通知タブ 1 枚追加）

## 2026-09-06 — いいね・スレッド・通知の dev デプロイ（バックエンド）

- **rev 00069**（`backend:dev-20260906-db5800e`）: いいね（#17）＋スレッド（#19）。`GET /api/tweets` に `liked_by_me` / `comment_counts` が載ることを確認、`POST /api/tweets/:id/like` 未認証 → 401、`GET /api/tweets/:id/comments` → 200
- **rev 00070**（`backend:dev-20260906-20930d9`）: 上に通知（#81）を追加した統合版。`GET /api/users/:id/notifications` 未認証 → 401、`GET /api/announcements` → 200
- dev DB のマイグレーション適用済み: `tweet_likes` / `tweet_comments` + `tweets.comment_counts` / `notifications` + `announcements`（いずれも冪等・追加のみ。prod 未適用）
- API は後方互換（列と経路の追加のみ）なので、古い枝（#79・#80）のアプリからでも従来どおり動く
## 2026-09-06 — Issue #74〜#78 の修正（ブランチ分割・チーム並列）

- **#74 / #75 / #77**（マイページ「ボル活」タブ: Pull-to-Refresh 不可・削除が一覧に残る・0 件時の骨組みちらつき）→ 1 チームに統合、ブランチ `fix/my-page-boul-log-refresh`・PR #80。原因: 一覧に `AlwaysScrollableScrollPhysics` 無し＋私有 ScrollController／`refresh()` が状態を初期化／削除後に一覧状態を未更新。修正: physics 付与＋NotificationListener、`isRefreshing` 新設で一覧保持、各 Notifier に `removeTweet` を追加し `ref.exists` で生きている一覧だけ更新＋統計 invalidate
- **#76**（イキタイジムカードの長押しで詳細に遷移しない）→ `fix/gym-card-long-press`・PR #79。カード全体の InkWell に onTap/onLongPress を統一
- **#78**（規約ページ）→ 別リポジトリ `iwanoboritai-legal` の `docs/legal-pages-redesign`・PR murakami-kaito-dev/iwanoboritai-legal#1。**main へのマージ＝公開**なので実機確認後にマージ
- 並列作業は `git worktree`（scratchpad 配下）で実施し、完了後に削除済み。3 ブランチともユーザーの実機確認待ち

---

## イメージタグ付けルール（2026-08-29 制定）

- **prod（既存ルールを維持）**: `supabase-vX.Y.Z`（アプリのマーケティングバージョンと一致させる）。App Storeリジェクト時は `-rejected1, -rejected2, …` を採番し、承認後に正規タグへ付け替える。
- **dev（新規制定）**: push するたびに **`dev-YYYYMMDD-<gitの短縮SHA>`** でタグ付けする（例: `dev-20260829-c1c6294`）。`:latest` やタグなしでの push は行わない。デプロイもこの明示タグを指定する。
  - 理由: 従来のタグなし運用では62イメージの中身が一切追跡できなくなった。日付+SHAなら「そのイメージにどのコミットが入っているか」を後から確実に特定できる。
- push 後は必ず `gcloud artifacts docker images list … --include-tags` でタグが意図どおり付いたかを確認し、このログに記録する。

---

## 2026-09-06 — 通知タブ（Issue #81）実装（ブランチ `feature/notifications`・dev DB のみ変更・デプロイなし）

- **目的**: Bottom Navigation に「通知」タブを追加し、いいね（#17）・コメント／返信（#19）のイベントからアプリ内通知を作る。右の「お知らせ」（運営・ジム発信）は DB・API・画面まで実装しつつ、当面は `FeatureFlags.showAnnouncementsTab = false` で隠す。契約は `social-spec.md`「3. 通知」
- **DB（dev Supabase）**: `backend/migrations/2026-09-06_notifications.sql`（`notifications`＋部分ユニーク索引、`announcements`。冪等）を **dev に適用済み**（2026-09-06、psql）。**prod は未適用**（likes / comments の後に同じファイルを流す）
- **バックエンド**: `services/notificationService.ts` が `TweetLiked` / `TweetUnliked` / `CommentCreated` を購読（`dependencies.ts` の `setupEventSystem()` で登録）し、投稿者へ `like`／`comment`、親コメント主へ `reply` を作る（自分自身・ブロック関係は作らない。投稿者＝親コメント主なら `reply` 1 件だけ。解除で `like` を削除）。`routes/notifications.ts`（`GET /api/users/:id/notifications`・`/unread-count`・`POST /read`。要認証・本人のみ。`/api/users` の後段にマウント）、`routes/announcements.ts`（`GET /api/announcements`。任意認証で公式＋ホームジム・イキタイジム）。いいねの集約は「同じツイート × JST の同じ日」で 1 行（代表行の `created_at` をカーソルに、重複なくページングできる決定的な区切り）。台帳用メモ `backend/docs-notifications.md`
- **アプリ**: 5 タブ（ホーム／ボル活／投稿／通知／マイページ。`app.dart`。テープ下線は `_pages.length` で割るので 5 分割に自動追従）、通知アイコンに未読バッジ（`unreadCountProvider`。起動＝ユーザー復元完了時・タブ表示時・アプリ復帰時に取得、ポーリングなし）。`NotificationPage`（通知｜お知らせの `SwitcherTab`、フラグで通知のみ）、`NotificationRow`（重ねたアイコン最大 6・一文・時間・投稿の引用。タップで `TweetDetailPage`。表示時に既読化してバッジを消す。未読の背景色は次の読み直しまで残す）、骨組みは初回のみ、引っ張って更新、空は「通知はまだありません」、未ログインはログイン導線。お知らせは `AnnouncementRow`（公式／ジムアイコン・タイトル・本文・画像・`url_launcher` のリンク）。前回タブの保存キーを `last_tab_index_v2` に変更（index 3 の意味が変わったため）
- **検証**: `tsc --noEmit` OK／`flutter analyze` 54 件（基準値と同じ・新規指摘なし）／ts-node のサービス結合テスト 20 項目すべて OK（いいね→通知、解除→削除、2 いいね→1 行集約、コメント・返信・重複排除、カーソル、既読、ブロック除外、お知らせの対象範囲。一時データは削除済み）／ローカル HTTP: 401・400・お知らせ 200 を確認。**未実施**: Firebase トークン付き HTTP と実機（fdev）での通知バッジ〜遷移の確認
- **デプロイ**: なし（Cloud Run / Artifact Registry 変化なし）

---

## 2026-09-06 — いいね機能（Issue #17）実装（ブランチ `feature/likes`・dev DB のみ変更・デプロイなし）

- **目的**: ボル活カードに「ハート＋件数」を付け、いいね／解除できるようにする（サウナイキタイ方式）。コメント（#19）・通知（#81）と同時並行の契約 `social-spec.md` に従う
- **DB（dev Supabase）**: `backend/migrations/2026-09-06_likes.sql`（`tweet_likes` テーブル＋索引、冪等）を **dev に適用済み**（2026-09-06、psql）。**prod は未適用**（本番反映時に同じファイルを流す）
- **バックエンド**: `routes/likes.ts`（`POST/DELETE /api/tweets/:tweet_id/like`、要認証・冪等）、`PostgresLikeRepository`（`FOR UPDATE`＋同一トランザクションで `tweets.liked_counts` ±1）、`likeService`（新規挿入／実削除の時だけ `TweetLikedEvent` / `TweetUnlikedEvent` を発行）。ツイート一覧・詳細 5 本に `liked_by_me` を追加（共通 SQL 断片 `sqlFragments.likedByMeSql`。未認証は false）。`routes/tweets.ts` / `gyms.ts` は optionalAuthenticate の uid をサービスへ渡す最小変更のみ
- **アプリ**: `Tweet.likedByMe`、`LikeResult`、`LikeTweetUseCase`、datasource を新 API（`/like`、トークン認証）へ差し替え（旧 `/likes`＋user_id ボディの死にコードと「自分の投稿へのいいね禁止」を撤去＝仕様どおり自分の投稿にも可）。`LikeButton`（楽観的更新→失敗で戻す＋SnackBar、未ログインはログイン導線ダイアログ、いいね済み＝ホールド赤）。`BoulLog` に操作行（左ハート、右にコメント枠 `commentCount`/`onCommentTap` を受けるだけで未描画）。5 つの一覧 Notifier に `updateLike` を追加し `tweet_like_sync.dart` で生きている一覧だけ揃える
- **検証**: `tsc` OK／`flutter analyze` 54 件＝ベースラインと同数（新規指摘なし）／ローカル `npm run dev` で未認証 GET が `liked_by_me: false`・like API がトークン無し 401／dev DB へのリポジトリ結合テストで冪等性・カウンタ整合・各一覧の `liked_by_me` を確認（詳細は `backend/docs-likes.md`）
- **未実施**: 実機（fdev）でのいいね操作・楽観的更新の見た目確認、ID トークン付き HTTP テスト、API 一覧スプレッドシートへの転記（行は `backend/docs-likes.md`）、dev Cloud Run デプロイ
## 2026-09-06 — スレッド（コメント・返信）機能の実装（Issue #19・ブランチ `feature/comment-threads`・dev DB のみ変更、デプロイなし）

- **目的**: ボル活へのコメントと返信（サウナイキタイ方式の 2 段表示）。「途中のコメントを削除しても下の返信は残したい」に論理削除で答える（仕様: `social-spec.md`「2. スレッド」）
- **DB（dev Supabase）**: `backend/migrations/2026-09-06_comments.sql` を適用（`tweet_comments` 新設・`idx_tweet_comments_tweet`・`tweets.comment_counts` 追加）。**prod 未適用**
- **バックエンド**: `routes/comments.ts`（GET/POST `/api/tweets/:id/comments`、DELETE `/api/comments/:id`）、`PostgresCommentRepository`、`commentService`、`domain/events/CommentCreatedEvent`。既存のツイート一覧・詳細に `comment_counts` を追加。台帳行は `backend/docs-comments.md`（スプレッドシートへの転記は未実施）
- **アプリ**: `Tweet.commentCount`、`Comment` エンティティ〜ユースケース、`tweetCommentsProvider(tweetId)`、`TweetDetailPage`（スレッド画面）、`CommentCountButton`、各一覧 Notifier の `updateCommentCount`、`BoulLog` のカード本文タップ／吹き出しで詳細へ、`AppRoutes.tweetDetail` を登録
- **検証**: `tsc --noEmit` OK／ローカル起動（`ts-node`・dev DB）で root→reply→reply-to-reply を作り、真ん中を削除しても 3 つ目が返る・`comment_counts` が 3→2・403/401/400/404 を curl で確認（詳細は `backend/docs-comments.md`）。`flutter analyze` は baseline と同じ 54 件（新規指摘なし）。**実機・シミュレータでの画面確認は未実施**（ディスク残量のため build 不可）
- **デプロイ**: なし（dev Cloud Run rev 00067 のまま）。マージ後に dev へデプロイし、実機で確認する
## 2026-09-06 — いいね機能（Issue #17）実装（ブランチ `feature/likes`・dev DB のみ変更・デプロイなし）

- **目的**: ボル活カードに「ハート＋件数」を付け、いいね／解除できるようにする（サウナイキタイ方式）。コメント（#19）・通知（#81）と同時並行の契約 `social-spec.md` に従う
- **DB（dev Supabase）**: `backend/migrations/2026-09-06_likes.sql`（`tweet_likes` テーブル＋索引、冪等）を **dev に適用済み**（2026-09-06、psql）。**prod は未適用**（本番反映時に同じファイルを流す）
- **バックエンド**: `routes/likes.ts`（`POST/DELETE /api/tweets/:tweet_id/like`、要認証・冪等）、`PostgresLikeRepository`（`FOR UPDATE`＋同一トランザクションで `tweets.liked_counts` ±1）、`likeService`（新規挿入／実削除の時だけ `TweetLikedEvent` / `TweetUnlikedEvent` を発行）。ツイート一覧・詳細 5 本に `liked_by_me` を追加（共通 SQL 断片 `sqlFragments.likedByMeSql`。未認証は false）。`routes/tweets.ts` / `gyms.ts` は optionalAuthenticate の uid をサービスへ渡す最小変更のみ
- **アプリ**: `Tweet.likedByMe`、`LikeResult`、`LikeTweetUseCase`、datasource を新 API（`/like`、トークン認証）へ差し替え（旧 `/likes`＋user_id ボディの死にコードと「自分の投稿へのいいね禁止」を撤去＝仕様どおり自分の投稿にも可）。`LikeButton`（楽観的更新→失敗で戻す＋SnackBar、未ログインはログイン導線ダイアログ、いいね済み＝ホールド赤）。`BoulLog` に操作行（左ハート、右にコメント枠 `commentCount`/`onCommentTap` を受けるだけで未描画）。5 つの一覧 Notifier に `updateLike` を追加し `tweet_like_sync.dart` で生きている一覧だけ揃える
- **検証**: `tsc` OK／`flutter analyze` 54 件＝ベースラインと同数（新規指摘なし）／ローカル `npm run dev` で未認証 GET が `liked_by_me: false`・like API がトークン無し 401／dev DB へのリポジトリ結合テストで冪等性・カウンタ整合・各一覧の `liked_by_me` を確認（詳細は `backend/docs-likes.md`）
- **未実施**: 実機（fdev）でのいいね操作・楽観的更新の見た目確認、ID トークン付き HTTP テスト、API 一覧スプレッドシートへの転記（行は `backend/docs-likes.md`）、dev Cloud Run デプロイ
## 2026-09-06 — イキタイジムカードの長押し／カード全体タップでジム詳細へ遷移（issue #76・アプリのみ・デプロイなし）

- **症状**: マイページ「イキタイ」タブ（他ユーザーページのイキタイも同じ部品）で、ジム名のタップだけが遷移し、カード本体のタップや長押しは押下の見た目（`Pressable` の縮小）だけ出て遷移しなかった
- **原因**: `FavoriteGymCard` はジム名の `GestureDetector.onTap` にしか遷移を置いておらず、`Pressable` は設計上「押下中の見た目だけ」（`Listener`）でタップ判定を持たない
- **修正（ブランチ `fix/gym-card-long-press`）**: `FavoriteGymCard` を `GymListCard` と同じ構造（Container → `InkWell` → Padding）に揃え、`InkWell` の `onTap` / `onLongPress` の両方で `NavigationHelper.toGymDetail` を呼ぶ（ジム名側の個別ハンドラは撤去＝二重遷移なし）。`GymListCard`（検索結果）も `onLongPress: onTap` を追加。`Pressable` 本体は変更なし（ホーム／ジム詳細のボタンに影響させない）
- **検証**: `flutter analyze` は修正前後とも 58 件（変更ファイルの指摘 0）。ディスク残量のため `flutter build` / `flutter run` は未実施 → **実機確認待ち**（イキタイタブ・他ユーザーのイキタイ・検索結果の 3 か所で、タップ／長押しとも 1 回だけ遷移すること、長押し時に Pressable の縮小が戻ること）

---

## 2026-09-05 — 時刻の基準を JST 固定に統一（PR #72・dev デプロイ）

- **目的**: DATE 列の UTC 深夜返却×端末 JST 解釈による日付ずれ（登録当日の午前中にプロフィール保存が失敗）と、統計「今月」の月範囲・経過日数を UTC で決めていたため毎月 1 日 0〜9 時（JST）に先月扱いになる問題を解消。方針は infrastructure.md「時刻の基準」
- **バックエンド**: `utils/jstTime.ts` 新設（`jstToday` / `isAfterJstToday` / `jstMonthRange`）。`getMonthlyStats` の月範囲・経過日数を JST に（`CURRENT_DATE` 廃止）、訪問日の未来チェックを共通部品に。pg の DATE 型を `'YYYY-MM-DD'` 文字列で返すよう設定（`database-supabase.ts`）
- **アプリ**: `shared/utils/app_clock.dart` 新設。DATE の読み書き・未来判定・訪問日の初期値／ピッカー上限・営業中判定・統計の月見出し・ボルダリング歴を JST 基準に統一
- **検証**: 境界テスト（JST 10/1 00:30＝UTC 9/30 15:30 → 今月=10月・経過 1 日、年またぎ、未来判定 3 形式）／アプリ側の一時ユニットテスト 3 件通過／ローカル起動で DATE が文字列・統計 200（週平均 1.4＝1回÷(5日/7)＝JST の経過日数）
- **デプロイ**: dev イメージ `dev-20260905-aca136e` → `bouldering-api-dev` rev **00067-p8v**（2026-09-05 03:06 JST）。疎通: `/health` healthy／公開プロフィール `boul_start_date: '2026-09-02'`（文字列）／統計 `total_visits 1, weekly_average 1.4`／`/api/tweets` の `visited_date = '2026-09-01'`／`POST /users` 無トークン → 401。prod 未反映

---

## 2026-09-03 — SNS ログイン移行（dev のみ・進行中）: dev DB の `users.email` を NULL 許容に

- **目的**: Google / Apple ログインへの移行に伴い、メールアドレスを「任意登録」にする（PR `feature/sns-login-google-apple`）
- **DB（dev Supabase）**: `ALTER TABLE public.users ALTER COLUMN email DROP NOT NULL;` を実行（2026-09-03、バックエンドの接続設定経由）。UNIQUE 制約 `users_new_email_key` とインデックスは維持。既存 9 行は変更なし。**prod DB は未実施**（本番切替時に同じ SQL を実行する）
- **バックエンド**: `POST /users` を要認証（本人 uid のみ）・email 任意に、`PATCH /users/:id/email` を「トークンの確認済みメールのみ保存／null で解除／重複は 409」に変更。ローカル起動（`ts-node`、Docker 不使用）でトークン無しの POST/PATCH が 401 になることを確認。**Cloud Run（dev）へデプロイ済み**: イメージ `dev-20260903-a431705`（Cloud Build。1回目は Google 側の INTERNAL_ERROR で失敗、再実行で SUCCESS）→ `bouldering-api-dev` rev 00064 → **00066**。検証: `/health` healthy／トークン無し `POST /users`・`PATCH .../email` → 401／公開の `GET /users/:id/profile`・`GET /tweets` → 200。**prod は未デプロイ**（本番切替時）
- **Firebase（dev）**: Google / Apple プロバイダ有効化・アカウントリンク設定変更（ユーザー実施）。`GoogleService-Info.plist`（dev）を CLIENT_ID 付きに差し替え（Firebase CLI）
- **Apple Developer**: dev App ID に Sign In with Apple capability を追加（App Store Connect API）
- **2026-09-04 旧アカウントの削除（dev）**: 旧メール/パスワード方式の 2 アカウント（運営者 `tEIHtN…`＝km.solo.developer / Boulder `exyTjv…`＝mri.benkyochannel）を Firebase（Identity Toolkit Admin API・`x-goog-user-project` 必須）と DB（`DELETE FROM users`、CASCADE で投稿 34 件も削除）から削除し、GCS の画像 8 objects も削除。理由: Firebase は「別アカウントが既に持つメール」宛ての確認メールを**200 を返しつつ送らない**（使い捨てメールボックスで実測）ため、旧アカウントがそのメールを占有していると新アカウントでメール登録ができない。**本番切替時も同じ処置が必要**（prod Firebase / prod DB の旧アカウント）

## 2026-09-02 — 月次統計「ペース(回/週)」の計算修正（dev→prod 両方デプロイ済み・アプリ変更なし）

- **目的**: 過去の月の「ペース（回/週）」が異常値になるバグの修正（refactor-candidates **B-21** / action-items **G-13**）
- **原因**: `PostgresUserRepository.getMonthlyStats` の週平均クエリが、`monthsAgo` に関わらず分母を `EXTRACT(DAY FROM CURRENT_DATE)/7` に固定していた。分子は対象月の回数なのに分母だけ「今日の日付」から作られるため、月初ほど過去月の値が膨らんでいた
- **修正**（PR #55 / コミット `b0c07d0`）:
  - 過去の月（`monthsAgo >= 1`）は **その月の日数**（8月なら31日）を週換算した値で割る
  - 今月（`monthsAgo === 0`）は **従来どおり経過日数**で割る（月初に値が大きくなるのは仕様としてユーザーが承認済み）
  - 週平均の分子を `total_visits` と同じ `DATE(visited_date)` 単位の集計に統一（従来は生の timestamp で GROUP BY しており不統一）
- **ビルド方法の例外**: Docker Desktop がハングして応答しなかったため、**ローカル docker build ではなく Cloud Build（`gcloud builds submit`）でイメージを作成**。Dockerfile・Artifact Registry・Cloud Run は従来と同一のため成果物は同等。秘密の混入防止に `backend/.gcloudignore` を新規作成し `.env*` を除外（このファイルは `.gitignore:104` の `**/.gcloudignore` により Git 管理外。クローン直後は手動作成が必要）

| 環境 | イメージタグ | Cloud Run | 検証結果 |
|---|---|---|---|
| dev | `dev-20260902-b0c07d0` | rev 00063 → **00064** | 先月 **13.9 → 0.9**（4回/(31/7)=0.903）／今月 3.4 据え置き／運営者 先月25回 → 5.6（=25/(31/7)）で正 |
| prod | `supabase-v3.0.0` | rev 00023 → **00024** | 2025年10月分 **3.4 → 0.2**（1回/(31/7)=0.226）／`/health` healthy・`/api/gyms`・`/api/tweets`・`/api/gyms/:id/photos`・`/api/gyms/:id` すべて 200 |

- **APIの増減なし**（内部ロジックのみの変更）のため、API一覧スプレッドシートの更新は不要
- **アプリ側の変更は不要**。審査中の v3.0.0（build 12）を含む既存アプリに、この修正が即時反映される
- **同種バグの横展開確認**: バックエンド全体で `CURRENT_DATE` を集計の割り算に使う箇所は他になし（残りは `updated_at` 更新用の `CURRENT_TIMESTAMP` のみ）

---

## 2026-09-01 — gyms の fee / equipment_rental_fee 表記統一（dev→prod・アプリ変更なし）

- **目的**: ジムごとにバラバラだった料金/レンタル料の自由記述を、統一フォーマット（金額=`1,800円`形式・区切り`：`・見出し`【】`・データなし=`情報なし`・税込は元記載時のみ`（税込）`）に整形し可読性を上げる（DBデータのみの変更。lib/バックエンドのコード変更なし）
- **手段**: dev/prodにバックアップテーブル `_fee_backup_20260901`（各430件）を作成 → dev全430件を並列エージェント15体で正規化（金額欠落ゼロ・件数/ID一致を機械検証）→ 一時テーブル経由でUPDATE → **dev確認OK後にprodへ同一値をコピー（dev/prod完全一致）**
- **dev/prod差分3件**（gym_id 100/288/298）はdev側の文字化けで、prod版を正として整形
- **gym_id 431 の元データ破損**（2軒分が連結）は公式サイト https://banjat.com/price/ から正しい料金を取得して再構築（会員/ビジター・大人/小学生以下・各時間別・月/3ヶ月パス・レンタル・プリペイド）。dev/prod両方へ適用
- **復元**: 問題時は `_fee_backup_20260901` から `UPDATE gyms SET fee=b.fee, equipment_rental_fee=b.equipment_rental_fee FROM _fee_backup_20260901 b WHERE gyms.gym_id=b.gym_id;` で元に戻せる（バックアップテーブルは当面保持）

---

## 2026-09-01 — バックエンド v2.0.0 prodデプロイ（ジム写真機能の本番反映完了）

- **イメージ**: `supabase-v2.0.0` をビルド・push（差分: ジム写真API新設のみ。既存APIは無変更）。ビルド前に PR #44 の .dockerignore 修正を取り込み、**イメージ内にenvファイルが無いことを実測で確認**（S-3対策の効果検証済み）
- **デプロイ**: Cloud Run `bouldering-api-prod` **rev 00023**（無停止切替・トラフィック100%）。既存環境変数を維持し `PLACES_API_KEY`（prod専用キー）のみ追加
- **検証（prod実測）**: `/health` 200・database connected / `/api/gyms` **430件・313不在・345あり** / `/api/gyms/3/photos` source=google・5枚 / 既存API（ジム詳細200・ツイート取得OK）デグレなし
- **ロールバック手段**: 旧タグ `supabase-v1.0.0`（rev 00022）への再デプロイで即時復旧可能

---

## 2026-09-01 — ジム写真機能 Phase 4-前半: prod インフラ・DB反映（v2.0.0準備）

- **インフラ（prod / bouldering-app-prod-ca5d7）**: Places API (New)・API Keys API を有効化。専用APIキー `places-server-prod` を新規作成（places.googleapis.com のみに制限。キー文字列は `.local/places_api_key_prod.txt`、リソース名は `.local/places_key_resource_prod.txt`、Git管理外）。実リクエスト1回で200/place取得を確認
- **DB（prod Supabase・1トランザクション+単独DELETE、psqlで直接実行）**:
  1. `gyms` に `google_place_id TEXT` 列追加
  2. devで解決済みの place_id **430件** を投入（dev→prodコピー、UPDATE 430）
  3. `gym_photos` テーブル新設（devと同一スキーマ: photo_id serial PK / gym_id FK CASCADE / photo_url / source default 'own' / created_at、idx_gym_photos_gym_id）
  4. 重複ジム **313「Dボルダリングプラスリードなんば」を削除**（I-9完了。事前に tweets/gym_favorites/users.home_gym_id への参照0件を確認。gym_hours 1件はCASCADE削除）
  - 事後検証: ジム430件・place_id保有430件・gym_photos 0行・313不在・345（正）残存
- **アプリ側の事前検証**: `flutter build ios --simulator --flavor "Runner Prod"` 成功 → `Bouldering App.app`（com.km.boulderingapp）生成を確認（**台帳I-4のスキーム不整合は実害なし**と実証。Archive構成は Release-Runner Prod で正しい）
- **バックエンドデプロイは未実施**（PR #44 の .dockerignore 修正マージ後に supabase-v2.0.0 をビルド・デプロイ予定）

---

## 2026-08-30 — ジム写真機能 Phase 1-2: Places API 導入（**devのみ・prod未変更**）

- **インフラ（dev）**: `bouldering-app-dev` で Places API (New) を有効化。専用APIキーを新規作成（Places APIのみに制限。キー文字列は `.local/places_api_key_dev.txt`、Git管理外）
- **DB（dev Supabase）**: `gyms` に `google_place_id TEXT` 列を追加し、**431/431件** の place_id をバッチ解決・格納（未ヒット0・エラー0。副産物としてジムマスタの重複登録1組を発見 → action-items I-9）
- **課金**: Text Search 計436回（PoC 5 + バッチ431）→ 無料枠内（0円）
- **関連**: 利用規約・プライバシーポリシーを GitHub Pages（`iwanoboritai-legal` リポジトリ）へ移設し、Google Maps Platform 条項を追記。アプリ内リンク切替は PR #30。App Store Connect のURL変更は公開中バージョンでは不可（Apple仕様・409）のため**次回申請時に実施**（action-items I-10）
- **App Store Connect APIキー**: `manage_subscription` から `.local/asc/` へ複製（所在は `.local/credentials-locations.md`）
- **次**: Phase 3（バックエンド写真解決+キャッシュ+GCS優先分岐、フロント帰属表示）→ Phase 4（prod展開）

---

## 2026-08-30 — ジム写真機能 Phase 3: 実装＋devデプロイ（**prod未変更**）

- **実装**: バックエンド `placesService.ts`（自前写真優先→Places APIフォールバック、7日サーバキャッシュ）＋ `GET /api/gyms/:id/photos`。フロント `GymPhotoStrip`（Google帰属バッジ付き）を詳細/検索カード/イキタイカード/地図カードに組込み（ブランチ feature/gym-photos、コミット ba4782f）
- **DB(dev)**: `gym_photos` テーブル新設（自前写真の将来受け皿・現在空）
- **ビルド/デプロイ**: イメージ **`dev-20260830-ba4782f`**（新タグ運用ルール初適用）を push → dev Cloud Run **rev 00063** へデプロイ。env に `PLACES_API_KEY` を追加
- **検証**: レジストリのタグ付与確認済み。dev実環境で /health 200、/api/gyms/1/photos → source=google・5枚・撮影者付き、既存の一覧API 430件正常（デグレなし）
- **次**: ユーザーの fdev 実機確認 → 問題なければ Phase 4（prod展開: API有効化/キー/DB反映/デプロイ）

---

## 2026-08-29 — backend ローカル起動修復（tsconfig-paths死に参照の削除）

- **修正**: `backend/nodemon.json`（`-r tsconfig-paths/register` 削除）と `backend/tsconfig.json`（`ts-node` ブロック削除）。未インストールのパッケージへの参照が残っており `npm run dev` が起動時にクラッシュしていた（refactor-candidates A-9）
- **ブランチ/PR**: `fix/remove-tsconfig-paths` → **PR #24**（コミット c1c6294）
- **検証**: ① `tsc --noEmit` 通過 ② `npm run dev` 起動→ `/health` 200・DB接続OK（**修正前は起動不可**）③ `docker build`+起動→ `/health` 200（ビルド経路デグレなし）
- **デプロイ**: なし。Artifact Registry 変化なし（dev: 2025-09-15 / prod: supabase-v1.0.0-rejected2 2025-10-12 のまま＝意図どおり）
- **付随作業**: ローカル起動用に `backend/.env`（Git管理外）を `.env.dev` からコピー作成（ドキュメント記載の手順どおり）

---

## 2026-08-29 — backend/.env.dev の接続情報修正（デプロイなし）

- **修正**: ローカルの `backend/.env.dev` の `DATABASE_URL` を修正。ユーザー名が `postgres` 単体でSupabaseトランザクションプーラーに認証拒否されていたため、稼働中の dev Cloud Run と同一値（`postgres.<プロジェクトref>` 形式）に差し替え。**Git管理外ファイルのためコミットなし**
- **検証**: Dockerビルド（ローカル）→ コンテナ起動 → `/health` 200・`database: connected` を確認。検証用イメージ・コンテナは検証後に削除（.dockerignore不備でenvが焼き込まれるため保持しない）
- **デプロイ**: なし。Artifact Registry 変化なし（dev最終更新 2025-09-15 のまま＝意図どおり）
- **備考**: `.env.prod` は実装・手順のどこからも未使用と確認し、修正せず（本番誤接続の安全弁として現状維持）

---

## 過去分の復元（2026-08-29 に Artifact Registry / Cloud Run リビジョン / git から逆引き）

※「配信したか」まで断定できないものは推測と明記。

### prod（bouldering-api-prod / bouldering-app-docker-prod）

| 日付 | イメージタグ | Cloud Run | 内容（分かる範囲） |
|---|---|---|---|
| 2025-10-12 | `supabase-v1.0.0-rejected2` push、同日 `supabase-v1.0.0`・`v1.0.0` を更新 | rev **00022**（現行） | **App Store リジェクト2回目への対応デプロイ**。承認後に正規タグへ付け替えたとみられる（タグ運用ルールどおり） |
| 2025-10-05 | `supabase-v1.0.0-rejected1` push | rev 00021 | **リジェクト1回目への対応デプロイ**（この時期のgit: 通報機能・退会機能の実装＝審査対応） |
| 2025-09-22 | （タグ記録なし） | rev 00020 | Supabase移行期の本番デプロイとみられる |
| 〜2025-09 | — | rev 0001x台 | Cloud SQL時代の初期デプロイ群（詳細不明） |

**確認できた事実**: prodのイメージタグは `-rejectedN` 方式が実際に運用されており、**App Storeで少なくとも2回リジェクトされてから承認された**ことがレジストリから読み取れる。

### dev（bouldering-api-dev / bouldering-app-docker-dev）

| 日付 | イメージタグ | Cloud Run | 内容 |
|---|---|---|---|
| 2025-10-11 | （devはタグなし運用） | rev **00062**（現行） | ユーザーブロック機能の開発期（git: feature/user-block）の最終dev デプロイ |
| 2025-09-14〜10-11 | タグなしイメージ多数 | rev 001〜00062 | 開発期間中に**計62回**デプロイ。個別の内容は追跡不能（タグなしのため） |

**教訓（今後のルール3の根拠）**: devはタグなし運用だったため「どのイメージに何が入っているか」が後から一切追えない。今後は dev も日付やコミットSHAでタグを付けるのが望ましい（要ユーザー判断）。

### アプリ（Flutter/App Store）

release-log.md 参照（v1.0.0 build 1 → v1.0.1 build 2、現行公開版）。
