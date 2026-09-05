# イワノボリタイ Web — Rock & Chalk
> A route-setter's tape board in a chalk-dusted gym

**Theme:** dark（単一テーマ・ライト切替なし）

ボルダリングジムの壁は暗い岩肌、ホールドを示す色テープ、粉のチョーク。この三つだけで画面を組む。
数字（イキタイ・ボル活・料金・営業時間）は「ジムの課題ボード」のように大きく、コンデンス体で読ませる。
装飾はテープ以外に足さない。UI は道具であり、地図とリストは並べて使える「計器」として設計する。

Live product: https://bouldering-app-dev.web.app（dev）／ iOS アプリ「イワノボリタイ」

参考にした決め方の粒度: https://styles.refero.design/（Linear / Strava 系の「暗い精密計器」の構造。値は流用しない）

## Tokens — Colors

| Name | Value | Token | Role |
|---|---|---|---|
| 岩肌 Rock | `#15171B` | `--color-rock` | ページ背景 |
| 節理 Joint | `#1E2126` | `--color-joint` | カード・パネル面 |
| 段差 Ledge | `#262A31` | `--color-ledge` | 浮いた面（ホバー・入力欄・地図上のカード） |
| 割れ目 Crack | `#2D313A` | `--color-crack` | 罫線・区切り |
| チョーク Chalk | `#F2F0EA` | `--color-chalk` | 主文字・見出し |
| 砂埃 Dust | `#9AA0AA` | `--color-dust` | 副文字・ラベル・プレースホルダ |
| 灰 Ash | `#838A97` | `--color-ash` | 無効・三次文字・広告ラベル（rock/joint 上で 4.5:1 以上） |
| 壁ブルー Wall | `#5B8CFF` | `--color-wall` | ブランド・主ボタン・リンク |
| 壁ブルー（明） | `#7AA2FF` | `--color-wall-bright` | ホバー・フォーカスリング |
| 壁ブルー（墨） | `#0B1020` | `--color-wall-ink` | 青地の上の文字 |
| ホールド赤 | `#FF7264` | `--color-hold-red` | 種別「ボルダリング」・エラー |
| ホールド緑 | `#3FCF8E` | `--color-hold-green` | 種別「リード」・営業中 OPEN |
| ホールドシアン | `#3EC6E0` | `--color-hold-cyan` | 種別「スピード」・情報 |
| テープ黄 | `#F5C542` | `--color-tape-yellow` | 強調テープ（人気・NEW）・イキタイ数 |

- 背景は純黒にしない（`#15171B` の温い墨）。面は 3 段（rock → joint → ledge）だけで奥行きを作る。影は使わない。
- 種別色は**意味**を持つ（赤=ボルダリング／緑=リード／シアン=スピード）。装飾に流用しない。
- 文字コントラスト: chalk on rock 14.9:1、dust on rock 6.4:1、wall-ink on wall 8.5:1（すべて AA 以上）。

## Tokens — Typography

### Zen Kaku Gothic New — 日本語見出し · `--font-display`
- **Substitute:** "Hiragino Sans", "Noto Sans JP", sans-serif
- **Weights:** 500, 700
- **Sizes:** 20–56px
- **Line height:** 1.15–1.3
- **Letter spacing:** -0.01em（40px 以上は -0.02em）
- **Role:** ページ見出し・ジム名・セクション見出し。太さで階層を作り、色は chalk 一色。

### Barlow Condensed — 数字と英字ラベル · `--font-numeric`
- **Substitute:** "Arial Narrow", sans-serif
- **Weights:** 500, 600, 700
- **Sizes:** 12–72px
- **Line height:** 1.0（数字は 0.95）
- **Letter spacing:** 0.08em（12–14px の大文字ラベル）／ 0（数字）
- **OpenType features:** `tnum`（表の数字を揃える）
- **Role:** イキタイ・ボル活の大きな数字、料金、営業時間、`OPEN/CLOSE`、英字のアイブロウ（`GYMS 431`）。

### Noto Sans JP — 本文 · `--font-body`
- **Substitute:** "Hiragino Sans", system-ui, sans-serif
- **Weights:** 400, 500
- **Sizes:** 13–17px
- **Line height:** 1.7
- **Letter spacing:** 0.01em
- **Role:** 説明文・住所・投稿本文・フォーム。

