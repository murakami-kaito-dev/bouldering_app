# ボルダリングアプリ バックエンド

## 概要

本アプリケーションのバックエンドは、**Clean Architecture**、**MVVM パターン**、**RESTful 設計**の原則に完全準拠したNode.js/TypeScript実装です。Google Cloud Platform上でのマイクロサービスアーキテクチャにより、高可用性とスケーラビリティを実現しています。

### 技術スタック

| 技術 | バージョン | 用途 |
|------|----------|------|
| **Nodes.js** | 18.0.0+ | ランタイム環境 |
| **TypeScript** | 5.3.3+ | プログラミング言語 |
| **Express.js** | 4.18.2+ | Webフレームワーク |
| **PostgreSQL** | 15 | データベース |
| **Firebase Admin** | 11.11.1+ | 認証システム |
| **Google Cloud SDK** | - | インフラストラクチャ |

### インフラストラクチャ

| サービス | 用途 | 環境 |
|---------|------|------|
| **Cloud Run** | APIサーバーホスティング | dev/prod |
| **Cloud SQL (PostgreSQL)** | データベース | dev/prod |
| **Cloud Storage** | 画像・動画ストレージ | dev/prod |
| **Cloud Tasks** | 非同期タスク処理 | dev/prod |
| **Artifact Registry** | Dockerイメージ管理 | dev/prod |
| **Secret Manager** | 機密情報管理 | dev/prod |

---

## 🏗 アーキテクチャ

本バックエンドは**Clean Architecture**を完全に実装しており、詳細なアーキテクチャ情報は[ARCHITECTURE.md](./ARCHITECTURE.md)を参照してください。

### 層構造概要

```
Presentation Layer (routes/)     ← HTTP リクエスト/レスポンス
        ↓
Application Layer (services/)    ← ビジネスロジック
        ↓
Domain Layer (domain/)          ← ビジネスルール・エンティティ
        ↑
Infrastructure Layer (infra/)    ← データアクセス・外部サービス
```

### 主要特徴

- **依存性逆転**: ドメイン層が他層に依存しない
- **リポジトリパターン**: データアクセスの抽象化
- **イベント駆動**: 非同期処理による疎結合
- **依存性注入**: テスタビリティの向上

### アーキテクチャ準拠度

| 原則 | 準拠度 | 状態 |
|------|--------|------|
| **クリーンアーキテクチャ** | 100% | ✅ 完全準拠 |
| **MVVM パターン** | 100% | ✅ 完全準拠 |
| **RESTful 設計** | 100% | ✅ 完全準拠 |

### 詳細なレイヤー構造

#### 1. Domain Layer (ドメイン層)
**責務**: ビジネスルールとエンティティの定義

```
/src/domain/
├── /repositories/         # リポジトリインターフェース
│   ├── ITweetRepository.ts
│   ├── IUserRepository.ts
│   └── IGymRepository.ts
├── /services/            # ドメインサービスインターフェース
│   └── IEventBus.ts
└── /events/             # ドメインイベント
    └── TweetDeletedEvent.ts
```

**特徴**:
- インフラストラクチャに依存しない純粋なビジネスロジック
- インターフェースによる抽象化
- ドメインイベントによる疎結合

#### 2. Application Layer (アプリケーション層)
**責務**: ビジネスロジックの実装とオーケストレーション

```
/src/services/
├── tweetService.ts       # ツイート業務ロジック
├── userService.ts        # ユーザー業務ロジック
├── gymService.ts         # ジム業務ロジック
└── favoriteService.ts    # お気に入り業務ロジック
```

**特徴**:
- リポジトリインターフェースのみに依存
- イベント駆動による非同期処理
- ビジネスルールの実装

#### 3. Infrastructure Layer (インフラストラクチャ層)
**責務**: 外部システムとの通信、具体的な実装

```
/src/infrastructure/
├── /repositories/        # リポジトリ実装
│   ├── PostgresTweetRepository.ts
│   ├── PostgresUserRepository.ts
│   └── PostgresGymRepository.ts
├── /events/             # イベントバス実装
│   └── InMemoryEventBus.ts
├── /handlers/           # イベントハンドラー
│   └── StorageCleanupEventHandler.ts
└── /setup/              # 依存性注入設定
    └── dependencies.ts
```

