# ボルダリングアプリ（クリーンアーキテクチャ版）

クリーンアーキテクチャの原則に基づいて再設計されたボルダリングアプリです。

## 🏗️ アーキテクチャ概要

### 層構造

```
lib_new/
├── domain/                    # ドメイン層（中核・抽象度最高）
│   ├── entities/             # エンティティ（ビジネスルール）
│   ├── repositories/         # リポジトリインタフェース
│   └── usecases/            # ユースケース（ビジネスロジック）
├── infrastructure/          # インフラ層（外側・詳細実装）
│   ├── services/            # 外部サービス（API、ストレージ）
│   ├── datasources/         # データソース（API通信）
│   └── repositories/        # リポジトリ実装
├── presentation/            # プレゼンテーション層（最外層・UI）
│   ├── providers/           # 状態管理（Riverpod）
│   ├── pages/              # 画面コンポーネント
│   └── components/         # UIコンポーネント
└── shared/                 # 共通
    ├── config/             # 環境設定
    ├── utils/              # ユーティリティ
    ├── constants/          # 定数
    └── extensions/         # 拡張メソッド
```

### 設計原則

1. **依存関係逆転**: 内側の層は外側の層を知らない
2. **単一責任**: 各クラスが明確な責務を持つ
3. **オープン/クローズ**: 拡張に開放、変更に閉鎖
4. **インタフェース分離**: 必要最小限のインタフェース

## 🚀 セットアップ手順

### 1. 開発環境のセットアップ

#### 1.1 新しいAPIサーバーの構築
```bash
# TODO: 新しい開発環境APIサーバーを構築後、以下の設定を更新
# lib_new/shared/config/environment_config.dart の
# _developmentApiEndpoint を実際のエンドポイントに変更

# 例: https://dev-api.your-domain.com/api/v1
```

#### 1.2 データベースサーバーのセットアップ
```bash
# TODO: 新しい開発用データベースサーバーをセットアップ後、以下の設定を更新
# lib_new/shared/config/environment_config.dart の
# _developmentDatabaseConfig を実際の接続情報に変更

# 例:
# host: 10.0.0.1
# port: 5432
# database: bouldering_app_dev
# username: dev_user
# password: dev_password_123
```

#### 1.3 Google Cloud Storage の設定
```bash
# TODO: 新しい開発用GCSバケットを作成後、以下の設定を更新
# lib_new/shared/config/environment_config.dart の
# _developmentGcsBucket を実際のバケット名に変更

# サービスアカウントキーファイルを配置
# assets/keys/dev_service_account.json

# 例: your-app-media-dev
```

#### 1.4 Firebase の設定
```bash
# TODO: 新しい開発用Firebaseプロジェクトをセットアップ後、設定ファイルを配置
# lib/firebase_options_dev.dart を作成

# Firebaseプロジェクトの設定手順:
# 1. Firebase Console でプロジェクト作成
# 2. iOS/Android アプリを追加
# 3. 設定ファイルをダウンロード・配置
# 4. FlutterFire CLI で設定ファイル生成
```

### 2. 本番環境のセットアップ

#### 2.1 本番用APIサーバーの構築
```bash
# TODO: 本番用APIサーバーを構築・デプロイ後、以下の設定を更新
# lib_new/shared/config/environment_config.dart の
# _productionApiEndpoint を実際のエンドポイントに変更

# セキュリティ要件:
# - HTTPS対応（SSL証明書の設定）
# - 高可用性・負荷分散の構成
# - 適切なアクセス制御

# 例: https://api.your-domain.com/api/v1
```

#### 2.2 本番用データベースの構築
```bash
# TODO: 本番用データベースサーバーをセットアップ後、以下の設定を更新
# lib_new/shared/config/environment_config.dart の
# _productionDatabaseConfig を実際の接続情報に変更

# セキュリティ要件:
# - 冗長化・バックアップ体制の構築
# - ネットワークセキュリティの強化
# - 適切な認証・認可設定

# 例:
# host: your-db.region.gcp.cloud.sql
# port: 5432
# database: bouldering_app_prod
# username: prod_user
# password: prod_secure_password_456
```

