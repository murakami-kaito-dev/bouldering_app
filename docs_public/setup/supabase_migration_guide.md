# Supabase移行ガイド（Cloud SQL互換性保持版）

## 📋 概要

このドキュメントは、ボルダリングアプリのデータベースをGoogle Cloud SQLからSupabaseに移行するための手順書です。
**重要**: Cloud SQLのコードは削除せず、環境変数で切り替え可能な構成を実装します。

### 移行の目的
- コスト削減（Cloud SQL: 月額約1万円 → Supabase: 月額0円〜$25）
- 開発環境の柔軟性向上
- 将来的なCloud SQL復帰の選択肢を残す

### アーキテクチャの変更点
```
【現在】
Flutter App → Cloud Run → Cloud SQL
                       → Firebase Auth
                       → Google Maps

【移行後】
Flutter App → Cloud Run → Supabase (PostgreSQL)  ← 変更点
                       → Firebase Auth            ← 変更なし
                       → Google Maps              ← 変更なし
```

---

## 🏗️ 実装設計

### ファイル構成（新規追加・変更）

```
backend/src/config/
├── database.ts              # 切り替えロジック（修正）
├── database-cloudsql.ts     # Cloud SQL接続（新規作成）
├── database-supabase.ts     # Supabase接続（新規作成）
└── environment.ts           # 環境変数定義（修正）

backend/
├── .env.dev                 # 開発環境設定（修正）
├── .env.prod               # 本番環境設定（修正）
└── .env.example            # テンプレート（修正）
```

### 切り替えの仕組み
環境変数 `DB_PROVIDER` で制御:
- `DB_PROVIDER=cloudsql` → Cloud SQL接続
- `DB_PROVIDER=supabase` → Supabase接続（デフォルト）

---

## 📝 実装手順

