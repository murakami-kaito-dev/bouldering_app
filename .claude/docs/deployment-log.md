# デプロイ・修正ログ（deployment-log）

**運用ルール（2026-08-29 ユーザー指示）**:
1. コード・設定を修正したら、**紐づくインフラで検証**する（フロント=Flutterビルド / バックエンド=Dockerビルド+起動確認 / DB=読み取り疎通）。
2. ビルド・デプロイで**バージョンが変わったら、修正内容とバージョンをこのログに記録**する（どのインフラでも同様）。
3. Artifact Registry（GCPのイメージ保存場所）の**タグが意図どおり変わったかを毎回確認**する。
4. アプリ（ストア）のバージョンは release-log.md、バックエンド・インフラはこのファイルが正。

新しいものを上に積む。確認コマンド:
`gcloud artifacts docker images list asia-northeast1-docker.pkg.dev/<project>/<repo> --include-tags`

## イメージタグ付けルール（2026-08-29 制定）

- **prod（既存ルールを維持）**: `supabase-vX.Y.Z`（アプリのマーケティングバージョンと一致させる）。App Storeリジェクト時は `-rejected1, -rejected2, …` を採番し、承認後に正規タグへ付け替える。
- **dev（新規制定）**: push するたびに **`dev-YYYYMMDD-<gitの短縮SHA>`** でタグ付けする（例: `dev-20260829-c1c6294`）。`:latest` やタグなしでの push は行わない。デプロイもこの明示タグを指定する。
  - 理由: 従来のタグなし運用では62イメージの中身が一切追跡できなくなった。日付+SHAなら「そのイメージにどのコミットが入っているか」を後から確実に特定できる。
- push 後は必ず `gcloud artifacts docker images list … --include-tags` でタグが意図どおり付いたかを確認し、このログに記録する。

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