#### 2.3 本番用GCS・Firebase の設定
```bash
# TODO: 本番用GCS・Firebaseプロジェクトの設定

# GCS設定:
# lib_new/shared/config/environment_config.dart の
# _productionGcsBucket を本番用バケット名に変更
# assets/keys/prod_service_account.json を配置

# Firebase設定:
# lib/firebase_options_prod.dart を作成
```

## 🏃‍♂️ アプリの起動方法

### 開発版の起動
```bash
# main_dev.dart を使用して開発環境に接続
flutter run -t lib_new/main_dev.dart

# または VS Code/Android Studio の実行設定で main_dev.dart を指定
```

### 本番版の起動
```bash
# main_prod.dart を使用して本番環境に接続
flutter run -t lib_new/main_prod.dart --release

# リリースビルド
flutter build apk -t lib_new/main_prod.dart
flutter build ipa -t lib_new/main_prod.dart
```

## 🔧 設定の検証

アプリ起動時に設定値が正しく設定されているかチェックされます：

```dart
// 開発環境起動時（main_dev.dart）
final configIssues = EnvironmentConfig.validateConfiguration();
if (configIssues.isNotEmpty) {
  print('⚠️ 設定に問題があります:');
  for (final issue in configIssues) {
    print('  - $issue');
  }
}
```

プレースホルダが残っている場合は警告が表示されます。

## 📱 主要機能

### ホームページ
- ジム検索・フィルタリング
- 地図表示での近隣ジム検索
- 人気ジムランキング

### ボル活ページ
- 全体のツイート表示
- お気に入りユーザーのツイート表示
- ジム別ツイート表示

### 投稿ページ
- ツイート投稿（テキスト・画像・動画）
- ジム選択機能
- 投稿日時設定

### マイページ
- プロフィール管理
- お気に入りユーザー管理
- イキタイジム管理
- アカウント設定

## 🧪 テスト

```bash
# ユニットテストの実行
flutter test

# インテグレーションテストの実行
flutter test integration_test/
```

## 🚀 デプロイ

### Android
```bash
# APKビルド
flutter build apk -t lib_new/main_prod.dart --release

# App Bundleビルド（Google Play Store用）
flutter build appbundle -t lib_new/main_prod.dart --release
```

### iOS
```bash
# IPAビルド
flutter build ipa -t lib_new/main_prod.dart --release
```

## 📝 開発ガイドライン

### 新機能の追加手順

1. **Domain層**: 必要に応じてエンティティ・ユースケースを追加
2. **Infrastructure層**: データソース・リポジトリ実装を追加
3. **Presentation層**: Provider・UI コンポーネントを追加

### コード品質の維持

- クリーンアーキテクチャの依存関係を守る
- 単体テストを必ず書く
- コードレビューを実施する
- 継続的インテグレーションを活用する

## 🆘 トラブルシューティング

### よくある問題

1. **設定エラー**: プレースホルダが残っている
   - `EnvironmentConfig.validateConfiguration()` でチェック
   - 該当する設定値を実際の値に変更

2. **API接続エラー**: エンドポイントが正しくない
   - 開発・本番環境のAPIサーバーが起動しているか確認
   - ネットワーク接続を確認

3. **認証エラー**: Firebase・GCS の設定が正しくない
   - サービスアカウントキーファイルの配置を確認
   - Firebase プロジェクト設定を確認

### ログの確認

開発環境では詳細なログが出力されます：

```dart
// EnvironmentConfig.printConfiguration() で設定値を表示
// デバッグログレベルで詳細な情報を出力
```

## 📖 参考資料