**特徴**:
- PostgreSQL との具体的な通信
- Cloud Tasks との連携
- イベント配信の実装

#### 4. Presentation Layer (プレゼンテーション層)
**責務**: HTTP リクエスト/レスポンスの処理

```
/src/routes/
├── tweets.ts            # ツイートエンドポイント
├── users.ts             # ユーザーエンドポイント
├── gyms.ts              # ジムエンドポイント
└── internal_tasks.ts    # 内部タスクエンドポイント
```

**特徴**:
- RESTful API の実装
- 認証・認可の処理
- バリデーション

### 実装パターン詳細

#### リポジトリパターン
すべてのデータアクセスはリポジトリインターフェースを通じて抽象化されています。

```typescript
// ドメイン層のインターフェース
export interface ITweetRepository {
  getAllTweets(limit: number, cursor?: string): Promise<any[]>;
  getTweetById(tweetId: number): Promise<any | null>;
  createTweet(tweetData: CreateTweetDto): Promise<Tweet>;
  deleteTweet(tweetId: number, userId: string): Promise<void>;
}

// インフラ層の実装
export class PostgresTweetRepository implements ITweetRepository {
  // PostgreSQL 固有の実装
}
```

#### イベント駆動アーキテクチャ
ドメインイベントによる疎結合な設計：

```typescript
// ドメインイベント
export class TweetDeletedEvent {
  constructor(
    public readonly tweetId: number,
    public readonly userId: string,
    public readonly storagePrefixes: string[]
  ) {}
}

// イベント発行
await this.eventBus.publish(new TweetDeletedEvent(...));

// イベントハンドリング
eventBus.subscribe('TweetDeleted', handler.handle);
```

#### 依存性注入 (DI)
すべての依存関係は起動時に注入：

```typescript
// 依存性の組み立て
const repository = new PostgresTweetRepository();
const eventBus = new InMemoryEventBus();
const service = new TweetService(repository, eventBus);
```

#### MVVM パターンの実装

**View Layer (Routes)**
```typescript
// プレゼンテーション層
router.delete('/:tweet_id', async (req, res) => {
  await tweetService.deleteTweet(tweetId, userId);
  res.status(204).send();
});
```

**ViewModel Layer (Services)**
```typescript
// ビジネスロジック層
export class TweetService {
  async deleteTweet(tweetId: number, userId: string) {
    // ビジネスロジックの実装
  }
}
```

**Model Layer (Repositories)**
```typescript
// データアクセス層
export class PostgresTweetRepository {
  async deleteTweet(tweetId: number) {
    // データベースアクセス
  }
}
```

### 非同期処理アーキテクチャ

#### GCS 削除の流れ
1. **同期処理**: ツイート削除（データベース）
2. **イベント発行**: TweetDeletedEvent
3. **非同期処理**: StorageCleanupEventHandler
4. **Cloud Tasks**: バックグラウンドでGCS削除

```
Client → API → TweetService → Repository
                    ↓
                EventBus → Handler → Cloud Tasks → GCS
```

---

## 📊 データベース設計

### 主要テーブル

| テーブル名 | 用途 | 主要カラム |
|-----------|------|-----------|
| **users** | ユーザー情報 | user_id(PK), user_name, email |
| **gyms** | ジム情報 | gym_id(PK), gym_name, prefecture, lat/lng |
| **tweets** | ツイート投稿 | tweet_id(PK), user_id(FK), gym_id(FK) |
| **tweet_media** | ツイート画像 | media_id(PK), tweet_id(FK), media_url |
| **user_favorites** | ユーザーお気に入り | liker_user_id(FK), likee_user_id(FK) |
| **gym_favorites** | ジムお気に入り | user_id(FK), gym_id(FK) |
| **gym_hours** | ジム営業時間 | gym_id(FK), day_of_week, open_time |

### 完全なデータベーススキーマ設計

