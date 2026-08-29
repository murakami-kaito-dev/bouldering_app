# 課題リスト（action-items）

このプロジェクトの**未対応の課題台帳**。修正・実装で発生した項目もここに集約する。

**運用ルール（2026-08-29 制定）**:
- 課題が**片付いたら、この表から除去**する（対応の記録は `deployment-log.md` / 該当PR に残す）。
- **新しく見つかった／実装の過程で生まれた課題は、ここに追加**する。
- 詳細な根拠・行番号は `refactor-candidates.md` を参照（本ファイルは「何を・どの優先度で」の一覧）。
- 着手順の推奨: 🔴セキュリティ → 🟠機能バグ → 🟡インフラ整備 → 🟢コード整理。

最終更新: 2026-08-29

---

## 🔴 セキュリティ（最優先）

| ID | 内容 | 参照 |
|---|---|---|
| S-1 | `POST /api/reports` に認証がなく、`reporter_user_id` をボディで受けるためなりすまし通報が可能 | refactor B-3 |
| S-2 | `/internal/tasks` のGCS削除がOIDC未検証。外部から任意プレフィックスの画像を一括削除可能 | B-4 |
| S-3 | `.dockerignore` の漏れで `.env.dev/.env.prod`（DBパスワード入り）がDockerイメージに焼き込まれる | B-5 |
| S-4 | `lib/shared/config/environment_config.dart` にDBパスワードが平文ハードコード（Git追跡下・当該コードは未使用） | B-6 |
| S-5 | GCSサービスアカウント鍵がアプリバイナリに同梱され抽出可能 | B-7 / secrets-map |
| S-6 | ローカル `docs/` 内に平文のDBパスワード・APIキー・クレカ番号・住所が残存（Git管理外だがイメージ焼き込みリスク） | secrets-map |

## 🟠 機能バグ

| ID | 内容 | 参照 |
|---|---|---|
| G-1 | メディア削除APIが RETURNING 漏れで常に404を返す | B-1 |
| G-2 | ジムのイキタイ/ボル活ランキングAPIがルート定義順で到達不能 | B-2 |
| G-3 | 地図の距離計算がハーバーサイン数式ミス → 半径フィルタが正しく効かない | B-8 |
| G-4 | ユーザー別ツイートのページネーションで offset が無視される | B-9 |
| G-5 | ジム検索画面が build 内副作用で無限リビルドしうる構造 | B-10 |
| G-6 | 地図ピン画像パス誤りで常にデフォルトマーカー表示 | B-11 |
| G-7 | 設定画面のバージョン表記が「1.0.0」固定（実際は1.0.1+2） | B-12 |
| G-8 | `likes`系: フロントが叩くがバックエンドにルートが存在しない | B-14 |
| G-9 | `ApiClient` の例外二重ラップで statusCode が失われ401判別不能 | B-13 |
| G-10 | エラー時に永久スピナー/スクロール判定の厳密等値など、UI系の小バグ複数 | B-18,B-19,B-20 ほか |

## 🟡 インフラ・設定の整備

| ID | 内容 | 参照 |
|---|---|---|
| I-1 | `.env.prod` が未使用のまま放置（削除 or 整理の判断） | 本セッション調査 |
| I-2 | dev/prodでSupabaseプーラー種別とSSL設定が不統一（dev=共有プーラー/require、prod=専用プーラー/disable。動作はする） | infrastructure.md |
| I-3 | `firebase.json` が存在しない `lib/firebase_options.dart` を指す | 設定6節 |
| I-4 | iOSスキーム不整合（`Runner Prod.xcscheme` が `Bouldering App Dev.app`／存在しない構成を参照） | I-B17 |
| I-5 | `Info.plist` 表示名ハードコードで dev/prod のアプリ名が実際には分離されていない | infrastructure.md |
| I-6 | `backend/docker` がローカル依存シンボリックリンクなのにGit追跡下（誤コミット） | 5節 A1 |
| I-7 | Supabase の public テーブルが dev/prod とも9件、ドキュメントは7テーブル → スキーマとドキュメントの乖離 | 本セッション調査 |
| I-8 | 過去のdevイメージがタグなしで追跡不能（今後はタグ運用ルール適用済み。過去分は復元不可） | deployment-log.md |

## 🟢 コード整理（リファクタ）

| ID | 内容 | 参照 |
|---|---|---|
| R-1 | フロント未使用ファイル（mock群約1,400行、`favorite_gym_provider`、`tweet_post_provider`、`user_card` 等） | refactor 1〜2節 |
| R-2 | 重複ロジック（営業時間判定の二重実装、ナビゲーション3方式混在、お気に入りページの左右対称重複 等） | 3節 |
| R-3 | 冗長・デッドコード（中身なし `try/catch(rethrow)` 32箇所、`print()` のリリース混入 等） | 4節 |
| R-4 | バックエンド未使用（`storageService`、未使用の `eventBus` 注入、認可チェック13回コピペ 等） | 5節 |
| R-5 | pubspec の未使用依存9パッケージ（`go_router`/`auto_route`/`sqflite` 等） | 4節 |

## 📄 ドキュメント整合

| ID | 内容 | 参照 |
|---|---|---|
| D-1 | `lib/README.md` が古い（`lib_new/` 表記等）、`docs/README.md` のリンク切れ、ルート `README.md` の Android ビルドコマンドが動かない | architecture.md 末尾 |

---

## 完了済み（記録用・次回更新時に古いものは削除可）

- ✅ 2026-08-29 `backend/.env.dev` の接続情報修正（→ deployment-log.md）
- ✅ 2026-08-29 tsconfig-paths 死に参照削除でローカル起動修復（PR #24）
- ✅ 2026-08-29 全インフラ接続確認（GCP/Firebase/Docker/GitHub/Supabase dev+prod）
