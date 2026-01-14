# Cloud Run デプロイ手順書

## 📋 概要

このドキュメントは、ボルダリングアプリのバックエンドをGoogle Cloud Runにデプロイするための包括的な手順書です。
4つのデプロイパターン（開発/本番 × Cloud SQL/Supabase）すべてに対応しています。

---

## 🏗️ デプロイパターン

| 環境 | データベース | 用途 |
|------|-------------|------|
| **開発環境** | Cloud SQL | 開発・テスト用（従来型） |
| **開発環境** | Supabase | 開発・テスト用（新型） |
| **本番環境** | Cloud SQL | 本番運用（従来型） |
| **本番環境** | Supabase | 本番運用（新型） |

---

## 📝 事前準備（全パターン共通）

### 1. プロジェクト設定
```bash
# 開発環境の場合
gcloud config set project [YOUR_GCP_PROJECT_ID_DEV]

# 本番環境の場合
gcloud config set project [YOUR_GCP_PROJECT_ID_PROD]

# 設定確認
gcloud config list
```

### 2. Docker認証設定
```bash
gcloud auth configure-docker asia-northeast1-docker.pkg.dev
```

---

## 🔧 パターン1: 開発環境 + Cloud SQL

### Step 1: Dockerイメージビルド
```bash
cd backend
docker build --platform linux/amd64 -t asia-northeast1-docker.pkg.dev/[YOUR_GCP_PROJECT_ID_DEV]/[YOUR_DOCKER_REPO_DEV]/backend:latest .
```

### Step 2: イメージプッシュ
```bash
docker push asia-northeast1-docker.pkg.dev/[YOUR_GCP_PROJECT_ID_DEV]/[YOUR_DOCKER_REPO_DEV]/backend:latest
```

### Step 3: Cloud Runデプロイ
```bash
gcloud run deploy [YOUR_SERVICE_NAME_DEV] \
  --image asia-northeast1-docker.pkg.dev/[YOUR_GCP_PROJECT_ID_DEV]/[YOUR_DOCKER_REPO_DEV]/backend:latest \
  --platform managed \
  --region asia-northeast1 \
  --allow-unauthenticated \
  --service-account [YOUR_SERVICE_ACCOUNT_DEV]@[YOUR_GCP_PROJECT_ID_DEV].iam.gserviceaccount.com \
  --set-env-vars NODE_ENV=development \
  --set-env-vars DB_PROVIDER=cloudsql \
  --set-env-vars DB_NAME=[YOUR_DB_NAME_DEV] \
  --set-env-vars DB_USER=postgres \
  --set-env-vars DB_HOST=/cloudsql/[YOUR_GCP_PROJECT_ID_DEV]:asia-northeast1:[YOUR_GCP_PROJECT_ID_DEV] \
  --set-env-vars INSTANCE_CONNECTION_NAME=[YOUR_GCP_PROJECT_ID_DEV]:asia-northeast1:[YOUR_GCP_PROJECT_ID_DEV] \
  --set-env-vars FIREBASE_PROJECT_ID=[YOUR_GCP_PROJECT_ID_DEV] \
  --set-env-vars GCS_BUCKET_NAME=[YOUR_GCS_BUCKET_DEV] \
  --set-env-vars GCP_PROJECT=[YOUR_GCP_PROJECT_ID_DEV] \
  --set-env-vars TASKS_LOCATION=asia-northeast1 \
  --set-env-vars TASKS_QUEUE_ID=[YOUR_TASKS_QUEUE_DEV] \
  --set-env-vars TASKS_HANDLER_URL=[YOUR_DEV_CLOUD_RUN_URL]/internal/tasks/gcs-delete-prefix \
  --set-env-vars TASKS_SA_EMAIL=[YOUR_TASKS_SA_DEV]@[YOUR_GCP_PROJECT_ID_DEV].iam.gserviceaccount.com \
  --set-secrets "DB_PASSWORD=db-password-dev:latest" \
  --set-secrets "FIREBASE_ADMIN_KEY=firebase-admin-key-dev:latest" \
  --add-cloudsql-instances [YOUR_GCP_PROJECT_ID_DEV]:asia-northeast1:[YOUR_GCP_PROJECT_ID_DEV] \
  --memory 512Mi \
  --timeout=900
```