#### 1. ユーザーテーブル（users）
```sql
CREATE TABLE users (
  user_id VARCHAR(28) PRIMARY KEY,           -- Firebase UID
  user_name VARCHAR(255) NOT NULL,
  email VARCHAR(320) UNIQUE NOT NULL,
  user_icon_url TEXT,
  user_introduce TEXT,                       -- 自己紹介
  favorite_gym TEXT,                         -- お気に入りジム（テキスト）
  boul_start_date DATE,                      -- ボルダリング開始日
  home_gym_id INTEGER,                       -- ホームジムID
  gender INTEGER DEFAULT 0,                  -- 性別（0:未設定, 1:男性, 2:女性, 3:その他）
  birthday DATE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- インデックス
CREATE UNIQUE INDEX users_new_email_key ON users(email);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_home_gym ON users(home_gym_id);

-- 制約
ALTER TABLE users ADD CONSTRAINT users_new_gender_check
  CHECK (gender = ANY (ARRAY[0, 1, 2, 3]));

-- トリガー（自動更新日時更新）
CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON users FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();
```

#### 2. ジムテーブル（gyms）
```sql
CREATE TABLE gyms (
  gym_id SERIAL PRIMARY KEY,
  gym_name VARCHAR(255) NOT NULL,
  prefecture VARCHAR(20) NOT NULL,
  city VARCHAR(64) NOT NULL,
  address_line TEXT NOT NULL,
  latitude NUMERIC(10,8) NOT NULL,
  longitude NUMERIC(11,8) NOT NULL,
  tel_no VARCHAR(35),                        -- 電話番号
  hp_link TEXT,                              -- ホームページURL
  fee TEXT,                                  -- 料金情報
  minimum_fee INTEGER,                       -- 最低料金
  equipment_rental_fee TEXT,                 -- レンタル料金
  is_bouldering_gym BOOLEAN DEFAULT true,    -- ボルダリング対応
  is_lead_gym BOOLEAN DEFAULT false,         -- リード対応
  is_speed_gym BOOLEAN DEFAULT false,        -- スピード対応
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- インデックス
CREATE INDEX idx_gyms_location ON gyms(prefecture, city);

-- トリガー
CREATE TRIGGER update_gyms_updated_at
  BEFORE UPDATE ON gyms FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();
```

#### 3. ツイートテーブル（tweets）
```sql
CREATE TABLE tweets (
  tweet_id SERIAL PRIMARY KEY,
  user_id VARCHAR(28) NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  gym_id INTEGER REFERENCES gyms(gym_id) ON DELETE SET NULL,
  tweet_contents TEXT,
  visited_date DATE,
  tweeted_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  liked_counts INTEGER DEFAULT 0,
  movie_url TEXT DEFAULT ''                  -- 動画URL（レガシー）
);

-- インデックス
CREATE INDEX idx_tweets_created_at ON tweets(tweeted_date DESC);
CREATE INDEX idx_tweets_gym_id ON tweets(gym_id);
CREATE INDEX idx_tweets_user_id ON tweets(user_id);

-- トリガー
CREATE TRIGGER update_tweets_updated_at
  BEFORE UPDATE ON tweets FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();
```

#### 4. ツイートメディアテーブル（tweet_media）
```sql
CREATE TABLE tweet_media (
  media_id SERIAL PRIMARY KEY,
  tweet_id INTEGER NOT NULL REFERENCES tweets(tweet_id) ON DELETE CASCADE,
  media_url TEXT NOT NULL,
  media_type VARCHAR(10) NOT NULL,           -- 'image' or 'video'
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  asset_uuid UUID,                           -- Cloud Storage用UUID
  storage_prefix TEXT,                       -- ストレージパス
  mime_type TEXT                             -- MIMEタイプ
);

-- インデックス
CREATE INDEX idx_tweet_media_tweet_id ON tweet_media(tweet_id);

-- 制約
ALTER TABLE tweet_media ADD CONSTRAINT tweet_media_new_media_type_check
  CHECK (media_type = ANY (ARRAY['image', 'video']));
```

#### 5. ユーザーお気に入りテーブル（user_favorites）
```sql
CREATE TABLE user_favorites (
  liker_user_id VARCHAR(28) NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  likee_user_id VARCHAR(28) NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (liker_user_id, likee_user_id)
);

-- インデックス
CREATE INDEX idx_user_favorites_followed ON user_favorites(likee_user_id);
CREATE INDEX idx_user_favorites_follower ON user_favorites(liker_user_id);

-- 制約（自分自身をフォロー禁止）
ALTER TABLE user_favorites ADD CONSTRAINT user_favorites_new_check
  CHECK (liker_user_id <> likee_user_id);
```

