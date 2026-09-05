# Web アプリの公開手順 — 独自ドメイン・Firebase Hosting・AdSense（web-domain-setup）

作成: 2026-09-05。対象: `webapp/`（Next.js 16）を **独自ドメインで公開し、AdSense を載せる**までの、
オーナー（ソロ開発者）向けの手順書。ドメインを初めて扱う前提で、用語から順に書く。

> 現在地（2026-09-05）: dev は Firebase Hosting の無料 URL `https://bouldering-app-dev.web.app` で公開する構成まで用意済み
> （Cloud Run `bouldering-web-dev` ← Hosting rewrite）。**独自ドメイン・prod・AdSense は未着手**。
> デプロイの実コマンドは `.claude/docs/commands.md`「Web アプリ」、構成は `infrastructure.md`「Web アプリ」。

---

## 0. まず用語（3 分）

| 用語 | 意味 | このプロジェクトでは |
|---|---|---|
| ドメイン | `iwanoboritai.com` のような「住所の名前」。年額で借りる（買い切りではない） | これから取得 |
| レジストラ | ドメインを売る業者（Cloudflare、お名前.com など）。どこで買っても同じドメイン | 下記 1 で選ぶ |
| DNS | 「この名前はどのサーバーか」を答える仕組み。レジストラの管理画面で **レコード**（A / AAAA / TXT / CNAME）を書く | Firebase が指定する値を貼るだけ |
| A / AAAA レコード | 名前 → IPv4 / IPv6 アドレス | Firebase Hosting の IP を登録 |
| TXT レコード | 名前に紐づく自由文。所有確認に使う | Firebase / Search Console の所有確認 |
| 伝播（propagation） | DNS を変えてから世界中に行き渡るまでの待ち時間（数分〜最大 48 時間、通常 1 時間以内） | 待つだけ |
| SSL / HTTPS 証明書 | `https://` にするための証明書 | **Firebase Hosting が無料で自動発行・自動更新** |
| Firebase Hosting | 静的配信 + CDN。ここでは「独自ドメインと SSL を受け持ち、中身は Cloud Run に転送（rewrite）」する役 | サイト `bouldering-app-dev`（既存）+ prod 用（未作成） |
| Cloud Run | Next.js のサーバーが動く場所（コンテナ） | `bouldering-web-dev` / `bouldering-web-prod` |

構成図（prod 完成形）:

```
ブラウザ ── https://<独自ドメイン> ──▶ Firebase Hosting（SSL・CDN・/_next/static キャッシュ）
                                           │ rewrite "**"（同一 GCP プロジェクト・asia-northeast1）
                                           ▼
                                     Cloud Run bouldering-web-prod（Next.js standalone, :8080）
                                           │ fetch（サーバー側）／ブラウザから直接（ログイン後の投稿など）
                                           ▼
                                     Cloud Run bouldering-api-prod（既存バックエンド）
```

---

## 1. ドメインを選んで買う

### 1-1. 名前の候補

- 第一候補: **`iwanoboritai.com`**（アプリ名そのまま・海外でも通る・最安）
- 次点: `iwanoboritai.jp`（日本向けの信頼感。やや高い。Cloudflare では買えない）
- 補助: `iwanoboritai.app`（Google 管理の TLD。**HTTPS 必須**の TLD だが Firebase なら問題なし）
- 避ける: ハイフン入り・長い綴り・`bouldering-app.com` のような一般名詞（SEO・ブランドの両面で弱い）

決め方: **アプリ名と同じ文字列を最優先**。取れれば `.com` を本命にし、余裕があれば `.jp` も押さえて `.com` へ転送（任意）。

### 1-2. レジストラ 2 択（日本のソロ開発者向け）