---

## 🆕 パターン2: 開発環境 + Supabase

### Step 1: Dockerイメージビルド
```bash
cd backend
docker build --platform linux/amd64 -t asia-northeast1-docker.pkg.dev/[YOUR_GCP_PROJECT_ID_DEV]/[YOUR_DOCKER_REPO_DEV]/backend:supabase-latest .
```

### Step 2: イメージプッシュ
```bash
docker push asia-northeast1-docker.pkg.dev/[YOUR_GCP_PROJECT_ID_DEV]/[YOUR_DOCKER_REPO_DEV]/backend:supabase-latest
```

### Step 3: Cloud Runデプロイ
```bash
gcloud run deploy [YOUR_SERVICE_NAME_DEV] \
  --image asia-northeast1-docker.pkg.dev/[YOUR_GCP_PROJECT_ID_DEV]/[YOUR_DOCKER_REPO_DEV]/backend:supabase-latest \
  --platform managed \
  --region asia-northeast1 \
  --allow-unauthenticated \
  --service-account [YOUR_SERVICE_ACCOUNT_DEV]@[YOUR_GCP_PROJECT_ID_DEV].iam.gserviceaccount.com \
  --set-env-vars NODE_ENV=development \
  --set-env-vars DB_PROVIDER=supabase \
  --set-env-vars DATABASE_URL="[YOUR_SUPABASE_DEV_CONNECTION_URL]" \
  --set-env-vars DB_SSL=true \
  --set-env-vars DB_POOL_MAX=10 \
  --set-env-vars FIREBASE_PROJECT_ID=[YOUR_GCP_PROJECT_ID_DEV] \
  --set-env-vars GCS_BUCKET_NAME=[YOUR_GCS_BUCKET_DEV] \
  --set-env-vars GCP_PROJECT=[YOUR_GCP_PROJECT_ID_DEV] \
  --set-env-vars TASKS_LOCATION=asia-northeast1 \
  --set-env-vars TASKS_QUEUE_ID=[YOUR_TASKS_QUEUE_DEV] \
  --set-env-vars TASKS_HANDLER_URL=[YOUR_DEV_CLOUD_RUN_URL]/internal/tasks/gcs-delete-prefix \
  --set-env-vars TASKS_SA_EMAIL=[YOUR_TASKS_SA_DEV]@[YOUR_GCP_PROJECT_ID_DEV].iam.gserviceaccount.com \
  --set-secrets "FIREBASE_ADMIN_KEY=firebase-admin-key-dev:latest" \
  --memory 512Mi \
  --timeout=900
```

**重要な変更点**:
- ✅ `DB_PROVIDER=supabase`
- ✅ `DATABASE_URL`でSupabase接続
- ✅ `--add-cloudsql-instances`を削除
- ✅ `DB_PASSWORD`シークレット不要

---

## 🔧 パターン3: 本番環境 + Cloud SQL

### Step 1: Dockerイメージビルド
```bash
cd backend
docker build --platform linux/amd64 -t asia-northeast1-docker.pkg.dev/[YOUR_GCP_PROJECT_ID_PROD]/[YOUR_DOCKER_REPO_PROD]/backend:v1.0.0 .
```

### Step 2: イメージプッシュ
```bash
docker push asia-northeast1-docker.pkg.dev/[YOUR_GCP_PROJECT_ID_PROD]/[YOUR_DOCKER_REPO_PROD]/backend:v1.0.0
```

