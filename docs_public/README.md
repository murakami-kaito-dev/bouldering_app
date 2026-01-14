# ボルダリングアプリ ドキュメント

> **📢 公開資料について**
> このドキュメント集は、個人でインフラ構築する際の資料です。`[YOUR_*]`形式のプレースホルダーは、ご自身の環境に合わせて設定してください。

## 📋 概要

ボルダリング愛好者のためのソーシャルプラットフォームアプリケーション（Flutter + Node.js）の開発・デプロイに関する包括的ドキュメント集です。

---

## 📁 ディレクトリ構成

### backend_implementation/
バックエンド（Node.js/TypeScript）の実装ガイド、アーキテクチャ設計、API仕様など。

**主なファイル:**
- `backend_overview.md` - バックエンド包括ガイド

### frontend_implementation/
フロントエンド（Flutter/Dart）の実装ガイド、機能別詳細ドキュメント、トラブルシューティングなど。

**主なファイル:**
- `frontend_overview.md` - フロントエンド包括ガイド
- `features/` - 機能別実装詳細
- `troubleshooting/` - 問題解決ガイド
- `summaries/` - 実装完了報告

### setup/
Google Cloud、Supabase、Google Maps API等の初期設定・環境構築手順。

**主なファイル:**
- `google_cloud_setup_private.txt` - Google Cloudプロジェクト初期設定
- `supabase_migration_guide.md` - Supabaseセットアップ・移行手順
- `google_maps_api_setup_guide.md` - Google Maps API設定
- `ios_flutter_flavor_setup.md` - iOS開発/本番環境分離設定

### deployment/
アプリのビルド、App Store申請、Cloud Runデプロイ手順。

**主なファイル:**
- `app_store_submission.md` - App Store配信申請手順
- `ios_device_build.md` - iPhone実機ビルド手順
- `cloud-run-deployment-guide.md` - バックエンドデプロイ手順

### git_rules/
Gitを使ったバージョン管理のルール（ブランチ戦略、コミットメッセージ規約など）。

**主なファイル:**
- `git-workflow.md` - 詳細なGitワークフロー
- `git運用ルール.txt` - 基本的なGit運用ルール

### アーキテクチャ.drawio
アプリケーション全体のアーキテクチャ図（Draw.ioで開けます）。

---

## 🚀 クイックスタート

### 初めて環境構築する場合
1. **setup/** - 外部サービスの初期設定
2. **backend_implementation/** または **frontend_implementation/** - 実装ガイドを参照
3. **deployment/** - ビルド・デプロイ手順

### Git運用ルールの確認
**git_rules/** フォルダのドキュメントを参照してください。

---

*最終更新: 2026年1月14日*
