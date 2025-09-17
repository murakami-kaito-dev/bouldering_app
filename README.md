# 🧗‍♀️ ボルダリングアプリ

全国のボルダリングジムを検索・共有し、クライミング体験を記録できるソーシャルプラットフォームアプリケーションです。

## 📱 アプリケーション概要

### コンセプト
日本のボルダリング愛好者のためのコミュニティアプリとして、ジム情報の共有、クライミング記録の投稿、ユーザー同士の交流を実現します。

### 主要機能

#### 🏢 ジム機能
- **全国ジム検索** - 地域や条件でボルダリングジムを検索
- **地図表示** - Google Maps連携による位置情報サービス
- **詳細情報閲覧** - 営業時間、料金、設備情報など
- **お気に入り登録** - 行きたいジムをブックマーク

#### 📝 活動記録機能
- **クライミング投稿** - 写真付きで活動を記録
- **タイムライン** - フォローユーザーの活動をリアルタイム表示
- **いいね・コメント** - 投稿への反応とコミュニケーション

#### 👥 ソーシャル機能
- **ユーザーフォロー** - お気に入りクライマーをフォロー
- **プロフィール** - 実績やお気に入りジムを公開
- **コミュニティ** - 同じジムを利用するユーザーとの交流

#### 🔐 認証・セキュリティ
- **Firebase Authentication** - セキュアなユーザー認証
- **プロフィール管理** - アバター画像、自己紹介の編集
- **プライバシー設定** - 公開範囲の制御

## 🏗️ アーキテクチャ

### 設計原則

本アプリケーションは以下の設計原則に基づいて実装されています：

- **クリーンアーキテクチャ** - 依存関係の明確な分離と保守性の向上
- **MVVMパターン** - UI とビジネスロジックの分離
- **RESTful API** - 標準的なWeb API設計

### レイヤー構造

```
┌──────────────────────────────────────────┐
│         Presentation層 (UI)               │
│  Pages / Components / Providers(MVVM)     │
├──────────────────────────────────────────┤
│           Domain層 (ビジネス)              │
│  Entities / UseCases / Repositories       │
├──────────────────────────────────────────┤
│      Infrastructure層 (データアクセス)      │
│  DataSources / Repository実装 / Services  │
├──────────────────────────────────────────┤
│          Shared層 (共通機能)               │
│  Config / Constants / Utils / Widgets     │
└──────────────────────────────────────────┘
```

### フロントエンド構成

```
lib/
├── presentation/          # UI層（MVVMのView + ViewModel）
│   ├── pages/            # 画面コンポーネント
│   │   ├── home_page.dart         # ホーム画面
│   │   ├── gym_map_page.dart      # ジム地図画面
│   │   ├── activity_post_page.dart # 活動投稿画面
│   │   └── my_page.dart           # マイページ
│   ├── components/       # 再利用可能UIコンポーネント
│   │   ├── common/       # 共通コンポーネント
│   │   ├── gym/          # ジム関連
│   │   ├── tweet/        # 投稿関連
│   │   └── user/         # ユーザー関連
│   └── providers/        # Riverpod状態管理（ViewModel）
│       ├── auth_provider.dart     # 認証状態管理
│       ├── gym_provider.dart      # ジム情報管理
│       └── tweet_provider.dart    # 投稿管理
├── domain/               # ビジネスロジック層
│   ├── entities/         # ビジネスエンティティ
│   ├── repositories/     # リポジトリインターフェース
│   ├── usecases/         # ユースケース
│   └── exceptions/       # ビジネス例外
├── infrastructure/       # データ層
│   ├── datasources/      # API通信・データソース
│   ├── repositories/     # リポジトリ実装
│   └── services/         # 外部サービス連携
└── shared/              # 共通機能
    ├── config/          # 環境設定
    ├── constants/       # 定数定義
    └── utils/           # ユーティリティ

```

### バックエンド構成