### Step 3: Cloud Runデプロイ
```bash
gcloud run deploy [YOUR_SERVICE_NAME_PROD] \
  --image asia-northeast1-docker.pkg.dev/[YOUR_GCP_PROJECT_ID_PROD]/[YOUR_DOCKER_REPO_PROD]/backend:v1.0.0 \
  --platform managed \
  --region asia-northeast1 \
  --allow-unauthenticated \
  --service-account [YOUR_SERVICE_ACCOUNT_PROD]@[YOUR_GCP_PROJECT_ID_PROD].iam.gserviceaccount.com \
  --set-env-vars NODE_ENV=production \
  --set-env-vars DB_PROVIDER=cloudsql \
  --set-env-vars DB_NAME=[YOUR_DB_NAME_PROD] \
  --set-env-vars DB_USER=postgres \
  --set-env-vars DB_HOST=/cloudsql/[YOUR_GCP_PROJECT_ID_PROD]:asia-northeast1:[YOUR_DB_INSTANCE_PROD] \
  --set-env-vars INSTANCE_CONNECTION_NAME=[YOUR_GCP_PROJECT_ID_PROD]:asia-northeast1:[YOUR_DB_INSTANCE_PROD] \
  --set-env-vars FIREBASE_PROJECT_ID=[YOUR_GCP_PROJECT_ID_PROD] \
  --set-env-vars GCS_BUCKET_NAME=[YOUR_GCS_BUCKET_PROD] \
  --set-env-vars GCP_PROJECT=[YOUR_GCP_PROJECT_ID_PROD] \
  --set-env-vars TASKS_LOCATION=asia-northeast1 \
  --set-env-vars TASKS_QUEUE_ID=[YOUR_TASKS_QUEUE_PROD] \
  --set-env-vars TASKS_HANDLER_URL=[YOUR_PROD_CLOUD_RUN_URL]/internal/tasks/gcs-delete-prefix \
  --set-env-vars TASKS_SA_EMAIL=[YOUR_TASKS_SA_PROD]@[YOUR_GCP_PROJECT_ID_PROD].iam.gserviceaccount.com \
  --set-secrets "DB_PASSWORD=db-password-prod:latest" \
  --set-secrets "FIREBASE_ADMIN_KEY=firebase-admin-key-prod:latest" \
  --add-cloudsql-instances [YOUR_GCP_PROJECT_ID_PROD]:asia-northeast1:[YOUR_DB_INSTANCE_PROD] \
  --memory 1Gi \
  --timeout=900
```

---

## 🆕 パターン4: 本番環境 + Supabase

### Step 1: Dockerイメージビルド (※ versionを更新すること)
```bash
cd backend
docker build --platform linux/amd64 -t asia-northeast1-docker.pkg.dev/[YOUR_GCP_PROJECT_ID_PROD]/[YOUR_DOCKER_REPO_PROD]/backend:supabase-v1.0.0 .
```

### Step 2: イメージプッシュ　(※ versionを更新すること)
```bash
docker push asia-northeast1-docker.pkg.dev/[YOUR_GCP_PROJECT_ID_PROD]/[YOUR_DOCKER_REPO_PROD]/backend:supabase-v1.0.0
```

### Step 3: Cloud Runデプロイ (※ versionを更新すること)
```bash
gcloud run deploy [YOUR_SERVICE_NAME_PROD] \
  --image asia-northeast1-docker.pkg.dev/[YOUR_GCP_PROJECT_ID_PROD]/[YOUR_DOCKER_REPO_PROD]/backend:supabase-v1.0.0 \
  --platform managed \
  --region asia-northeast1 \
  --allow-unauthenticated \
  --service-account [YOUR_SERVICE_ACCOUNT_PROD]@[YOUR_GCP_PROJECT_ID_PROD].iam.gserviceaccount.com \
  --set-env-vars NODE_ENV=production \
  --set-env-vars DB_PROVIDER=supabase \
  --set-env-vars DATABASE_URL="[YOUR_SUPABASE_PROD_CONNECTION_URL]" \
  --set-env-vars DB_SSL=true \
  --set-env-vars DB_POOL_MAX=10 \
  --set-env-vars FIREBASE_PROJECT_ID=[YOUR_GCP_PROJECT_ID_PROD] \
  --set-env-vars GCS_BUCKET_NAME=[YOUR_GCS_BUCKET_PROD] \
  --set-env-vars GCP_PROJECT=[YOUR_GCP_PROJECT_ID_PROD] \
  --set-env-vars TASKS_LOCATION=asia-northeast1 \
  --set-env-vars TASKS_QUEUE_ID=[YOUR_TASKS_QUEUE_PROD] \
  --set-env-vars TASKS_HANDLER_URL=[YOUR_PROD_CLOUD_RUN_URL]/internal/tasks/gcs-delete-prefix \
  --set-env-vars TASKS_SA_EMAIL=[YOUR_TASKS_SA_PROD]@[YOUR_GCP_PROJECT_ID_PROD].iam.gserviceaccount.com \
  --set-secrets "FIREBASE_ADMIN_KEY=firebase-admin-key-prod:latest" \
  --memory 1Gi \
  --timeout=900
```

