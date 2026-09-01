# デザイン提案「岩と粉」（v2.1想定・2026-09-01）

**モック（提案本体）**: https://claude.ai/code/artifact/d10b59dc-8a06-4c59-8e1e-568842994257
（主要4画面モック・パレット・タイポ・Before/After・実装計画を収録）

## 決定経緯

- ユーザー回答: 方向性=**A 岩壁とチョーク（ダーク）**／狙う印象=**かっこいい・スポーツ**／
  好きな参考=Strava/Nike・YAMAP・Duolingo/みてね（3系統全部）→ ダーク基調に
  「情報の見やすさ(YAMAP)」と「褒める瞬間(Duolingo)」を混ぜる方針
- 現状診断: 生Material色121箇所散乱・青2種混在(#0056FF/#007AFF)・角丸10種・フォント個性なし
- 過去のWIPブランチ refactor/ui-design-update はカジュアルパステル路線（今回のB案に相当）→ 今回A採用により方向転換

## トークン（確定案）

| 名前 | 値 | 役割 |
|---|---|---|
| 岩肌 | #15171B | 背景 |
| 節理 | #1E2126 | カード面 |
| 割れ目 | #2D313A | 罫線 |
| チョーク | #F2F0EA | 主文字 |
| 砂埃 | #9AA0AA | 副文字 |
| 壁ブルー | #5B8CFF | ブランド・主ボタン（現行#0056FFの進化形） |
| ホールド赤 | #FF7264 | ボルダリング種別 |
| ホールド緑 | #3FCF8E | リード種別・営業中 |
| ホールドシアン | #3EC6E0 | スピード種別 |

- 角丸3種: テープ2 / カード14 / ピル・アバター999
- フォント: 見出し=Zen Kaku Gothic New Bold / 数字=Barlow Condensed SemiBold / 本文=Noto Sans JP（google_fonts導入済み・未使用を活用）
- シグネチャ: **課題テープ**（skewX(-8deg)の平行四辺形チップ。種別タグ・選択タブ・ラベル）
- モーション3箇所限定: 投稿完了チョークパフ / タブのテープスライド / 押下スプリング（animation-effectsスキル）

## 実装計画

1. Phase 1: トークンクラス新設＋ThemeData差し替え＋生色121箇所置換（全画面が一括で概ね新テーマ化）
2. Phase 2: 主要4画面（ホーム・タイムライン・ジム詳細・マイページ）作り込み＋テープコンポーネント
3. Phase 3: 残り画面追従＋演出＋地図ダークスタイル

## 決定事項（2026-09-01 ユーザー承認）

- [x] この方向でGO
- [x] **ダーク一本**（ライト切替なし）
- [x] **地図はライトスタイル維持**（見やすさ優先。周辺UIのみダーク）
- [x] **アプリアイコンは差し替え**（ユーザーがNano Banana Proで生成→受領後に反映。
      生成プロンプトは提供済み: 案1チョーク手形(推奨)/案2ホールド/案3岩の線画）

## Phase 1 実施記録（2026-09-01）

- lib/presentation/theme/app_tokens.dart 新設（AppColors/AppRadius）
- ThemeData全面差し替え（dark・StadiumBorderボタン・カード14・入力欄filled）
- スプラッシュ/LaunchScreen.storyboardを岩肌色に
- 52ファイル・約370箇所の色literalをトークンへ置換（8並列エージェント・エラー0・ビルド成功）
- 既知の残課題: GymCategory/SwitcherTab/Button等がint colorCodeを受けるAPIのため
  同値hexで暫定対応 → Phase 2でColor型化・テープコンポーネント化
- user_card.dartの_buildStatChip（MaterialColorシェード参照）はPhase 2対応