```
backend/src/
├── routes/              # RESTful APIエンドポイント
│   ├── users.ts        # /api/users
│   ├── tweets.ts       # /api/tweets
│   ├── gyms.ts         # /api/gyms
│   └── internal_tasks.ts # 内部タスク処理
├── domain/              # ドメイン層（Clean Architecture）
│   ├── repositories/    # リポジトリインターフェース
│   ├── services/        # ドメインサービス
│   └── events/         # ドメインイベント
├── infrastructure/      # インフラストラクチャ層
│   ├── repositories/    # PostgreSQL実装
│   ├── events/         # イベントバス
│   └── handlers/       # イベントハンドラー
├── services/           # アプリケーションサービス
├── middleware/         # Express ミドルウェア
├── config/             # 設定ファイル
└── utils/              # ユーティリティ
```

## 🛠️ 技術スタック

### フロントエンド
| 技術 | バージョン | 用途 |
|------|----------|------|
| **Flutter** | 3.5.3+ | クロスプラットフォーム開発フレームワーク |
| **Dart** | 3.5.3+ | プログラミング言語 |
| **Riverpod** | 2.6.0+ | 状態管理（MVVMのViewModel実装） |
| **Firebase Auth** | 5.3.4+ | ユーザー認証 |
| **Google Maps Flutter** | 2.10.1+ | 地図表示機能 |
| **GoRouter** | - | 画面遷移管理 |
| **Image Picker** | 1.1.2+ | 写真撮影・選択 |

### バックエンド
| 技術 | バージョン | 用途 |
|------|----------|------|
| **Node.js** | 18.0.0+ | JavaScript実行環境 |
| **TypeScript** | 5.3.3+ | 型安全な開発 |
| **Express.js** | 4.18.2+ | RESTful APIフレームワーク |
| **PostgreSQL** | 15 | リレーショナルデータベース |
| **Firebase Admin SDK** | 11.11.1+ | 認証トークン検証 |

### インフラストラクチャ（Google Cloud Platform）
| サービス | 用途 |
|---------|------|
| **Cloud Run** | コンテナ化されたAPIサーバーのホスティング |
| **Cloud SQL** | マネージドPostgreSQLデータベース |
| **Cloud Storage** | 画像・メディアファイルの保存 |
| **Cloud Tasks** | 非同期タスク処理（画像削除など） |
| **Secret Manager** | APIキー・パスワードの安全な管理 |
| **Artifact Registry** | Dockerイメージの管理 |

## 🚀 開発環境セットアップ

### 前提条件

- Flutter SDK 3.5.3以上
- Node.js 18.0.0以上
- PostgreSQL（ローカル開発用）
- Xcode 13以上（iOS開発）
- Android Studio（Android開発）

### フロントエンド セットアップ

```bash
# リポジトリのクローン
git clone [リポジトリURL]
cd bouldering_app

# Flutter依存関係のインストール
flutter pub get

# コード生成（必要に応じて）
flutter packages pub run build_runner build

# 開発環境での実行
flutter run -t lib/main_dev.dart

# 本番環境での実行
flutter run -t lib/main_prod.dart
```

### バックエンド セットアップ

```bash
# バックエンドディレクトリへ移動
cd backend

# Node.js依存関係のインストール
npm install

# TypeScriptのビルド
npm run build

# 開発サーバーの起動
npm run dev

# 本番サーバーの起動
npm start
```

## 📦 プロジェクト構成

```
bouldering_app/
├── lib/                 # Flutterアプリケーションソース
├── backend/             # Node.js APIサーバー
├── ios/                 # iOS固有設定
├── android/             # Android固有設定
├── assets/              # 画像・アイコンリソース
├── test/                # テストコード
├── docs/                # ドキュメント（非公開）
└── README.md           # このファイル
```

## 🔄 API エンドポイント

### RESTful API 設計