#### 6. ジムお気に入りテーブル（gym_favorites）
```sql
CREATE TABLE gym_favorites (
  user_id VARCHAR(28) NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  gym_id INTEGER NOT NULL REFERENCES gyms(gym_id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id, gym_id)
);

-- インデックス
CREATE INDEX idx_gym_favorites_gym ON gym_favorites(gym_id);
CREATE INDEX idx_gym_favorites_user ON gym_favorites(user_id);
```

#### 7. ジム営業時間テーブル（gym_hours）
```sql
CREATE TABLE gym_hours (
  gym_id INTEGER PRIMARY KEY REFERENCES gyms(gym_id) ON DELETE CASCADE,
  mon_open TIME WITHOUT TIME ZONE,           -- 月曜開店時間
  mon_close TIME WITHOUT TIME ZONE,          -- 月曜閉店時間
  tue_open TIME WITHOUT TIME ZONE,
  tue_close TIME WITHOUT TIME ZONE,
  wed_open TIME WITHOUT TIME ZONE,
  wed_close TIME WITHOUT TIME ZONE,
  thu_open TIME WITHOUT TIME ZONE,
  thu_close TIME WITHOUT TIME ZONE,
  fri_open TIME WITHOUT TIME ZONE,
  fri_close TIME WITHOUT TIME ZONE,
  sat_open TIME WITHOUT TIME ZONE,
  sat_close TIME WITHOUT TIME ZONE,
  sun_open TIME WITHOUT TIME ZONE,
  sun_close TIME WITHOUT TIME ZONE,
  notes TEXT                                 -- 営業時間に関する特記事項
);
```

### リレーション図

```
users (1) ←→ (N) user_favorites          フォロー関係
users (1) ←→ (N) gym_favorites           ジムお気に入り
users (1) ←→ (N) tweets                  ツイート投稿
gyms (1) ←→ (N) tweets                   ジム-ツイート関係
gyms (1) ←→ (1) gym_hours                営業時間
tweets (1) ←→ (N) tweet_media            ツイート画像・動画
```

---

## 🔌 API仕様

### エンドポイント一覧

| メソッド | エンドポイント | 説明 | 認証 |
|---------|---------------|------|------|
| GET | `/api/tweets` | ツイート一覧取得 | ✅ |
| GET | `/api/tweets/:id` | 特定ツイート取得 | ✅ |
| POST | `/api/tweets` | ツイート作成 | ✅ |
| DELETE | `/api/tweets/:id` | ツイート削除 | ✅ |
| GET | `/api/gyms` | ジム一覧・検索 | ✅ |
| GET | `/api/gyms/:id` | ジム詳細取得 | ✅ |
| GET | `/api/users/:id` | ユーザー情報取得 | ✅ |
| PUT | `/api/users/:id` | ユーザー情報更新 | ✅ |
| POST | `/api/favorites/users` | ユーザーお気に入り追加 | ✅ |
| POST | `/api/favorites/gyms` | ジムお気に入り追加 | ✅ |

### 認証フロー

```
Flutter App → Firebase Auth → ID Token → API Request
                                      ↓
Backend → Firebase Admin SDK → Token Verification → Response
```

### レスポンス形式

#### 成功レスポンス
```json
{
  "success": true,
  "data": { ... },
  "meta": {
    "limit": 20,
    "offset": 0,
    "total": 150
  }
}
```

#### エラーレスポンス
```json
{
  "success": false,
  "error": "エラーメッセージ",
  "code": "ERROR_CODE"
}
```

### HTTPステータスコード

| コード | 意味 | 使用例 |
|-------|------|--------|
| 200 | 成功 | GET リクエスト成功 |
| 201 | 作成成功 | POST でリソース作成 |
| 204 | コンテンツなし | DELETE 成功 |
| 400 | リクエストエラー | バリデーションエラー |
| 401 | 認証エラー | 無効なトークン |
| 403 | 権限エラー | 他人のデータ編集 |
| 404 | リソースなし | 存在しないID |
| 500 | サーバーエラー | DB接続エラー等 |

