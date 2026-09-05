@AGENTS.md

# webapp/ — イワノボリタイ Web（Next.js）

iOS アプリ「イワノボリタイ」の Web 版。**ジム検索・ジム詳細・みんなのボル活・ログイン・ボル活投稿・マイページ**を持ち、
独自ドメインで公開し AdSense を載せ、iOS アプリへの流入を狙う。バックエンドはアプリと同じ Cloud Run API。

## 必読（順に）
1. `DESIGN.md` — デザインの正典（トークン・書体・部品・Do/Don't）。**ここに無い色・角丸・書体を発明しない。**
2. `src/lib/api/*` — API 型と取得関数。生 JSON（snake_case）は `normalize*` で正規化してから UI へ。
3. `src/lib/gym/hours.ts` — 営業時間の判定は **JST 固定**。`new Date()` の getHours 等を直接使わない。
4. `node_modules/next/dist/docs/` — Next 16 は学習データと違う（`params`/`searchParams` は Promise、`proxy.ts`、`PageProps<'/path'>`）。

## 構成
- `src/app/` … ルート（App Router）。`(site)` などの route group は使っていない
- `src/components/ui/` … Tape / Button / Primitives（Container, Eyebrow, SectionHeader, Stat, Panel, Skeleton）
- `src/components/site/` … SiteHeader / SiteFooter / AppCta / HeaderAuth
- `src/components/ads/` … AdSlot（未設定時は同寸の仮枠）/ AdSenseScript
- `src/lib/env.ts` … 環境変数（`NEXT_PUBLIC_*` は公開値。秘密は置かない）

## ルート（担当チーム）
| パス | 役割 | 担当 |
|---|---|---|
| `/` | ホーム（検索の入口・人気ジム・新着ボル活・アプリ導線） | home |
| `/gyms` | 検索（`?q=&pref=&type=&sort=&near=`）: リスト｜地図の 2 ペイン | search |
| `/gyms/area/[slug]` | 都道府県別一覧（SEO） | search |
| `/gyms/[id]` | ジム詳細（施設情報・営業時間・料金・写真・地図・ボル活タブ・アプリ導線） | detail |
| `/boul-log` | みんなのボル活（読み取り） | feed |
| `/login` `/me` `/post` `/users/[id]` | 認証・マイページ・投稿・公開プロフィール | auth |
| `/sitemap.xml` `/robots.txt` `/ads.txt` `opengraph-image` | SEO・広告 | home |

## ルール
- **秘密をコミットしない**（`.env.local` は gitignore 済み）。Maps キーは HTTP リファラ制限付きブラウザキー。
- サーバー側の読み取りは `revalidate` で必ずキャッシュ（全ジム 1h・詳細 10m・ボル活 60s）。
- 画像は `next/image` + `remotePatterns`（`next.config.ts`）。Google Places 写真は投稿者クレジット必須。
- 営業中・今日・投稿日は JST。日付は `'YYYY-MM-DD'` 文字列で API と受け渡す。
- スタイルは Tailwind v4 のトークン（`bg-rock` `text-chalk` `font-numeric` …）と `globals.css` の型クラス（`text-h1` `text-eyebrow` `tape` …）だけを使う。
- `npm run lint` と `npm run build` が通る状態で PR に含める。
- コミット・PR はリポジトリ直下の `CLAUDE.md`／`.claude/rules/` に従う（main 直コミット禁止・ブランチ→PR）。

## 実行
```
cd webapp && npm run dev        # http://localhost:3000（.env.local が要る）
npm run build && npm run start  # 本番相当（standalone 出力）
```