| | **Cloudflare Registrar**（推奨） | **お名前.com**（GMO） |
|---|---|---|
| 向く人 | 英語 UI が苦でない・余計な営業メールが嫌 | 日本語で完結したい・`.jp` が欲しい |
| 価格（目安・2026 時点） | 原価販売。`.com` 約 US$10〜11/年（≒ ¥1,600〜1,800）。**更新も同額** | `.com` 初年度 ¥0〜1,000 のセール多数、**更新は ¥1,700〜2,200/年 前後**。`.jp` ¥3,000〜4,500/年 |
| Whois 代行（住所非公開） | 無料・標準 | 「Whois 情報公開代行」を **取得時に必ずチェック**（取得後に付けると有料になることがある） |
| 注意 | `.jp` は取り扱い無し。Cloudflare アカウントにサイトを追加（DNS を Cloudflare にする・無料）してから購入する | 有料オプションの初期チェック・更新案内メールが多い。**自動更新の設定と支払い方法の有効期限を確認**（失効すると他人に取られる） |
| DNS 管理画面 | Cloudflare DNS（速い・無料） | お名前.com Navi「DNS レコード設定」 |

- Google Domains は 2023 年に **Squarespace Domains** へ移管された（`.com` 約 US$20/年と高め）。すでに Google アカウントで揃えたい理由がなければ上の 2 つで十分。
- どちらでも「**Whois 代行 ON・自動更新 ON・2 段階認証 ON**」の 3 点は必ず設定する。ドメインを失うと Firebase Auth・AdSense・検索順位をすべて失う。

### 1-3. 買うときの入力

- 登録者情報は本名・実住所（Whois 代行で公開はされない）。
- Cloudflare の場合、購入後に **DNS プロキシ（オレンジ雲）を OFF（DNS only）** にすること。ON のままだと Firebase の SSL 発行や所有確認が失敗する。

---

## 2. ドメインを Firebase Hosting につなぐ

前提: prod は **Firebase プロジェクト `bouldering-app-prod-ca5d7`** に Hosting サイトを作って、そこへ接続する。
dev（`bouldering-app-dev`）へ独自ドメインは付けない（dev は `*.web.app` のままで十分。`noindex` も付いている）。

### 2-1. prod 用 Hosting サイトを作る（1 回だけ）

```bash
# サイト ID は全世界で一意。取れなければ末尾に -web 等
firebase hosting:sites:create bouldering-app-prod --project bouldering-app-prod-ca5d7
firebase hosting:sites:list --project bouldering-app-prod-ca5d7
```

`firebase.json` の `hosting` を **配列 + target** 形式に変え、prod を追加する（dev は今の内容をそのまま `target: dev` に）:

```jsonc
"hosting": [
  { "target": "dev",  "site": "bouldering-app-dev",  "public": "webapp/hosting-public", "ignore": [...],
    "rewrites": [{ "source": "**", "run": { "serviceId": "bouldering-web-dev",  "region": "asia-northeast1" } }],
    "headers": [...] },
  { "target": "prod", "site": "bouldering-app-prod", "public": "webapp/hosting-public", "ignore": [...],
    "rewrites": [{ "source": "**", "run": { "serviceId": "bouldering-web-prod", "region": "asia-northeast1" } }],
    "headers": [...] }
]
```

```bash
firebase target:apply hosting dev  bouldering-app-dev  --project bouldering-app-dev
firebase target:apply hosting prod bouldering-app-prod --project bouldering-app-prod-ca5d7
# → .firebaserc が生成される（コミットしてよい。秘密は含まない）
firebase deploy --only hosting:prod --project bouldering-app-prod-ca5d7
```

> rewrite 先の Cloud Run は **Hosting と同じ GCP プロジェクト**にあり、**未認証呼び出しを許可**している必要がある
> （Firebase 公式 docs/hosting/cloud-run）。`asia-northeast1` は rewrite 対応リージョン（確認済み 2026-09-05）。
> 先に `webapp/deploy/deploy-prod.sh` で `bouldering-web-prod` を 1 回デプロイしておく。

### 2-2. Firebase コンソールでカスタムドメインを追加