**重要な変更点**:
- ✅ `DB_PROVIDER=supabase`
- ✅ `DATABASE_URL`で本番Supabase接続
- ✅ `--add-cloudsql-instances`を削除
- ✅ `DB_PASSWORD`シークレット不要

---

## 🚫 App Store リジェクト時のタグ管理

### 本番環境での注意点

本番環境では、同一タグの重複をデプロイできない設定となっています。App Store Connectでアプリがリジェクトされた場合、以下の手順でタグを編集してください。

### タグ編集手順

1. **Google Cloud Console** → **Artifact Registry** にアクセス
2. 該当するリポジトリを選択
3. リジェクトされたイメージのタグを編集

### タグ命名規則

リジェクト時は、元のタグに `-rejectX` を追加します：

| 状況 | 元のタグ | 新しいタグ |
|------|----------|------------|
| 初回リジェクト | `supabase-v1.0.0` | `supabase-v1.0.0-reject1` |
| 2回目リジェクト | `supabase-v1.0.0` | `supabase-v1.0.0-reject2` |
| 3回目リジェクト | `supabase-v1.0.0` | `supabase-v1.0.0-reject3` |

### 例：Supabase本番環境でのリジェクト対応

```bash
# 1回目のリジェクト後
docker build --platform linux/amd64 -t asia-northeast1-docker.pkg.dev/[YOUR_GCP_PROJECT_ID_PROD]/[YOUR_DOCKER_REPO_PROD]/backend:supabase-v1.0.0-reject1 .
docker push asia-northeast1-docker.pkg.dev/[YOUR_GCP_PROJECT_ID_PROD]/[YOUR_DOCKER_REPO_PROD]/backend:supabase-v1.0.0-reject1

# デプロイ時もタグを更新
gcloud run deploy [YOUR_SERVICE_NAME_PROD] \
  --image asia-northeast1-docker.pkg.dev/[YOUR_GCP_PROJECT_ID_PROD]/[YOUR_DOCKER_REPO_PROD]/backend:supabase-v1.0.0-reject1 \
  # ... その他のオプション
```

**注意**: App Storeで承認されたら、次回リリース時は通常のバージョンタグ（例：`supabase-v1.0.1`）に戻してください。

---

## 📊 パターン比較表

| 項目 | Cloud SQL | Supabase |
|------|-----------|----------|
| **DB_PROVIDER** | `cloudsql` | `supabase` |
| **DB接続方式** | 個別設定 | `DATABASE_URL` |
| **Cloud SQL接続** | `--add-cloudsql-instances` | 不要 |
| **パスワード管理** | Secret Manager | 接続URLに含む |
| **SSL設定** | 不要 | `DB_SSL=true` |

---

## 🔄 デプロイ後の確認

### ヘルスチェック
```bash
# 開発環境
curl [YOUR_DEV_CLOUD_RUN_URL]/health

# 本番環境
curl [YOUR_PROD_CLOUD_RUN_URL]/health
```

### ログ確認
```bash
# 開発環境
gcloud run services logs read [YOUR_SERVICE_NAME_DEV] --limit=50

# 本番環境
gcloud run services logs read [YOUR_SERVICE_NAME_PROD] --limit=50
```

---

## 📚 関連ドキュメント

- [Supabase移行ガイド](../setup/supabase_migration_guide.md)
- [Google Cloud セットアップ](../setup/google_cloud_setup_private.txt)
- [Git運用ルール](../development/git-workflow.md)

---

*最終更新: 2025年1月*