- [Clean Architecture - Robert C. Martin](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Flutter Clean Architecture](https://github.com/ResoCoder/flutter-tdd-clean-architecture-course)
- [Riverpod Documentation](https://riverpod.dev/)
- [Firebase for Flutter](https://firebase.flutter.dev/)

## 📄 ライセンス

[ライセンス情報をここに記載]

## 🌐 サーバー側実装要件（Google Cloud）

### APIサーバー実装

#### 必要なAPIエンドポイント

##### 認証・ユーザー管理
```
POST   /api/v1/auth/login
POST   /api/v1/auth/signup
POST   /api/v1/auth/logout
GET    /api/v1/users/{userId}
PUT    /api/v1/users/{userId}/profile
PUT    /api/v1/users/{userId}/icon
POST   /api/v1/users/{userId}/upload-icon
```

##### ジム管理
```
GET    /api/v1/gyms/search?prefecture={}&city={}&name={}&types={}
GET    /api/v1/gyms/nearby?lat={}&lng={}&radius={}
GET    /api/v1/gyms/popular?limit={}
GET    /api/v1/gyms/{gymId}
GET    /api/v1/gyms/{gymId}/tweets?limit={}&offset={}
```

##### ツイート管理
```
GET    /api/v1/tweets?limit={}&offset={}
POST   /api/v1/tweets
GET    /api/v1/tweets/{tweetId}
DELETE /api/v1/tweets/{tweetId}
GET    /api/v1/tweets/favorites/{userId}?limit={}&offset={}
GET    /api/v1/tweets/users/{userId}?limit={}&offset={}
POST   /api/v1/tweets/{tweetId}/like
DELETE /api/v1/tweets/{tweetId}/like
POST   /api/v1/tweets/{tweetId}/bookmark
DELETE /api/v1/tweets/{tweetId}/bookmark
```

##### お気に入り・フォロー管理
```
GET    /api/v1/favorites/users/{userId}
POST   /api/v1/favorites/users/{targetUserId}
DELETE /api/v1/favorites/users/{targetUserId}
GET    /api/v1/favorites/gyms/{userId}
POST   /api/v1/favorites/gyms/{gymId}
DELETE /api/v1/favorites/gyms/{gymId}
```

#### データベーススキーマ

##### users テーブル
```sql
CREATE TABLE users (
    user_id VARCHAR(255) PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    user_name VARCHAR(100),
    user_icon_url TEXT,
    user_introduce TEXT,
    favorite_gym VARCHAR(255),
    gender INTEGER, -- 0: 未設定, 1: 男性, 2: 女性
    birthday DATE,
    boul_start_date DATE,
    home_gym_id INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

##### gyms テーブル
```sql
CREATE TABLE gyms (
    gym_id SERIAL PRIMARY KEY,
    gym_name VARCHAR(255) NOT NULL,
    prefecture VARCHAR(50) NOT NULL,
    city VARCHAR(100) NOT NULL,
    address TEXT NOT NULL,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    phone_number VARCHAR(20),
    website_url TEXT,
    climbing_types JSON, -- ["ボルダリング", "リードクライミング", etc.]
    facilities JSON, -- 施設情報
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

##### tweets テーブル
```sql
CREATE TABLE tweets (
    tweet_id SERIAL PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL,
    gym_id INTEGER NOT NULL,
    tweet_content TEXT NOT NULL,
    visited_date DATE NOT NULL,
    movie_url TEXT,
    media_urls JSON, -- 画像・動画URL配列
    like_count INTEGER DEFAULT 0,
    bookmark_count INTEGER DEFAULT 0,
    comment_count INTEGER DEFAULT 0,
    tweeted_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (gym_id) REFERENCES gyms(gym_id)
);
```

##### favorite_relations テーブル
```sql
CREATE TABLE favorite_relations (
    id SERIAL PRIMARY KEY,
    liker_user_id VARCHAR(255) NOT NULL,
    likee_user_id VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (liker_user_id) REFERENCES users(user_id),
    FOREIGN KEY (likee_user_id) REFERENCES users(user_id),
    UNIQUE(liker_user_id, likee_user_id)
);
```

##### wanna_go_relations テーブル
```sql
CREATE TABLE wanna_go_relations (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL,
    gym_id INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (gym_id) REFERENCES gyms(gym_id),
    UNIQUE(user_id, gym_id)
);
```

##### tweet_likes テーブル
```sql
CREATE TABLE tweet_likes (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL,
    tweet_id INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (tweet_id) REFERENCES tweets(tweet_id),
    UNIQUE(user_id, tweet_id)
);
```

##### tweet_bookmarks テーブル
```sql
CREATE TABLE tweet_bookmarks (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL,
    tweet_id INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (tweet_id) REFERENCES tweets(tweet_id),
    UNIQUE(user_id, tweet_id)
);
```

### Google Cloud Services 設定

#### 1. Cloud SQL（PostgreSQL）
```bash
# インスタンス作成
gcloud sql instances create bouldering-app-db \
    --database-version=POSTGRES_14 \
    --tier=db-f1-micro \
    --region=asia-northeast1

# データベース作成
gcloud sql databases create bouldering_app_dev --instance=bouldering-app-db
gcloud sql databases create bouldering_app_prod --instance=bouldering-app-db

# ユーザー作成
gcloud sql users create dev_user --instance=bouldering-app-db --password=dev_password_123
gcloud sql users create prod_user --instance=bouldering-app-db --password=prod_secure_password_456
```

#### 2. Cloud Storage
```bash
# バケット作成
gsutil mb gs://your-app-media-dev
gsutil mb gs://your-app-media-prod

# 公開アクセス設定
gsutil iam ch allUsers:objectViewer gs://your-app-media-dev
gsutil iam ch allUsers:objectViewer gs://your-app-media-prod
```

#### 3. Cloud Run（APIサーバー）
```bash
# APIサーバーをデプロイ
gcloud run deploy bouldering-api-dev \
    --image gcr.io/PROJECT_ID/bouldering-api:dev \
    --region asia-northeast1 \
    --allow-unauthenticated

gcloud run deploy bouldering-api-prod \
    --image gcr.io/PROJECT_ID/bouldering-api:prod \
    --region asia-northeast1 \
    --allow-unauthenticated
```

#### 4. Firebase設定
```bash
# Firebaseプロジェクト作成
firebase projects:create bouldering-app-dev
firebase projects:create bouldering-app-prod

# Firebase設定ファイル生成
cd ios && firebase apps:sdkconfig ios
cd android && firebase apps:sdkconfig android

# FlutterFire CLI設定
flutterfire configure --project=bouldering-app-dev
flutterfire configure --project=bouldering-app-prod
```

### 環境変数設定

#### 開発環境（.env.dev）
```env
DATABASE_URL=postgresql://dev_user:dev_password_123@10.0.0.1:5432/bouldering_app_dev
GOOGLE_CLOUD_PROJECT=your-project-dev
GCS_BUCKET=your-app-media-dev
FIREBASE_PROJECT=bouldering-app-dev
API_BASE_URL=https://dev-api.your-domain.com/api/v1
ENVIRONMENT=development
```

#### 本番環境（.env.prod）
```env
DATABASE_URL=postgresql://prod_user:prod_secure_password_456@your-db.region.gcp.cloud.sql:5432/bouldering_app_prod
GOOGLE_CLOUD_PROJECT=your-project-prod
GCS_BUCKET=your-app-media-prod
FIREBASE_PROJECT=bouldering-app-prod
API_BASE_URL=https://api.your-domain.com/api/v1
ENVIRONMENT=production
```

### セキュリティ設定

#### 1. IAM権限設定
```bash
# サービスアカウント作成
gcloud iam service-accounts create bouldering-app-dev
gcloud iam service-accounts create bouldering-app-prod

# 必要な権限を付与
gcloud projects add-iam-policy-binding PROJECT_ID \
    --member="serviceAccount:bouldering-app-dev@PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/cloudsql.client"

gcloud projects add-iam-policy-binding PROJECT_ID \
    --member="serviceAccount:bouldering-app-dev@PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/storage.objectAdmin"
```

#### 2. ネットワークセキュリティ
```bash
# 許可IPの設定
gcloud sql instances patch bouldering-app-db \
    --authorized-networks=YOUR_APP_SERVER_IP/32
```

### デプロイ手順

#### 1. データベース初期化
```sql
-- テーブル作成スクリプトの実行
psql -h your-db-host -U username -d database_name -f create_tables.sql

-- 初期データの投入
psql -h your-db-host -U username -d database_name -f insert_initial_data.sql
```

#### 2. APIサーバーデプロイ
```bash
# Dockerイメージビルド
docker build -t gcr.io/PROJECT_ID/bouldering-api:latest .

# Container Registry にプッシュ
docker push gcr.io/PROJECT_ID/bouldering-api:latest

# Cloud Run にデプロイ
gcloud run deploy bouldering-api \
    --image gcr.io/PROJECT_ID/bouldering-api:latest \
    --region asia-northeast1
```

---

**注意**: このプロジェクトは既存アプリケーションのクリーンアーキテクチャ移行版です。上記のサーバー側実装をすべて完了してから、`lib_new/shared/config/environment_config.dart` の各設定値を実際の値に変更してください。