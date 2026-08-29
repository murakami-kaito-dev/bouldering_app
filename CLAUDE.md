# CLAUDE.md — イワノボリタイ（bouldering_app）

ボルダリングジム検索・ボル活記録SNS。**iOS配信済み（v1.0.1+2）の本番アプリ**。
Flutter + Cloud Run(Express/TS) + Firebase Auth + Supabase。dev/prod 完全分離。

## 最重要ルール（このプロジェクト専用・グローバルルールより優先）

1. **ユーザー許可があるまでコード・インフラを編集しない**（現在有効）。
   調査・報告・`.claude/` 整備のみ可。詳細: `.claude/rules/no-edit-without-permission.md`
2. **main 直接コミット禁止**。機能/修正ごとに `feature/` `fix/` `refactor/` `docs/` ブランチ → PR → ユーザーがレビュー・マージ。
   詳細: `.claude/rules/git-branch-workflow.md`（グローバルの「main直コミット可」はこのプロジェクトでは無効）
3. **コードが正**。docs/・README・ユーザーの記憶と食い違ったらコードを信じ、乖離を報告する。
4. 秘密（.env、鍵、パスワード、`docs/` 内の機密）は読まない・書かない・コミットしない。所在は `.claude/docs/secrets-map.md`。
5. dev/prod 二系統: 日常は **dev のみ**（`fdev`）。prod はリリース時のみ。環境は「エントリポイント × --dart-define × --flavor」の3点セットで必ずエイリアス経由で切替（片手落ちは環境混在事故になる）。

## 情報の地図

| 知りたいこと | 場所 |
|---|---|
| 全体像・アーキテクチャ | `.claude/docs/architecture.md` |
| dev/prod対応表・インフラ | `.claude/docs/infrastructure.md` |
| 開発コマンド（fdev等・Docker・デプロイ） | `.claude/docs/commands.md` |
| 開発経緯・PR履歴 | `.claude/docs/development-history.md` |
| リリース履歴 | `.claude/docs/release-log.md` |
| 秘密情報の所在 | `.claude/docs/secrets-map.md` |
| バグ・リファクタ候補（未着手） | `.claude/docs/refactor-candidates.md` |
| 詳細な構築・デプロイ手順（一次資料、機密込み・Git非管理） | `docs/`（deployment/, setup/ 等） |
| 公開用サニタイズ版ドキュメント | `docs_public/` |

## クイックリファレンス

- 実行: `fdev`（開発版）/ `fprod`（本番版・リリース時のみ）。エイリアスは `~/.zshrc` 定義
- バックエンドローカル: `cd backend && npm run dev`
- デプロイ: 手動運用（`.claude/docs/commands.md` → 完全版は `docs/deployment/cloud-run-deployment-guide.md`）
- Android は事実上未整備（iOS のみ配信）
- テストは front/back とも 0 件
- ストア申請時: 提出コミットに `vX.Y.Z` タグ必須 + `release-log.md` 更新（グローバルルール）