---

## 🛠 開発環境セットアップ

### 前提条件

- Node.js 18.0.0以上
- npm または yarn
- Docker（本番デプロイ用）
- Google Cloud SDK

### ローカル開発環境構築

```bash
# リポジトリクローン
git clone [YOUR_REPOSITORY_URL]  # 例: https://github.com/yourname/your-app.git
cd [YOUR_APP_DIR]/backend  # 例: your-app/backend

# 依存関係インストール
npm install

# 環境変数設定
cp .env.example .env.dev
# .env.dev を編集して適切な値を設定

# TypeScriptコンパイル
npm run build

# 開発サーバー起動
npm run dev
```

### 環境変数設定

#### 開発環境（.env.dev）
```bash
# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=[YOUR_DB_NAME_DEV]  # 例: your_app_dev
DB_USER=postgres
DB_PASSWORD=[YOUR_DEV_DB_PASSWORD]  # 強力なパスワードを設定

# Firebase
FIREBASE_PROJECT_ID=[YOUR_FIREBASE_PROJECT_ID]  # Firebase プロジェクトID
GOOGLE_APPLICATION_CREDENTIALS=[PATH_TO_FIREBASE_KEY]  # 例: ./keys/firebase-key.json

# Server
PORT=8080
NODE_ENV=development

# Cloud Tasks (開発時は無効化可能)
TASKS_HANDLER_URL=http://localhost:8080
GCP_PROJECT=[YOUR_GCP_PROJECT_ID]  # Google Cloud プロジェクトID
```

#### 本番環境（Cloud Run）
```bash
# Database (Cloud SQL)
DB_HOST=/cloudsql/[YOUR_GCP_PROJECT_ID]:asia-northeast1:[YOUR_DB_INSTANCE_NAME]
DB_PORT=5432
DB_NAME=[YOUR_DB_NAME_PROD]  # 例: your_app_prod
DB_USER=postgres
DB_PASSWORD=${SECRET_DB_PASSWORD}  # Secret Managerから取得

# Firebase
FIREBASE_PROJECT_ID=[YOUR_FIREBASE_PROJECT_ID]  # Firebase プロジェクトID

# Server
PORT=8080
NODE_ENV=production

# Cloud Tasks
TASKS_HANDLER_URL=[YOUR_CLOUD_RUN_URL]  # 例: https://your-api-service.run.app
GCP_PROJECT=[YOUR_GCP_PROJECT_ID]  # Google Cloud プロジェクトID
```

### ローカルデータベース設定

```bash
# PostgreSQLをローカルにインストール（macOS）
brew install postgresql
brew services start postgresql

# データベース作成
createdb [YOUR_DB_NAME_DEV]  # 例: your_app_dev

# スキーマ適用
psql [YOUR_DB_NAME_DEV] < [PATH_TO_SCHEMA_FILE]  # 例: docs/schema/dev_schema.sql
```

---

## 🚀 ビルド・実行

### ローカル開発

```bash
# 開発モード（ホットリロード）
npm run dev

# ビルド
npm run build

# 本番モード（ローカル）
npm start

# テスト実行
npm test

# リンター
npm run lint

# フォーマッター
npm run format
```

---

## 🧪 テスト戦略

### テスト構成

```bash
backend/
├── tests/
│   ├── unit/           # 単体テスト
│   │   ├── services/
│   │   ├── repositories/
│   │   └── utils/
│   ├── integration/    # 統合テスト
│   │   ├── api/
│   │   └── database/
│   └── e2e/           # E2Eテスト
│       └── scenarios/
```

### テスト実行

```bash
# 全テスト実行
npm test

# 単体テストのみ
npm run test:unit

# 統合テストのみ
npm run test:integration

# カバレッジ付きテスト
npm run test:coverage

# ウォッチモード
npm run test:watch
```

### APIテスト例

```typescript
// tests/integration/api/tweets.test.ts
describe('POST /api/tweets', () => {
  it('should create a new tweet', async () => {
    const response = await request(app)
      .post('/api/tweets')
      .set('Authorization', `Bearer ${validToken}`)
      .send({
        gym_id: 1,
        tweet_contents: 'Test tweet',
        visited_date: '2025-01-01'
      })
      .expect(201);

    expect(response.body.success).toBe(true);
    expect(response.body.data.tweet_contents).toBe('Test tweet');
  });
});
```

