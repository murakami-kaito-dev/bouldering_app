# Git運用ルール

## 📋 概要

このドキュメントは、ボルダリングアプリ開発におけるGit運用ルールを定義します。

---

## 🌿 ブランチ戦略

### ブランチ構成

#### `main`ブランチ
- **用途**: リリース済みの本番コード
- **ルール**: 直接開発・pushは禁止
- **更新方法**: Pull Requestからのマージのみ

#### Topicブランチ
機能開発、バグ修正、ドキュメント更新用の作業ブランチ

| ブランチタイプ | 用途 | 命名例 |
|---------------|------|--------|
| `feature/` | 新機能開発 | `feature/gym-search-filter`<br>`feature/chat-function` |
| `hotfix/` | 緊急バグ修正 | `hotfix/prod-env-variable`<br>`hotfix/login-error` |
| `docs/` | ドキュメント更新 | `docs/update-readme-ja`<br>`docs/api-documentation` |
| `refactor/` | リファクタリング | `refactor/database-layer`<br>`refactor/auth-service` |

### ブランチ運用フロー

```
main ← PR ← feature/new-function
     ← PR ← hotfix/critical-bug
     ← PR ← docs/setup-guide
```

---

## 📝 コミットルール

### ⚠️ 重要な原則

**「ブランチ名」と「コミット種別」は別物**
- `feature`ブランチでも`fix:`や`docs:`コミットをする場合がある
- 各コミットの**実際の中身**に合わせてタイプを選ぶ

### コミットメッセージ形式

```
type(scope): 要約（50文字以内）

本文：何を/なぜ/影響範囲...など
（必要に応じて）

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

### コミットタイプ一覧

| タイプ | 用途 | 例 |
|--------|------|-----|
| `feat`/`feature` | 新機能追加 | `feat(auth): Google OAuth2認証を追加` |
| `fix` | バグ修正 | `fix(chat): 既読数がずれる不具合を修正` |
| `refactor` | 仕様不変の整理 | `refactor(chat): ソケット接続ロジックをフックに分離` |
| `perf` | 性能改善 | `perf(db): クエリキャッシュを追加して応答速度向上` |
| `docs` | ドキュメント | `docs: セットアップ手順書をREADMEに追加` |
| `chore` | 付帯作業 | `chore: firebase-adminを11.11.1に更新` |
| `test` | テスト追加・修正 | `test(api): ユーザー登録APIのテストケース追加` |
| `build`/`ci` | ビルド・CI変更 | `ci: GitHub Actionsワークフロー追加` |
| `revert` | 取り消し | `revert: "feat(chat): DM送受信API"を取り消し` |

### 実際のコミット例

`feature/chat-function`ブランチでの開発例：

```bash
# 新機能追加
feat(chat): DM送受信APIを追加

# バグ修正
fix(chat): 既読数がずれる不具合を修正

# リファクタリング
refactor(chat): ソケット接続ロジックをカスタムフックに分離

# 依存関係更新
chore: firebase-adminを11.11.1に更新

# ドキュメント追加
docs: チャット機能のAPI仕様書を追加
```

---

## 🔄 Pull Request（PR）

### PRタイトル

- ❌ **ブランチ名のコピー**: `feature/gym-search-filter`
- ✅ **実際の変更内容**: `ジム検索にフィルター機能を追加`

### PRの構成

```markdown
## 概要
このPRで何を実装/修正したかの要約

## 変更内容
- 機能A を追加
- バグB を修正
- ファイルC をリファクタリング

## テスト
- [ ] 手動テスト完了
- [ ] 自動テスト追加
- [ ] 既存テストが通ることを確認

## レビューポイント
特に注意して見てほしい箇所があれば記載
```

---

## 🔀 マージコミットルール

### GitHub PR マージ時の設定

#### Commit Message（マージコミットタイトル）
**ルール**: PRタイトルと同じ形式で記載
```
type(scope): 要約
```

**例**:
- ❌ デフォルト: `Merge pull request #123 from feature/supabase-db-switch`
- ✅ 推奨: `feat(db): Cloud SQL から Supabase への切り替え`

#### Extended Description（マージコミット本文）
**ルール**: PR本文の「変更内容」を簡潔に記載

**例**:
```
- Supabase向けDB設定を追加
- Supabase / Cloud SQLの切り替え機能を実装
- アプリリリースに必要な付帯作業を実施
```

### マージ戦略

| 項目 | ルール |
|------|--------|
| **Commit Message** | コミットルールに従って記載（`type(scope): 要約`） |
| **Extended Description** | 主要な変更点を箇条書きで記載 |
| **マージ方法** | Squash and merge推奨（複数のコミットを1つに統合） |

### 実際のマージ手順

1. **PR承認後、「Merge pull request」をクリック**
2. **Commit Message を編集**:
   - PRタイトルをコピー
   - `type(scope): 要約` 形式に整形
3. **Extended Description を編集**:
   - PR本文の変更内容を箇条書きでコピー
4. **「Confirm merge」をクリック**

---

## 🔒 セキュリティ・注意事項

### 🚨 コミット禁止事項

- **機密情報の漏洩**:
  - パスワード、APIキー、秘密鍵
  - 個人情報、テストデータ
  
- **大容量ファイル**:
  - バイナリファイル（画像、動画）
  - ログファイル、一時ファイル

### 環境別コミット

- **開発環境**: 実験的コミットOK（後でsquash推奨）
- **本番環境**: 安定したコミットのみ

---

## 📚 参考リンク

- [Conventional Commits](https://www.conventionalcommits.org/ja/)
- [Git Flow](https://nvie.com/posts/a-successful-git-branching-model/)
- [GitHub Flow](https://guides.github.com/introduction/flow/)

---

*最終更新: 2025年1月*