1. Firebase コンソール → プロジェクト `bouldering-app-prod-ca5d7` → **Hosting** → サイト `bouldering-app-prod` → **カスタムドメインを追加**
2. ドメイン名を入力（`iwanoboritai.com`。「`www` にもリダイレクト」にチェックすると `www.` も同時に設定できる）
3. **所有権の確認**: 表示される **TXT レコード**（ホスト名 `@`、値 `hosting-site=...` または `google-site-verification=...`）をレジストラの DNS 画面に追加 → コンソールで「確認」
4. **A / AAAA レコード**: 表示される Firebase の IP アドレス（A を 2 件。AAAA が出ればそれも）をホスト名 `@`（と `www`）に追加。
   既存の A / AAAA / CNAME（レジストラのパーキングページ用など）は**削除**する
5. 伝播を待つ（通常 10 分〜1 時間、最大 48 時間）。コンソールのステータスが「保留中」→「接続済み」に変わる
6. **SSL は自動**。「接続済み」になってから最大 24 時間ほどで証明書が発行され `https://` で開けるようになる。Let's Encrypt 相当で自動更新、費用ゼロ

確認コマンド:

```bash
dig +short iwanoboritai.com A          # Firebase の IP が返れば OK
dig +short iwanoboritai.com TXT
curl -sI https://iwanoboritai.com | head -5   # 200 と server: Google Frontend
```

### 2-3. ハマりどころ

- Cloudflare の **プロキシ ON** のまま → 所有確認・SSL が失敗。DNS only にする
- お名前.com の **「DNS 追加オプション」** を契約しないと DNS レコードが編集できない場合がある（無料）。「ネームサーバー設定」が「お名前.com のネームサーバー」になっているか確認
- 古い A レコードが残っている → 「接続済み」にならない
- `www` あり/なし は Firebase 側でリダイレクト設定できる。**正規 URL は `https://iwanoboritai.com`（www なし）に統一**し、`NEXT_PUBLIC_SITE_URL` もそれにする

---

## 3. ドメイン接続後にやること（アプリ側の設定）

順番どおりに。全部やらないと「表示はできるがログインできない／地図が出ない」になる。

| # | 作業 | 場所 | 具体 |
|---|---|---|---|
| 1 | `NEXT_PUBLIC_SITE_URL` を独自ドメインに | `webapp/.env.prod.local` | `NEXT_PUBLIC_SITE_URL=https://iwanoboritai.com`（末尾スラッシュなし）。sitemap / canonical / OG に使われる |
| 2 | Firebase Auth の承認済みドメインに追加 | Firebase コンソール（prod）→ Authentication → 設定 → **承認済みドメイン** | `iwanoboritai.com` を追加。無いと Google / Apple ログインが `auth/unauthorized-domain` で失敗 |
| 3 | `authDomain` を独自ドメインに（推奨） | `.env.prod.local` の `NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN` | `iwanoboritai.com` にすると、ログインのポップアップ／リダイレクトが自ドメインで完結する（Hosting は `/__/auth/*` を rewrite より先に自動処理する）。既定の `<project>.firebaseapp.com` のままでも動く |
| 4 | Apple ログイン（Web）の設定 | Apple Developer → Services ID → Sign In with Apple → **Return URLs** に `https://<authDomain>/__/auth/handler` | Firebase コンソールの Apple プロバイダに Services ID・チーム ID・キー ID・秘密鍵を登録（iOS のみだった設定に Web 分を追加。`infrastructure.md`「認証」参照） |
| 5 | Maps ブラウザキーのリファラ | GCP（prod）→ API とサービス → 認証情報 → 「Web Maps API Key - Prod」（未作成なら dev と同じ設定で作る） | HTTP リファラに `https://iwanoboritai.com/*` と `https://www.iwanoboritai.com/*` を追加 |
| 6 | バックエンド API の CORS | Cloud Run `bouldering-api-prod` の環境変数 `ALLOWED_ORIGINS` | `https://iwanoboritai.com` を追加して `gcloud run services update ... --update-env-vars ALLOWED_ORIGINS=...`。**ブラウザから直接 API を叩く（ログイン後の投稿等）に必須**。サーバー側 fetch は不要 |
| 7 | GCS バケットの CORS | `boulderingapp_tweets_media`（prod） | **ブラウザから直接バケットへアップロードする実装がある場合のみ**。画像の表示（`<img>` / `next/image`）には不要 |
| 8 | prod 再デプロイ | `webapp/deploy/deploy-prod.sh --confirm-prod` | `NEXT_PUBLIC_*` は**ビルド時に埋め込まれる**ため、値を変えたら必ず再ビルド |
| 9 | Search Console | https://search.google.com/search-console | 「ドメイン」プロパティで追加 → TXT で所有確認（Firebase の確認とは別レコード。共存可）→ **サイトマップ** に `https://iwanoboritai.com/sitemap.xml` を送信 |
| 10 | robots / noindex の確認 | `curl -sI https://iwanoboritai.com` | `X-Robots-Tag: noindex` が**付いていない**こと（`NEXT_PUBLIC_APP_ENV=prod` でビルドされていれば付かない） |