### Step 1: Supabaseプロジェクト作成
◯ 本番版
1. [Supabase](https://supabase.com) にサインアップ
2. アカウント作成
  -  アカウント情報はメモ帳に記載
3. 新規プロジェクト作成
   - Organization: `Murakami Company`
   - プロジェクト名: `[YOUR_GCP_PROJECT_ID_PROD]`
   - Compute Engine: MEDIUM 4GB RAM/2-core ARM CPU
   - データベースパスワード: [YOUR_SUPABASE_PASSWORD]
   - リージョン: `Northeast Asia (Tokyo)`
   → Create Project 押下(※ 50$ 追加費用としてかかることを言われる)
**⚠️ プラン変更履歴 ⚠️**
- **変更日**: 2026-01-07
- **変更内容**: Compute Engine を MEDIUM → FREE プランにダウングレード
- **理由**: ユーザー数が少ないため、コスト最適化
- **変更後**:
  - Compute Engine: FREE (制限あり)
  - 追加費用: $0/月
- **影響**: パフォーマンス低下の可能性があるが、現在の利用量では問題なし

4. 接続情報を取得（実際のプロジェクト: [YOUR_SUPABASE_PROD_PROJECT_ID]）
   **4-1. Supabase Dashboardでの操作**
   - プロジェクト作成完了後、自動的にプロジェクトダッシュボードに移動
   - 左メニューから「Settings」をクリック
   - 「Settings」メニュー内の「Database」をクリック

   **4-2. 3種類のConnection stringを確認**
   Supabaseでは用途に応じて3種類の接続方法が提供されます：

   **① Direct connection（データ移行・DDL操作用）**
   ```
   postgresql://postgres:[YOUR_SUPABASE_PASSWORD]@db.[YOUR_SUPABASE_PROD_PROJECT_ID].supabase.co:5432/postgres

   Host: db.[YOUR_SUPABASE_PROD_PROJECT_ID].supabase.co
   Port: 5432
   Database: postgres
   User: postgres
   Password: [YOUR_SUPABASE_PASSWORD]
   ```
   **用途**: データベースへの直接接続。データ移行、テーブル作成、長時間クエリに使用

   **② Transaction pooler（本番運用用、推奨） ← これを使用**
   ```
   postgresql://postgres:[YOUR_SUPABASE_PASSWORD]@db.[YOUR_SUPABASE_PROD_PROJECT_ID].supabase.co:6543/postgres

   Host: db.[YOUR_SUPABASE_PROD_PROJECT_ID].supabase.co
   Port: 6543
   Database: postgres
   User: postgres
   Password: [YOUR_SUPABASE_PASSWORD]
   Pool mode: transaction
   ```
   **用途**: 本番アプリケーションの接続。短いトランザクション向け、接続効率が最も良い

   **③ Session pooler（長時間接続用）**
   ```
   postgresql://postgres.[YOUR_SUPABASE_PROD_PROJECT_ID]:[YOUR_SUPABASE_PASSWORD]@aws-1-ap-northeast-1.pooler.supabase.com:5432/postgres

   Host: aws-1-ap-northeast-1.pooler.supabase.com
   Port: 5432
   Database: postgres
   User: postgres.[YOUR_SUPABASE_PROD_PROJECT_ID]  ← 注意: ユーザー名が異なる
   Password: [YOUR_SUPABASE_PASSWORD]
   Pool mode: session
   ```
   **用途**: プリペアドステートメントや長時間接続が必要な場合

   **4-3. 本番環境での使い分け**
   | 用途 | 使用する接続 | ポート |
   |------|------------|--------|
   | **通常のAPI運用** | Transaction pooler | 6543 |
   | **データ移行** | Direct connection | 5432 |
   | **テーブル作成/変更** | Direct connection | 5432 |
   | **長時間クエリ** | Session pooler | 5432 |

   **重要**: 本番アプリケーションでは**Transaction pooler（6543）を使用**してください

◯開発版
1. [Supabase](https://supabase.com) にサインアップ
2. アカウント作成
  -  アカウント情報はメモ帳に記載
3. 新規プロジェクト作成
   - Organization: `Murakami Company`
   - プロジェクト名: `[YOUR_GCP_PROJECT_ID_DEV]`
   - Compute Engine: - (※ 選択権なし)
   - データベースパスワード: [YOUR_SUPABASE_PASSWORD]
   - リージョン: `Northeast Asia (Tokyo)`
   → Create Project 押下
4. 接続情報を取得（実際のプロジェクト: [YOUR_SUPABASE_DEV_PROJECT_ID]）
   **4-1. Supabase Dashboardでの操作**
   - プロジェクト作成完了後、自動的にプロジェクトダッシュボードに移動
   - 左メニューから「Settings」をクリック
   - 「Settings」メニュー内の「Database」をクリック

   **4-2. 3種類のConnection stringを確認**
   Supabaseでは用途に応じて3種類の接続方法が提供されます：

   **① Direct connection（データ移行・DDL操作用）**
   ```
   postgresql://postgres:[YOUR_SUPABASE_PASSWORD]@db.[YOUR_SUPABASE_DEV_PROJECT_ID].supabase.co:5432/postgres

   Host: db.[YOUR_SUPABASE_DEV_PROJECT_ID].supabase.co
   Port: 5432
   Database: postgres
   User: postgres
   Password: [YOUR_SUPABASE_PASSWORD]
   ```
   **用途**: データベースへの直接接続。データ移行、テーブル作成、長時間クエリに使用

   **② Transaction pooler（開発運用用、推奨） ← これを使用**
   ```
   postgresql://postgres.[YOUR_SUPABASE_DEV_PROJECT_ID]:[YOUR_SUPABASE_PASSWORD]@aws-1-ap-northeast-1.pooler.supabase.com:6543/postgres

   Host: aws-1-ap-northeast-1.pooler.supabase.com
   Port: 6543
   Database: postgres
   User: postgres.[YOUR_SUPABASE_DEV_PROJECT_ID]
   Password: [YOUR_SUPABASE_PASSWORD]
   Pool mode: transaction
   ```
   **用途**: 開発アプリケーションの接続。短いトランザクション向け、接続効率が最も良い

   **③ Session pooler（長時間接続用）**
   ```
   postgresql://postgres.[YOUR_SUPABASE_DEV_PROJECT_ID]:[YOUR_SUPABASE_PASSWORD]@aws-1-ap-northeast-1.pooler.supabase.com:5432/postgres

   Host: aws-1-ap-northeast-1.pooler.supabase.com
   Port: 5432
   Database: postgres
   User: postgres.[YOUR_SUPABASE_DEV_PROJECT_ID]
   Password: [YOUR_SUPABASE_PASSWORD]
   Pool mode: session
   ```
   **用途**: プリペアドステートメントや長時間接続が必要な場合

   **4-3. 開発環境での使い分け**
   | 用途 | 使用する接続 | ポート |
   |------|------------|--------|
   | **通常のAPI運用** | Transaction pooler | 6543 |
   | **データ移行** | Direct connection | 5432 |
   | **テーブル作成/変更** | Direct connection | 5432 |
   | **長時間クエリ** | Session pooler | 5432 |

   **重要**: 開発アプリケーションでは**Transaction pooler（6543）を使用**してください


### Step 2: 新規ファイル作成

#### 2-1. `backend/src/config/database-cloudsql.ts` (新規)
```typescript
import { Pool, PoolConfig } from 'pg';
import { config } from './environment';
import logger from '../utils/logger';

/**
 * Cloud SQL PostgreSQL接続プール作成
 *
 * クリーンアーキテクチャにおける位置づけ:
 * - Infrastructure 層の具体実装
 * - Google Cloud SQL PostgreSQLとの接続を管理
 * - Unix Socket接続（本番）とTCP接続（開発）の両方に対応
 */
// Cloud SQL専用の接続設定（既存のdatabase.tsから移動）
export function createCloudSQLPool(): Pool {
  const poolConfig: PoolConfig = {
    user: config.database.user,
    password: config.database.password,
    database: config.database.database,
    port: config.database.port,
    max: 20, // Maximum number of clients in the pool
    idleTimeoutMillis: 30000, // 30 seconds
    connectionTimeoutMillis: 2000, // 2 seconds
  };

  // For Cloud SQL in production
  if (config.server.isProduction && config.database.instanceConnectionName) {
    poolConfig.host = `/cloudsql/${config.database.instanceConnectionName}`;
  } else {
    poolConfig.host = config.database.host;
  }

  logger.info('Cloud SQL connection pool created', {
    database: poolConfig.database,
    host: poolConfig.host,
  });

  return new Pool(poolConfig);
}
```

#### 2-2. `backend/src/config/database-supabase.ts` (新規)
```typescript
import { Pool, PoolConfig } from 'pg';
import { config } from './environment';
import logger from '../utils/logger';

/**
 * Supabase PostgreSQL接続プール作成
 *
 * クリーンアーキテクチャにおける位置づけ:
 * - Infrastructure 層の具体実装
 * - Supabase PostgreSQLとの接続を管理
 * - PgBouncer（Transaction pooler）経由での効率的な接続プールを提供
 *
 * PgBouncerについて:
 * - PostgreSQL用コネクションプーラー
 * - 多数のアプリ接続を少数のDB接続に集約
 * - メモリ効率と性能向上を実現
 * - Supabaseでは6543ポート（Transaction pooler）で提供
 */
// Supabase専用の接続設定
export function createSupabasePool(): Pool {
  const poolConfig: PoolConfig = {};

  // 接続文字列が提供されている場合（推奨）
  if (config.database.url) {
    poolConfig.connectionString = config.database.url;
  } else {
    // 個別パラメータで接続
    poolConfig.host = config.database.host;
    poolConfig.port = config.database.port;
    poolConfig.database = config.database.database;
    poolConfig.user = config.database.user;
    poolConfig.password = config.database.password;
  }

  // Supabase必須のSSL設定
  if (config.database.ssl) {
    poolConfig.ssl = {
      rejectUnauthorized: false, // Cloud Run環境での証明書検証回避
    };
  }

  // PgBouncer使用時は接続プールを小さめに設定
  // 理由: PgBouncerが既に接続プールを管理しているため
  poolConfig.max = config.database.maxConnections || 10;
  poolConfig.idleTimeoutMillis = 30000;
  poolConfig.connectionTimeoutMillis = 5000;

  logger.info('Supabase connection pool created', {
    database: poolConfig.database || 'from connection string',
    ssl: !!poolConfig.ssl,
  });

  return new Pool(poolConfig);
}
```

### Step 3: 既存ファイルの修正

#### 3-1. `backend/src/config/database.ts` (修正)
```typescript
import { Pool } from 'pg';
import { config } from './environment';
import logger from '../utils/logger';
import { createCloudSQLPool } from './database-cloudsql';
import { createSupabasePool } from './database-supabase';

// データベースプロバイダーに基づいて適切な接続プールを作成
let pool: Pool;

const provider = config.database.provider || 'supabase';

switch (provider) {
  case 'cloudsql':
    pool = createCloudSQLPool();
    break;
  case 'supabase':
    pool = createSupabasePool();
    break;
  default:
    throw new Error(`Unknown database provider: ${provider}`);
}

logger.info(`Database provider initialized: ${provider}`);

// 既存のDatabaseServiceクラスはそのまま維持
export class DatabaseService {
  async query<T = any>(text: string, params?: any[]): Promise<T[]> {
    const start = Date.now();
    try {
      const result = await pool.query(text, params);
      const duration = Date.now() - start;

      logger.debug('Database query executed', {
        query: text.substring(0, 100),
        duration: `${duration}ms`,
        rows: result.rowCount,
      });

      return result.rows;
    } catch (error) {
      logger.error('Database query error', {
        query: text.substring(0, 100),
        error: error instanceof Error ? error.message : 'Unknown error',
      });
      throw error;
    }
  }

  async getClient() {
    return pool.connect();
  }

  async transaction<T>(callback: (client: any) => Promise<T>): Promise<T> {
    const client = await this.getClient();
    try {
      await client.query('BEGIN');
      const result = await callback(client);
      await client.query('COMMIT');
      return result;
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  async checkConnection(): Promise<boolean> {
    try {
      await pool.query('SELECT 1');
      logger.info('Database connection successful');
      return true;
    } catch (error) {
      logger.error('Database connection failed', {
        error: error instanceof Error ? error.message : 'Unknown error',
      });
      return false;
    }
  }

  async close(): Promise<void> {
    await pool.end();
    logger.info('Database connections closed');
  }
}

export const db = new DatabaseService();
export { pool };
```

#### 3-2. `backend/src/config/environment.ts` (修正)
```typescript
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

// Environment configuration
export const config = {
  // Server
  server: {
    port: parseInt(process.env.PORT || '8080', 10),
    env: process.env.NODE_ENV || 'development',
    isProduction: process.env.NODE_ENV === 'production',
    isDevelopment: process.env.NODE_ENV === 'development',
  },

  // Database
  database: {
    // プロバイダー選択（cloudsql または supabase）
    provider: process.env.DB_PROVIDER || 'supabase',

    // 接続URL（Supabase推奨）
    url: process.env.DATABASE_URL,

    // 個別接続パラメータ
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT || '5432', 10),
    database: process.env.DB_NAME || 'bouldering_app',
    user: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD || '',

    // Cloud SQL専用
    instanceConnectionName: process.env.INSTANCE_CONNECTION_NAME,

    // Supabase専用
    ssl: process.env.DB_SSL === 'true',
    maxConnections: parseInt(process.env.DB_POOL_MAX || '10', 10),
  },

  // Firebase
  firebase: {
    projectId: process.env.FIREBASE_PROJECT_ID || '',
  },

  // CORS
  cors: {
    origins: process.env.ALLOWED_ORIGINS?.split(',') || ['http://localhost:3000'],
  },

  // Logging
  logging: {
    level: process.env.LOG_LEVEL || 'info',
  },
} as const;

// Validate required environment variables
export function validateEnvironment(): void {
  const required = [
    'FIREBASE_PROJECT_ID',
  ];

  if (config.server.isProduction) {
    const provider = config.database.provider;

    if (provider === 'cloudsql') {
      required.push('DB_PASSWORD', 'INSTANCE_CONNECTION_NAME');
    } else if (provider === 'supabase') {
      // DATABASE_URLがある場合は個別パラメータ不要
      if (!config.database.url) {
        required.push('DB_HOST', 'DB_PORT', 'DB_NAME', 'DB_USER', 'DB_PASSWORD');
      }
    }
  }

  const missing = required.filter((key) => !process.env[key]);
  if (missing.length > 0) {
    throw new Error(`Missing required environment variables: ${missing.join(', ')}`);
  }
}
```

### Step 4: 環境変数ファイルの更新

#### 4-1. `backend/.env.dev` (開発環境設定 - プロバイダー別完全分離)
```env
# =============================================
# Database Provider Selection
# =============================================
DB_PROVIDER=supabase

# =============================================
# Supabase Settings (Currently Active)
# =============================================
DATABASE_URL=postgresql://postgres.[YOUR_SUPABASE_DEV_PROJECT_ID]:[YOUR_SUPABASE_PASSWORD]@aws-1-ap-northeast-1.pooler.supabase.com:6543/postgres?sslmode=require
DB_SSL=true
DB_POOL_MAX=10

# =============================================
# Cloud SQL Settings (Backup)
# =============================================
# DB_HOST=/cloudsql/[YOUR_GCP_PROJECT_ID_DEV]:asia-northeast1:bouldering-db-dev
# DB_PORT=5432
# DB_NAME=[YOUR_DB_NAME_DEV]
# DB_USER=postgres
# DB_PASSWORD=[YOUR_DB_PASSWORD]
# INSTANCE_CONNECTION_NAME=[YOUR_GCP_PROJECT_ID_DEV]:asia-northeast1:bouldering-db-dev

# =============================================
# Provider Switching Instructions
# =============================================
# To switch to Cloud SQL:
#   1. Change DB_PROVIDER=cloudsql (line 5)
#   2. Comment out Supabase settings (lines 9-11)
#   3. Uncomment Cloud SQL settings (lines 16-20)
#
# To switch back to Supabase:
#   1. Change DB_PROVIDER=supabase (line 5)
#   2. Uncomment Supabase settings (lines 9-11)
#   3. Comment out Cloud SQL settings (lines 16-20)

# =============================================
# Common Settings (Both Providers)
# =============================================
PORT=8080
NODE_ENV=development
FIREBASE_PROJECT_ID=[YOUR_GCP_PROJECT_ID_DEV]
ALLOWED_ORIGINS=http://localhost:3000
LOG_LEVEL=debug
```

#### 4-2. `backend/.env.prod` (本番環境設定 - プロバイダー別完全分離)
```env
# =============================================
# Database Provider Selection
# =============================================
DB_PROVIDER=supabase

# =============================================
# Supabase Settings (Currently Active)
# =============================================
DATABASE_URL=postgresql://postgres:[YOUR_SUPABASE_PASSWORD]@db.[YOUR_SUPABASE_PROD_PROJECT_ID].supabase.co:6543/postgres?sslmode=require
DB_SSL=true
DB_POOL_MAX=10

# =============================================
# Cloud SQL Settings (Backup)
# =============================================
# DB_HOST=/cloudsql/[YOUR_GCP_PROJECT_ID_PROD]:asia-northeast1:[YOUR_GCP_PROJECT_ID_PROD]
# DB_PORT=5432
# DB_NAME=[YOUR_DB_NAME_PROD]
# DB_USER=postgres
# DB_PASSWORD=[YOUR_DB_PASSWORD]
# INSTANCE_CONNECTION_NAME=[YOUR_GCP_PROJECT_ID_PROD]:asia-northeast1:[YOUR_GCP_PROJECT_ID_PROD]

# =============================================
# Provider Switching Instructions
# =============================================
# To switch to Cloud SQL:
#   1. Change DB_PROVIDER=cloudsql (line 5)
#   2. Comment out Supabase settings (lines 9-11)
#   3. Uncomment Cloud SQL settings (lines 16-20)
#
# To switch back to Supabase:
#   1. Change DB_PROVIDER=supabase (line 5)
#   2. Uncomment Supabase settings (lines 9-11)
#   3. Comment out Cloud SQL settings (lines 16-20)

# =============================================
# Common Settings (Both Providers)
# =============================================
PORT=8080
NODE_ENV=production
FIREBASE_PROJECT_ID=[YOUR_GCP_PROJECT_ID_PROD]
ALLOWED_ORIGINS=https://your-app-domain.com
LOG_LEVEL=info
```

---

## 🔄 データ移行手順

### Step 1: Cloud SQLからデータをエクスポート

### Step 2: テーブル構造のインポート（データなし）

**重要**: Supabase SQL EditorはCOPY文のタブ区切りデータを正しく処理できないため、テーブル構造とデータは分けてインポートする必要があります。

#### 方法A: テーブル構造のみインポート（推奨）

1. **Cloud SQLからテーブル構造のみエクスポート**
   - Google Cloud Console → SQLインスタンス選択
   - エクスポート → 詳細オプション
   - 「スキーマのみ」を選択してエクスポート

2. **Supabase Dashboardでインポート**
   - Supabase Dashboard → SQL Editor
   - テーブル構造のSQLを貼り付けまたはファイルインポート
   - Runボタンで実行

#### 方法B: 既存SQLファイルからCOPYデータ部分を手動削除

1. **SQLファイルを編集**
   - `docs/250919_ver1.0.0デプロイ時SQL_最新_Cloud_SQL_Export_2025-09-19 (00_28_54).sql`をコピー
   - テキストエディタで開く
   - 以下のパターンを削除：
     - `COPY public.テーブル名 ... FROM stdin;` から
     - `\.` （バックスラッシュとドット）まで
   - つまり、CREATE TABLE文やCREATE FUNCTION文のみ残す

2. **編集したファイルをインポート**
   - Supabase Dashboard → SQL Editor
   - 編集したファイルをインポート
   - Runボタンで実行

### Step 3: データのインポート（必要に応じて）

1. **Cloud SQLからCSV形式でエクスポート**
   - Google Cloud Console → SQLインスタンス
   - エクスポート → CSV形式を選択
   - 各テーブルごとにエクスポート

2. **Supabase Table Editorでインポート**
   - Supabase Dashboard → Table Editor
   - 各テーブルを選択
   - 「Import data」ボタン
   - CSVファイルをアップロード

---

## 🚀 デプロイ手順

### Step 1: Dockerイメージのビルド

```bash
cd backend
docker build --platform linux/amd64 -t asia-northeast1-docker.pkg.dev/[YOUR_GCP_PROJECT_ID_PROD]/bouldering-app-docker-prod/backend:supabase-v1.0.0 .
docker push asia-northeast1-docker.pkg.dev/[YOUR_GCP_PROJECT_ID_PROD]/bouldering-app-docker-prod/backend:supabase-v1.0.0
```

### Step 2: Cloud Runへのデプロイ（Supabase版）

```bash
gcloud run deploy [YOUR_SERVICE_NAME_PROD] \
  --image asia-northeast1-docker.pkg.dev/[YOUR_GCP_PROJECT_ID_PROD]/bouldering-app-docker-prod/backend:supabase-v1.0.0 \
  --platform managed \
  --region asia-northeast1 \
  --allow-unauthenticated \
  --service-account cloud-run-backend-prod@[YOUR_GCP_PROJECT_ID_PROD].iam.gserviceaccount.com \
  --set-env-vars NODE_ENV=production \
  --set-env-vars DB_PROVIDER=supabase \
  --set-env-vars DATABASE_URL="postgresql://postgres:[YOUR_SUPABASE_PASSWORD]@db.[YOUR_SUPABASE_PROD_PROJECT_ID].supabase.co:6543/postgres?sslmode=require" \
  --set-env-vars DB_SSL=true \
  --set-env-vars DB_POOL_MAX=10 \
  --set-env-vars FIREBASE_PROJECT_ID=[YOUR_GCP_PROJECT_ID_PROD] \
  --set-env-vars GCS_BUCKET_NAME=boulderingapp_tweets_media \
  --set-secrets "FIREBASE_ADMIN_KEY=firebase-admin-key-prod:latest" \
  --memory 512Mi \
  --timeout=900

# 注意: --add-cloudsql-instances オプションは削除
```

---

## 🔄 Cloud SQLとSupabaseの切り替え

### Supabase → Cloud SQLに戻す

1. **環境変数を変更**
```bash
gcloud run services update [YOUR_SERVICE_NAME_PROD] \
  --update-env-vars DB_PROVIDER=cloudsql \
  --remove-env-vars DATABASE_URL,DB_SSL,DB_POOL_MAX \
  --update-env-vars DB_NAME=[YOUR_DB_NAME_PROD] \
  --update-env-vars DB_USER=postgres \
  --update-env-vars DB_PASSWORD=[YOUR_DB_PASSWORD] \
  --update-env-vars INSTANCE_CONNECTION_NAME=[YOUR_GCP_PROJECT_ID_PROD]:asia-northeast1:[YOUR_GCP_PROJECT_ID_PROD] \
  --add-cloudsql-instances [YOUR_GCP_PROJECT_ID_PROD]:asia-northeast1:[YOUR_GCP_PROJECT_ID_PROD]
```

2. **動作確認**
```bash
curl https://[YOUR_SERVICE_NAME_PROD]-xxxxx.a.run.app/health
```

### Cloud SQL → Supabaseに切り替え

上記の逆の操作を実行

---

## 🧪 動作確認

### ローカルでのテスト

```bash
cd backend

# Supabase接続でテスト
cp .env.dev .env
npm run dev

# ヘルスチェック
curl http://localhost:8080/health

# API動作確認
curl http://localhost:8080/api/gyms?prefecture=東京都
```

### 本番環境での確認

```bash
# ヘルスチェック
curl https://[YOUR_SERVICE_NAME_PROD]-xxxxx.a.run.app/health

# ログ確認
gcloud run services logs read [YOUR_SERVICE_NAME_PROD] --limit=50
```

---

## 🔧 トラブルシューティング

### 接続エラーが発生する場合

1. **SSL証明書エラー**
```typescript
// database-supabase.ts で rejectUnauthorized: false を確認
poolConfig.ssl = {
  rejectUnauthorized: false
};
```

2. **接続プールエラー**
```bash
# PgBouncer使用時は接続数を制限
DB_POOL_MAX=5  # 10から5に減らす
```

3. **タイムアウトエラー**
```typescript
// 接続タイムアウトを延長
connectionTimeoutMillis: 10000  // 5秒から10秒に
```

### データベースマイグレーション

#### 📦 既存データのインポート（Cloud SQLバックアップから）

**重要**: 既存のCloud SQLバックアップファイルを使用してテーブル構造とデータを一括インポートできます。

```bash
# 本番環境への復元
psql "postgresql://postgres:[YOUR_SUPABASE_PASSWORD]@db.[YOUR_SUPABASE_PROD_PROJECT_ID].supabase.co:5432/postgres" \
  -f "docs/250919_ver1.0.0デプロイ時SQL_最新_Cloud_SQL_Export_2025-09-19 (00_28_54).sql"

# 開発環境への復元
psql "postgresql://postgres:[YOUR_SUPABASE_PASSWORD]@db.[YOUR_SUPABASE_DEV_PROJECT_ID].supabase.co:5432/postgres" \
  -f "docs/250919_ver1.0.0デプロイ時SQL_最新_Cloud_SQL_Export_2025-09-19 (00_28_54).sql"
```

**このコマンドで以下が一括実行されます:**
✅ 全テーブル構造の作成（users, gyms, tweets, gym_favorites, etc）
✅ カスタム関数の作成（update_timestamp, update_updated_at）
✅ 制約・インデックスの作成
✅ 全実データのインポート

**実行時間**: 約1-2分
**対象テーブル**: 7テーブル（gym_favorites, gym_hours, gyms, tweet_media, tweets, user_favorites, users）

#### ⚠️ 注意事項

1. **実行前の確認**
   - Supabase Dashboard → Table Editorで現在のテーブル一覧を確認
   - 既存データのバックアップを取得（必要に応じて）

2. **既存テーブルがある場合**
   - Supabase Dashboard → SQL Editorで既存テーブルを削除
   - またはTable Editorで個別にテーブルを削除
   - その後、新しいテーブル構造をインポート

3. **インポート結果の確認**
   - Supabase Dashboard → Table Editorで各テーブルを確認
   - データ件数やカラムの確認

### パフォーマンス問題

1. **スロークエリの確認**
   - Supabase Dashboard → Database → Query Performance

2. **インデックスの追加**
```sql
CREATE INDEX idx_tweets_user_id ON tweets(user_id);
CREATE INDEX idx_gyms_prefecture ON gyms(prefecture);
```

---

## 💰 コスト比較

| 項目 | Cloud SQL | Supabase |
|------|-----------|----------|
| 基本料金 | 約10,000円/月 | 0円〜2,500円/月 |
| CPU/メモリ | 2vCPU/8GB | 共有〜専用 |
| ストレージ | 100GB SSD | 8GB〜無制限 |
| バックアップ | 自動（追加料金） | 自動（プラン込） |
| 接続数制限 | なし | プラン依存 |

### 推奨プラン
- **開発環境**: Supabase Free Plan（0円）
- **本番環境**: Supabase Pro Plan（$25/月 = 約3,750円）

---

## 📚 参考リンク

- [Supabase Documentation](https://supabase.com/docs)
- [Supabase Database](https://supabase.com/docs/guides/database)
- [PgBouncer Connection Pooling](https://supabase.com/docs/guides/database/connecting-to-postgres#connection-pool)
- [Cloud Run Environment Variables](https://cloud.google.com/run/docs/configuring/environment-variables)

---

## ✅ チェックリスト

### 移行前
- [ ] Cloud SQLデータのバックアップ完了
- [ ] Supabaseプロジェクト作成完了
- [ ] 環境変数の準備完了

### 実装
- [ ] database-cloudsql.ts 作成
- [ ] database-supabase.ts 作成
- [ ] database.ts 修正
- [ ] environment.ts 修正
- [ ] .env ファイル更新

### 移行
- [ ] データエクスポート完了
- [ ] データインポート完了
- [ ] 動作確認完了

### デプロイ
- [ ] Dockerイメージビルド完了
- [ ] Cloud Runデプロイ完了
- [ ] 本番環境動作確認完了

### 事後作業
- [ ] Cloud SQL停止（コスト削減）
- [ ] モニタリング設定
- [ ] ドキュメント更新

---

*最終更新: 2025年1月*