### Type Scale

| Role | Size | Line Height | Letter Spacing | Token |
|---|---|---|---|---|
| Display（ホームの見出し） | 56 / 40(mobile) | 1.1 | -0.02em | `text-display` |
| H1（ジム名・ページ題） | 36 / 28 | 1.2 | -0.01em | `text-h1` |
| H2（セクション） | 24 / 20 | 1.3 | -0.01em | `text-h2` |
| H3（カード見出し） | 18 | 1.4 | 0 | `text-h3` |
| Stat（大きな数字） | 48–72 | 0.95 | 0 | `text-stat` |
| Body | 16 | 1.7 | 0.01em | `text-body` |
| Small | 13 | 1.6 | 0.01em | `text-small` |
| Eyebrow（英字大文字） | 12 | 1 | 0.08em | `text-eyebrow` |

## Tokens — Spacing & Shapes

**Base unit:** 4px
**Density:** Default（一覧と地図は Compact）

### Spacing Scale
| Name | Value | Token |
|---|---|---|
| 1 | 4px | `--space-1` |
| 2 | 8px | `--space-2` |
| 3 | 12px | `--space-3` |
| 4 | 16px | `--space-4` |
| 6 | 24px | `--space-6` |
| 8 | 32px | `--space-8` |
| 12 | 48px | `--space-12` |
| 16 | 64px | `--space-16` |

### Border Radius
| Element | Value |
|---|---|
| テープ（チップ・タブ・ラベル） | 2px |
| カード・パネル・入力欄 | 14px |
| ボタン・ピル・アバター | 999px |
| 地図・写真の枠 | 14px |

### Shadows
| Name | Value | Token |
|---|---|---|
| なし | 面の段差（rock/joint/ledge）と 1px の crack 線だけで奥行きを出す | — |
| フォーカスリング | `0 0 0 3px rgb(122 162 255 / 0.45)` | `--ring` |

### Layout
- **Page max-width:** 1200px（本文は 720px）
- **Gutter:** 20px（mobile）／ 32px（≥768px）
- **Section gap:** 64px（mobile 48px）
- **Card padding:** 20px（Compact 16px）
- **Element gap:** 12px
- **検索ページ:** ≥1024px で「リスト 440px ｜ 地図 残り幅」の 2 ペイン。地図はビューポート高に固定（sticky）。<1024px はリストのみ＋右下の「地図」ボタンで全画面地図に切替。
- **詳細ページ:** ≥1024px で「本文 ｜ 右レール 360px（地図・アプリ導線・広告）」。右レールは sticky。

## Components

### Tape（課題テープ）
**Role:** 種別・状態・選択タブを示すチップ。サイトの署名。
Background 種別色 12% + 種別色の文字, font Barlow Condensed 600 12px uppercase letter-spacing 0.08em, padding 2px 10px, `transform: skewX(-8deg)`（中の文字は `skewX(8deg)` で戻す）, radius 2px。選択中は塗り 100% + wall-ink 文字。`OPEN` は hold-green、`CLOSE` は ash。

### Stat（課題ボードの数字）
**Role:** イキタイ／ボル活／料金の数字を主役にする。
Number Barlow Condensed 700 48–72px line-height 0.95 color chalk（イキタイは tape-yellow）, label 12px uppercase dust eyebrow 上に配置。数字と単位（`円〜`, `人`）は 0.5em の間隔。

### Button
**Role:** 主行動（アプリで開く・投稿する・検索）。
Primary: background wall, text wall-ink, radius 999px, height 44px, padding 0 20px, font Zen Kaku 700 15px, hover wall-bright, active `scale(0.97)`。
Secondary: background transparent, border 1px crack, text chalk, hover background ledge。
Ghost: text wall, underline on hover。