---

## 📋 開発ガイドライン

### 新機能追加フロー

1. **Domain Layer**: インターフェース定義
   ```typescript
   // domain/repositories/INewRepository.ts
   export interface INewRepository {
     methodName(params: Type): Promise<ReturnType>;
   }
   ```

2. **Infrastructure Layer**: 実装
   ```typescript
   // infrastructure/repositories/PostgresNewRepository.ts
   export class PostgresNewRepository implements INewRepository {
     async methodName(params: Type): Promise<ReturnType> {
       // PostgreSQL実装
     }
   }
   ```

3. **Application Layer**: ビジネスロジック
   ```typescript
   // services/newService.ts
   export class NewService {
     constructor(private repository: INewRepository) {}
   }
   ```

4. **Presentation Layer**: エンドポイント
   ```typescript
   // routes/new.ts
   router.post('/new', authenticate, handler);
   ```

### アーキテクチャの拡張性

#### データベース変更への対応
PostgreSQL から他のデータベースへの移行が容易：

1. 新しいリポジトリ実装を作成
2. `dependencies.ts` で注入する実装を変更
3. アプリケーションコードの変更不要

```typescript
// 例：MongoDB実装への切り替え
const repository = new MongoTweetRepository(); // PostgresTweetRepository から変更
const service = new TweetService(repository, eventBus); // サービス層は無変更
```

#### 新機能の追加
Clean Architectureにより、新機能追加時の影響範囲が限定的：

- **ドメイン層**: ビジネスルール追加
- **インフラ層**: 新しいデータソース追加
- **アプリケーション層**: ビジネスロジック実装
- **プレゼンテーション層**: API エンドポイント追加

### テスタビリティの実現

#### 単体テスト
依存性注入により、各層を独立してテスト可能：

```typescript
// モックを使ったサービステスト
describe('TweetService', () => {
  const mockRepository = {
    deleteTweet: jest.fn(),
    getTweetById: jest.fn()
  };
  const mockEventBus = {
    publish: jest.fn()
  };

  const service = new TweetService(mockRepository, mockEventBus);

  it('should delete tweet and publish event', async () => {
    await service.deleteTweet(123, 'user123');

    expect(mockRepository.deleteTweet).toHaveBeenCalledWith(123, 'user123');
    expect(mockEventBus.publish).toHaveBeenCalledWith(
      expect.any(TweetDeletedEvent)
    );
  });
});
```

#### 統合テスト
各レイヤーを組み合わせた統合テストも容易：

```typescript
// リアルデータベースを使った統合テスト
describe('Tweet API Integration', () => {
  beforeEach(async () => {
    await setupTestDatabase();
  });

  it('should create and retrieve tweet', async () => {
    const response = await request(app)
      .post('/api/tweets')
      .send({ content: 'Test tweet', gym_id: 1 });

    expect(response.status).toBe(201);
  });
});
```

### パフォーマンス最適化

#### データベース最適化
- **インデックス戦略**: 検索頻度の高いカラムに適切なインデックス設定
- **N+1 問題対策**: JOIN を使用した効率的なクエリ
- **コネクションプーリング**: データベース接続の効率化

```sql
-- 複合インデックスによる検索最適化
CREATE INDEX idx_tweets_user_date ON tweets(user_id, tweeted_date DESC);

-- JOINによるN+1問題解決
SELECT t.*, u.user_name, g.gym_name
FROM tweets t
INNER JOIN users u ON t.user_id = u.user_id
INNER JOIN gyms g ON t.gym_id = g.gym_id;
```

#### 非同期処理による最適化
- **Cloud Tasks**: 重い処理（画像削除等）を非同期化
- **イベント駆動**: レスポンス時間の短縮
- **バックグラウンド処理**: ユーザー体験の向上

```typescript
// 同期：ツイート削除（高速）
await this.repository.deleteTweet(tweetId, userId);

// 非同期：ストレージ削除（時間のかかる処理）
await this.eventBus.publish(new TweetDeletedEvent(tweetId, userId, prefixes));
```

### コーディング規約

