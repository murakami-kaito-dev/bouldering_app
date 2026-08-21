# .claude/docs 索引

Claude Code 用のプロジェクト情報集約場所（2026-08-21 全ファイル調査に基づく）。
**コードが正**: 既存の docs/・README と食い違う場合はコードの事実を採用している。

| ファイル | 内容 |
|---|---|
| [architecture.md](architecture.md) | 全体構成・フロント/バックエンドの層構造・環境切替の仕組み・機能一覧・docsとコードの乖離 |
| [infrastructure.md](infrastructure.md) | dev/prod対応表（GCP/Firebase/Supabase/Cloud Run/GCS）・環境変数・iOSビルド構成・重要な要注意点 |
| [commands.md](commands.md) | fdev系エイリアス・Dockerビルド/Cloud Runデプロイ・リリースビルド手順 |
| [development-history.md](development-history.md) | 開発経緯（全コミット+PR履歴から再構成） |
| [release-log.md](release-log.md) | バージョン・配信履歴（復元分含む） |
| [secrets-map.md](secrets-map.md) | 秘密情報の**所在**マップ（値は不記載）・既知のセキュリティ問題 |
| [refactor-candidates.md](refactor-candidates.md) | バグ・未使用・重複・冗長コードの候補メモ（**削除はユーザー許可後**） |

## 関連ルール（.claude/rules/）

- [git-branch-workflow.md](../rules/git-branch-workflow.md) — main直コミット禁止・ブランチ→PR運用（このプロジェクト専用）
- [no-edit-without-permission.md](../rules/no-edit-without-permission.md) — 許可までコード・インフラ編集禁止（現在有効）

## 既存ドキュメントとの関係

- `docs/`（Git非管理・機密込みの一次資料）と `docs_public/`（サニタイズ済み公開版）は従来通り。移動・削除はしていない
- `.claude/docs/` は「Claudeが素早く全体を把握する」ための要約層。詳細手順は `docs/deployment/` `docs/setup/` を参照