| エンドポイント | メソッド | 説明 |
|-------------|---------|------|
| `/api/users` | GET/POST/PUT/DELETE | ユーザー情報の管理 |
| `/api/tweets` | GET/POST/PUT/DELETE | 投稿（クライミング記録）の管理 |
| `/api/gyms` | GET | ジム情報の取得・検索 |
| `/api/gyms/:id/favorites` | POST/DELETE | ジムのお気に入り登録 |
| `/api/users/:id/follow` | POST/DELETE | ユーザーフォロー機能 |
| `/health` | GET | ヘルスチェック |

## 🔒 セキュリティ

- **Firebase Authentication** によるトークンベース認証
- **HTTPS通信** の強制
- **環境変数** による機密情報の管理
- **Google Cloud Secret Manager** によるシークレット管理
- **入力値検証** とサニタイゼーション
- **CORS設定** による適切なアクセス制御

## 📱 画面構成

### 主要画面
- **ホーム画面** - タイムライン表示
- **ジム検索画面** - 条件検索・一覧表示
- **ジムマップ画面** - 地図上でジムを探索
- **活動投稿画面** - クライミング記録の投稿
- **マイページ** - プロフィール・設定管理
- **ユーザー詳細画面** - 他ユーザーのプロフィール閲覧

## 🎨 デザイン原則

- **Material Design 3** に準拠したUI
- **レスポンシブデザイン** による各種画面サイズ対応
- **ダークモード** 対応（実装予定）
- **アクセシビリティ** 考慮

## 🧪 テスト

```bash
# Flutterユニットテスト
flutter test

# Flutterインテグレーションテスト
flutter drive --target=test_driver/app.dart

# バックエンドテスト
cd backend && npm test

# リント実行
flutter analyze
cd backend && npm run lint
```

## 📈 パフォーマンス最適化

- **画像の遅延読み込み** とキャッシング
- **ページネーション** による大量データの効率的な取得
- **SQLiteローカルキャッシュ** によるオフライン対応
- **Cloud CDN** による静的コンテンツの配信（実装予定）

## 🚢 デプロイメント

### iOS
```bash
# ビルド
flutter build ios --flavor [Runner Dev/Runner Prod] --dart-define=ENVIRONMENT=[dev/prod]

# App Store Connect へのアップロード
# Xcodeまたはfastlaneを使用
```

### Android
```bash
# APKビルド
flutter build apk --flavor [dev/prod] --dart-define=ENVIRONMENT=[dev/prod]

# AABビルド（Google Play Store用）
flutter build appbundle --flavor [dev/prod] --dart-define=ENVIRONMENT=[dev/prod]
```

### バックエンド（Cloud Run）
```bash
# Dockerイメージのビルド
docker build --platform linux/amd64 -t [IMAGE_TAG] .

# Cloud Runへのデプロイ
gcloud run deploy [SERVICE_NAME] --image [IMAGE_TAG]
```

## 📊 プロジェクト状況

### 開発進捗
- **フロントエンド**: 95% 完成
- **バックエンド**: 90% 完成
- **インフラ構築**: 85% 完成
- **ドキュメント**: 95% 完成

### 実装済み機能
✅ ユーザー認証（Firebase Authentication）
✅ ジム検索・地図表示
✅ 活動投稿・タイムライン
✅ ユーザーフォロー機能
✅ 画像アップロード
✅ プロフィール管理
✅ お気に入り機能

### 今後の実装予定
- プッシュ通知
- ダークモード対応
- オフライン完全対応
- AI による難易度推定機能
- 退会機能
- スレッド会話機能
- コンペティション機能

## 📄 ライセンス

ISCライセンス - 詳細は package.json を参照

## 👥 開発チーム

日本のボルダリング愛好者のために開発されたコミュニティアプリケーション

---

**注記**: 本READMEは公開用のドキュメントです。機密情報（APIキー、データベース接続情報等）は含まれていません。開発に必要な詳細設定については、別途提供される開発者向けドキュメントを参照してください。