---

## 4. Google AdSense

### 4-1. 申請できる条件（満たしてから申請する）

- **自分のドメイン**であること（`*.web.app` では申請不可）
- **オリジナルの内容**が十分にある（ジム情報ページ・都道府県別一覧・ボル活フィードは該当。ただし「ほぼ写真だけ」「他サイトの転載」はリジェクト理由になる）
- 必須ページ: **プライバシーポリシー**（Cookie・AdSense・Google Analytics の利用を明記）、**お問い合わせ**、可能なら **運営者情報**。アプリの既存ポリシーを Web に載せる（`/privacy` `/contact` を home チームに依頼）
- **ads.txt**: `https://iwanoboritai.com/ads.txt` に `google.com, pub-XXXXXXXXXXXXXXXX, DIRECT, f08c47fec0942fa0` を配信（`webapp` は `/ads.txt` ルートを持つ。`NEXT_PUBLIC_ADSENSE_CLIENT` 設定後に内容が出る想定。空のうちは 404 でも申請自体は可能だが、承認後 1 週間以内に用意する）
- 18 歳以上・AdSense アカウントは **1 人 1 つ**（既存アカウントがあればそれに「サイトを追加」）
- **ユーザー投稿（UGC）**があるサイトは「不適切な内容」で落ちやすい → 通報機能・NG ワード・削除運用があることをポリシーページに書いておく

### 4-2. 申請の流れ

1. https://www.google.com/adsense/ → 開始 → サイト URL `https://iwanoboritai.com` と支払い国（日本）を登録
2. 発行される **パブリッシャー ID `ca-pub-XXXXXXXXXXXXXXXX`** を控える
3. `webapp/.env.prod.local` に `NEXT_PUBLIC_ADSENSE_CLIENT=ca-pub-XXXXXXXXXXXXXXXX` を設定 → **prod 再デプロイ**。これで
   `<head>` に AdSense のスクリプト（`AdSenseScript`）が入り、`/ads.txt` も出る
4. AdSense 画面で「サイトを審査に送信」（コードが検出されると押せる）
5. 審査: **数日〜2 週間、長いと 1 か月**。結果はメール。落ちたら理由（「価値の低い広告枠」「ポリシー違反」等）に沿って直し再申請（回数制限なし）
6. 承認後: 「広告 → 広告ユニット」で **ディスプレイ広告ユニット**を作り、`data-ad-slot` を `AdSlot` に設定する（ユニット ID は公開値。`webapp` の ads チームに渡す）
7. 収益が発生したら住所確認の **PIN が郵送**（数週間）→ 入力 → 支払い口座登録。¥8,000 に達した翌月 21 日以降に振込

### 4-3. 審査中・未設定のあいだ

- `NEXT_PUBLIC_ADSENSE_CLIENT` が空のとき、`AdSlot` は **同寸の仮枠（プレースホルダ）** を表示するだけで AdSense のスクリプトは読み込まない（`webapp/src/components/ads/`）。レイアウト崩れを防ぐための仕様
- dev（`*.web.app`）には絶対に本番の `ca-pub-` を入れない（無効トラフィック扱いの原因）

---