### GymCard（一覧）
**Role:** 比較して選ぶための 1 行。
Background joint, radius 14px, padding 16px, border 1px transparent（hover: border crack, background ledge）。左に写真 96×96（無ければ岩肌のプレースホルダに種別テープ）、右に「ジム名（Zen 700 18px）／市区町村（dust 13px）／テープ列（種別・OPEN）／下段に Stat 小（イキタイ・ボル活・最低料金）」。地図と連動するときは選択状態で左端に 3px の wall 縦線。

### Map
**Role:** 場所で選ぶ計器。
Google Maps JS（ライトスタイルは使わず、暗いカスタムスタイル。水面 `#0F1114`、道路 `#2D313A`、ラベル dust）。マーカーは種別色の丸 + 選択時に拡大＋wall のリング。地図の上に載せるカードは ledge 面。

### Section header
**Role:** 見出しの前に英字アイブロウ、下にテープ線。
Eyebrow（Barlow 600 12px uppercase dust）→ H2（Zen 700）→ 幅 40px 高さ 3px の wall テープ（`skewX(-8deg)`）。

### AdSlot
**Role:** 広告枠（AdSense）。
Background joint, border 1px dashed crack, radius 14px, min-height 250px（sidebar 300×250 / 一覧の in-feed 横長）。ラベル `AD` を eyebrow で右上に。クライアント ID 未設定時は同サイズの空枠を出し、レイアウトシフトを起こさない。

### AppCta（アプリ導線）
**Role:** Web からアプリへの流入。
ledge 面のカード。左に App Store バッジ、右に「地図でジムを探す・ボル活を記録する」の 2 行。ジム詳細では「このジムをアプリで開く」（`iwanoboritai://gym/<id>` へのユニバーサルリンクは未整備のため App Store へ）。

## Do's and Don'ts

### Do
- 数字は必ず Barlow Condensed で `tnum` を効かせる。日本語見出しは Zen Kaku、本文は Noto Sans JP。三つの書体の役割を混ぜない。
- 種別は必ずテープ（Tape）で示す。テキストだけ・アイコンだけにしない。
- 営業中判定・「今日」の判断は **日本時間（JST）固定**。端末やサーバーの TZ を使わない（`lib/gym/hours.ts`）。
- 一覧と地図は同じ選択状態を共有する（カードのホバー＝マーカーの強調）。
- 画像には必ず `alt`（ジム名）。Google Places 由来の写真は投稿者クレジットを表示する。
- 空状態は次の行動を示す（「この条件のジムはまだありません。都道府県を広げる」）。
- フォーカスリング（`--ring`）を全ての操作要素に出す。`prefers-reduced-motion` でスプリングを止める。

### Don't
- 影・グラデーション・ガラス効果を足さない。奥行きは面の 3 段と 1px 線だけ。
- 純黒 `#000` と純白 `#FFF` を使わない。
- 種別色を装飾（背景・見出し）に流用しない。
- 角丸を 3 種（2 / 14 / 999）以外に増やさない。
- モバイルアプリの画面をそのまま横に伸ばさない（Web は 2 ペイン・sticky レール・ホバーを前提に組む）。
- 絵文字をアイコン代わりに使わない。

## Quick Start

```css
:root {
  --color-rock: #15171B; --color-joint: #1E2126; --color-ledge: #262A31; --color-crack: #2D313A;
  --color-chalk: #F2F0EA; --color-dust: #9AA0AA; --color-ash: #838A97;
  --color-wall: #5B8CFF; --color-wall-bright: #7AA2FF; --color-wall-ink: #0B1020;
  --color-hold-red: #FF7264; --color-hold-green: #3FCF8E; --color-hold-cyan: #3EC6E0; --color-tape-yellow: #F5C542;
  --radius-tape: 2px; --radius-card: 14px; --radius-pill: 999px;
  --ring: 0 0 0 3px rgb(122 162 255 / 0.45);
}
```

Tailwind v4 では `src/app/globals.css` の `@theme` に同じ名前で登録済み: `bg-rock` `bg-joint` `bg-ledge` `border-crack`
`text-chalk` `text-dust` `text-ash` `bg-wall` `text-wall-ink` `text-hold-red` `text-hold-green` `text-hold-cyan` `text-tape-yellow`、
書体は `font-display` `font-numeric` `font-body`、角丸は `rounded-tape` `rounded-card` `rounded-pill`。
