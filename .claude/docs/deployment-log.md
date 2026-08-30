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