## 5. 費用の目安（月額換算・2026-09 時点。実額は各社の料金ページで要確認）

| 項目 | 無料枠 | 想定コスト（個人サイト規模: 月 1〜5 万 PV） | 備考 |
|---|---|---|---|
| ドメイン `.com` | なし | **¥150〜200/月**（年 ¥1,700〜2,200） | Cloudflare は原価。`.jp` は年 ¥3,000〜4,500 |
| Firebase Hosting（Blaze） | ストレージ 10 GB、転送 360 MB/日（≒10 GB/月） | **¥0〜数百円** | 超過は転送 US$0.15/GB。静的ファイルは Cloud Run 側から配信され Hosting の CDN にキャッシュされる。SSL 無料 |
| Cloud Run `bouldering-web-*` | 月 200 万リクエスト・180,000 vCPU 秒・360,000 GiB 秒 | **¥0〜500** | `min-instances 0` なのでアクセスが無ければ ¥0。初回アクセスにコールドスタート 1〜3 秒。常時起動（`min-instances 1`）にすると ¥1,000〜2,000/月 |
| Cloud Build | 1 日 120 分（e2-medium 換算） | **¥0〜100**（デプロイ回数次第） | `E2_HIGHCPU_8` は US$0.016/分。1 回 3〜5 分 → 十数円 |
| Artifact Registry | 0.5 GB | **¥0〜100** | US$0.10/GB/月。古い `web:` イメージは定期的に削除（backend と同じリポジトリ） |
| Google Maps JavaScript API | **月 10,000 マップロードまで無料**（2025-03 の料金改定・Essentials） | **¥0**（1 万ロード超で US$7/1,000） | Places 等は別 SKU。ブラウザキーはリファラ制限必須。予算アラートを GCP に設定しておく |
| Firebase Auth | Google / Apple ログインは無料 | ¥0 | 電話認証のみ有料 |
| Search Console / AdSense | 無料 | ¥0 | AdSense は収益側 |
| **合計** | | **月 ¥200〜1,000 程度**（ほぼドメイン代） | 常時起動にしない限り |

- GCP の **予算アラート**（例: 月 ¥2,000）を prod プロジェクトに作っておく（請求 → 予算とアラート）。Maps キー流出時の保険。

---

## 6. 全体の順番（チェックリスト）

```
[ ] 1. ドメイン購入（Whois 代行・自動更新・2FA）
[ ] 2. prod Hosting サイト作成 → firebase.json を target 形式に → deploy-prod.sh の PROD_HOSTING_SITE 記入
[ ] 3. .env.prod.local 作成（SITE_URL=独自ドメイン / API=bouldering-api-prod / Maps prod キー / Firebase prod Web アプリ）
      ※ prod の Firebase Web アプリ・「Web Maps API Key - Prod」は未作成 → dev と同じ手順で作る（infrastructure.md）
[ ] 4. deploy-prod.sh --dry-run → --confirm-prod（Cloud Run bouldering-web-prod + Hosting）
[ ] 5. Firebase コンソールでカスタムドメイン接続（TXT → A/AAAA → SSL 待ち）
[ ] 6. 3 章の 10 項目（Auth 承認済みドメイン・Maps リファラ・ALLOWED_ORIGINS・Search Console …）
[ ] 7. プライバシーポリシー / お問い合わせページ公開 → AdSense 申請 → 承認後 ca-pub を設定して再デプロイ
[ ] 8. deployment-log.md / release-log.md に記録
```

参考（一次情報）:
- Firebase Hosting × Cloud Run: https://firebase.google.com/docs/hosting/cloud-run
- Firebase Hosting カスタムドメイン: https://firebase.google.com/docs/hosting/custom-domain
- Hosting のキャッシュと Cookie（`__session` 以外は Cloud Run に届かない）: https://firebase.google.com/docs/hosting/manage-cache
- Next.js standalone / Docker: `webapp/node_modules/next/dist/docs/01-app/03-api-reference/05-config/01-next-config-js/output.md`
- AdSense 申請要件: https://support.google.com/adsense/answer/9724