- **ファイル名**: `camelCase.ts`
- **クラス名**: `PascalCase`
- **関数・変数**: `camelCase`
- **定数**: `UPPER_SNAKE_CASE`
- **インターフェース**: `IInterfaceName`

### エラーハンドリング

```typescript
// 標準エラーレスポンス
class ApiError extends Error {
  constructor(
    public message: string,
    public statusCode: number,
    public code?: string
  ) {
    super(message);
  }
}

// 使用例
throw new ApiError('Tweet not found', 404, 'TWEET_NOT_FOUND');
```

---

## 📈 監視・ログ

### 構造化ログ

```typescript
import winston from 'winston';

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  )
});

// 使用例
logger.info('Tweet created successfully', {
  userId,
  tweetId,
  gymId,
  timestamp: new Date().toISOString()
});
```

### パフォーマンス監視

- **Cloud Logging**: アプリケーションログ
- **Cloud Monitoring**: メトリクス監視
- **Cloud Trace**: 分散トレーシング
- **Error Reporting**: エラー追跡

---

## 🔒 セキュリティ

### 認証・認可

```typescript
// Firebase ID Token検証
export const authenticate = async (req: Request, res: Response, next: NextFunction) => {
  const token = req.headers.authorization?.replace('Bearer ', '');

  try {
    const decodedToken = await admin.auth().verifyIdToken(token);
    req.user = decodedToken;
    next();
  } catch (error) {
    res.status(401).json({ success: false, error: 'Unauthorized' });
  }
};
```

### データ保護

- **SQLインジェクション対策**: パラメータバインディング
- **XSS対策**: 入力値サニタイズ
- **CSRF対策**: トークンベース認証
- **レート制限**: express-rate-limit

### 機密情報管理

```typescript
// Secret Managerから取得
const password = await secretManager.accessSecretVersion({
  name: `projects/${projectId}/secrets/db-password-${env}/versions/latest`
});
```

---

## 📚 リファレンス

### 関連ドキュメント

- [アーキテクチャ詳細](./ARCHITECTURE.md)
- [プロジェクト概要](../README.md)
- [フロントエンド](../lib/)
- [Google Cloud環境構築手順](../Google Cloud 環境構築手順.txt)

### 外部リソース

- [Google Cloud Run Documentation](https://cloud.google.com/run/docs)
- [Firebase Admin SDK](https://firebase.google.com/docs/admin/setup)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Express.js Guide](https://expressjs.com/en/guide/)

### APIテストツール

- **Postman**: GUI APIテスト
- **curl**: CLIテスト
- **Jest + Supertest**: 自動テスト

---

## 🐛 トラブルシューティング

### よくある問題

#### Cloud SQL接続エラー
```bash
# 解決方法
1. Cloud SQL Admin API有効化確認
2. サービスアカウント権限確認
3. インスタンス接続名確認
```

#### Firebase認証エラー
```bash
# 解決方法
1. Firebase Admin SDK キー確認
2. プロジェクトID確認
3. トークン有効期限確認
```

#### メモリ不足エラー
```bash
# Cloud Run設定
--memory=2Gi  # メモリ増量
--cpu=2       # CPU増量
```

### ログ確認方法

```bash
# Cloud Runログ
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=[YOUR_SERVICE_NAME]" --limit=50
# 例: service_name=your-api-dev

# Cloud SQLログ
gcloud logging read "resource.type=cloudsql_database" --limit=50
```

---

## 🤝 開発者向け情報

### 必要な権限

開発者は以下の Google Cloud IAM ロールが必要：

- **Cloud Run 開発者**
- **Cloud SQL 編集者**
- **Secret Manager シークレット アクセサー**
- **Artifact Registry 管理者**

### 開発フロー

1. **ローカル開発**: `npm run dev`
2. **テスト**: `npm test`
3. **ビルド確認**: `npm run build`
4. **デプロイ**: Google Cloud 環境構築手順に従う

### 本番リリース手順

1. **develop** ブランチで開発
2. **main** ブランチにマージ
3. バージョンタグ作成（例: `v1.0.0`）
4. 本番環境デプロイ
5. 動作確認・監視

---

*最終更新: 2025年9月*
*バージョン: 1.0.0*
