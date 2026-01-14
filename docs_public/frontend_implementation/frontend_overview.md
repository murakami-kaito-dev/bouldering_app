# 🧗‍♀️ ボルダリングアプリ

## 概要

ボルダリング愛好者のためのソーシャルプラットフォームアプリケーション。全国のボルダリングジム情報を検索・共有し、クライミング体験を記録・発信できるコミュニティアプリです。

### 主要機能
- 🏢 **ジム検索・発見**: 全国のボルダリングジムを地図・条件検索
- 📝 **体験共有**: クライミング記録を写真付きで投稿
- 👥 **コミュニティ**: ユーザーフォロー・ジムのお気に入り登録
- 🗺️ **地図連携**: Google Maps統合による位置情報サービス
- 🔐 **認証**: Firebase Authenticationによるセキュアな認証

### 開発状況
- **実装完成度**: 95%（2025年9月時点）
- **リリース準備**: App Store配信申請準備中

---

## 🏗 アーキテクチャ

### Clean Architecture + MVVM

本アプリケーションは**Clean Architecture**原則に基づき、**MVVM**パターンを採用した4層構造で実装されています。

```
┌─────────────────────────────────────────────────┐
│                  Presentation層                  │
│         (UI Components + State Management)       │
│                    ↓依存↑                        │
├─────────────────────────────────────────────────┤
│                   Domain層                       │
│        (Business Logic + Entities)               │
│                    ↓依存↑                        │
├─────────────────────────────────────────────────┤
│                Infrastructure層                  │
│         (External Services + Data Access)        │
│                    ↓依存↑                        │
├─────────────────────────────────────────────────┤
│                   Shared層                       │
│          (Utilities + Constants + Config)        │
└─────────────────────────────────────────────────┘
```

### 層の責務

#### 1. **Presentation層** (`lib/presentation/`)
- **責務**: ユーザーインターフェースと状態管理
- **構成要素**:
  - `pages/`: 画面コンポーネント
  - `components/`: 再利用可能UIコンポーネント
  - `providers/`: Riverpod状態管理
- **技術**: Flutter Widgets, Riverpod

#### 2. **Domain層** (`lib/domain/`)
- **責務**: ビジネスロジックとビジネスルール
- **構成要素**:
  - `entities/`: ビジネスエンティティ
  - `repositories/`: リポジトリインターフェース
  - `usecases/`: ユースケース（ビジネスロジック）
  - `exceptions/`: ドメイン例外
- **特徴**: 外部依存なし、純粋なDartコード

#### 3. **Infrastructure層** (`lib/infrastructure/`)
- **責務**: 外部システムとの連携
- **構成要素**:
  - `datasources/`: API通信・データ取得
  - `repositories/`: リポジトリ実装
  - `services/`: 外部サービス統合
- **連携システム**: Firebase, Cloud Run API, Google Maps

#### 4. **Shared層** (`lib/shared/`)
- **責務**: 共通機能・ユーティリティ
- **構成要素**:
  - `config/`: 環境設定
  - `constants/`: 定数定義
  - `utils/`: ユーティリティ関数
  - `widgets/`: 共通ウィジェット

---

## 🛠 技術スタック

### フロントエンド
| 技術 | バージョン | 用途 |
|------|----------|------|
| **Flutter** | 3.24.3+ | UIフレームワーク |
| **Dart** | 3.5.3+ | プログラミング言語 |
| **Riverpod** | 2.6.0+ | 状態管理 |
| **GoRouter** | - | ルーティング |
| **Google Maps Flutter** | 2.10.1+ | 地図表示 |

### バックエンド・インフラ
| サービス | 用途 |
|---------|------|
| **Google Cloud Run** | APIサーバーホスティング |
| **Cloud SQL (PostgreSQL)** | データベース |
| **Cloud Storage** | 画像・動画ストレージ |
| **Cloud Tasks** | 非同期タスク処理 |
| **Firebase Authentication** | ユーザー認証 |
| **Secret Manager** | 機密情報管理 |

---

## 📁 ディレクトリ構造

```
[your_app_name]/
├── lib/
│   ├── domain/                    # ビジネスロジック層
│   │   ├── entities/              # エンティティ
│   │   │   ├── user.dart
│   │   │   ├── gym.dart
│   │   │   └── tweet.dart
│   │   ├── repositories/          # リポジトリインターフェース
│   │   │   ├── user_repository.dart
│   │   │   ├── gym_repository.dart
│   │   │   └── tweet_repository.dart
│   │   ├── usecases/              # ユースケース
│   │   │   ├── auth_usecases.dart
│   │   │   ├── gym_usecases.dart
│   │   │   └── tweet_usecases.dart
│   │   ├── exceptions/            # カスタム例外
│   │   └── services/              # サービスインターフェース
│   │
│   ├── infrastructure/            # データアクセス層
│   │   ├── datasources/           # データソース
│   │   │   ├── remote/
│   │   │   │   ├── auth_datasource.dart
│   │   │   │   └── api_client.dart
│   │   │   └── local/
│   │   ├── repositories/          # リポジトリ実装
│   │   └── services/              # 外部サービス実装
│   │       ├── firebase_auth_service.dart
│   │       └── google_maps_service.dart
│   │
│   ├── presentation/              # プレゼンテーション層
│   │   ├── pages/                 # 画面
│   │   │   ├── home_page.dart
│   │   │   ├── gym_detail_page.dart
│   │   │   ├── tweet_post_page.dart
│   │   │   ├── profile_page.dart
│   │   │   └── login_page.dart
│   │   ├── components/            # UIコンポーネント
│   │   │   ├── common/
│   │   │   ├── gym/
│   │   │   ├── tweet/
│   │   │   └── user/
│   │   └── providers/             # 状態管理
│   │       ├── auth_provider.dart
│   │       ├── gym_provider.dart
│   │       ├── tweet_provider.dart
│   │       └── dependency_injection.dart
│   │
│   ├── shared/                    # 共通機能
│   │   ├── config/                # 環境設定
│   │   │   ├── environment_config.dart
│   │   │   ├── firebase_options_dev.dart
│   │   │   └── firebase_options_prod.dart
│   │   ├── constants/             # 定数
│   │   │   ├── app_colors.dart
│   │   │   ├── app_routes.dart
│   │   │   └── api_endpoints.dart
│   │   └── utils/                 # ユーティリティ
│   │       ├── navigation_helper.dart
│   │       ├── date_formatter.dart
│   │       └── validators.dart
│   │
│   ├── main_dev.dart              # 開発版エントリーポイント
│   └── main_prod.dart             # 本番版エントリーポイント
│
├── ios/                           # iOS固有設定
│   ├── Runner/
│   │   ├── Info.plist
│   │   ├── Config.plist          # API キー設定
│   │   └── GoogleService-Info.plist
│   └── Podfile
│
├── android/                       # Android固有設定
├── assets/                        # アセット
│   ├── keys/                      # APIキー（Git管理外）
│   └── images/
├── docs/                          # ドキュメント
├── backend/                       # バックエンドコード（Node.js/TypeScript）
└── pubspec.yaml                   # 依存関係定義
```

---

## 🎯 主要機能と実装

### 1. ユーザー認証
- **Firebase Authentication**によるメール/パスワード認証
- 新規登録・ログイン・ログアウト
- パスワードリセット機能
- 認証状態の永続化

### 2. ジム機能
- **ジム検索**: 名前・地域・都道府県での検索
- **ジム詳細**: 営業時間・料金・設備情報表示
- **地図表示**: Google Maps統合
- **イキタイ機能**: お気に入りジム登録

### 3. ツイート（投稿）機能
- **投稿作成**: テキスト・画像・訪問日記録
- **タイムライン**: フォローユーザーの投稿表示
- **いいね・ブックマーク**: エンゲージメント機能
- **画像アップロード**: Cloud Storage連携

### 4. プロフィール機能
- **プロフィール編集**: アイコン・自己紹介
- **ホームジム設定**: よく行くジムの登録
- **フォロー機能**: ユーザー間の繋がり
- **統計表示**: 投稿数・フォロワー数

---

## 🔧 環境構成

### 環境分離

本アプリケーションは**開発環境**と**本番環境**を完全に分離しています。

| 環境 | エントリーポイント | Bundle ID | Firebase Project |
|------|------------------|-----------|-----------------|
| **開発** | `main_dev.dart` | `com.yourcompany.yourapp.dev` | `[YOUR_FIREBASE_PROJECT_DEV]` |
| **本番** | `main_prod.dart` | `com.yourcompany.yourapp` | `[YOUR_FIREBASE_PROJECT_PROD]` |

### 環境変数管理

```dart
// lib/shared/config/environment_config.dart
class EnvironmentConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '[YOUR_API_BASE_URL_DEV]',
  );

  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'dev',
  );
}
```

---

## 🚀 ビルド・実行

### 開発環境

```bash
# 依存関係インストール
flutter pub get

# iOS開発版実行
flutter run --flavor "Runner Dev" \
  --dart-define=ENVIRONMENT=dev \
  --target lib/main_dev.dart

# または事前設定済みエイリアス使用
fdev  # 開発版実行
```

### 本番環境

```bash
# iOS本番版ビルド
flutter build ios --flavor "Runner Prod" \
  --dart-define=ENVIRONMENT=prod \
  --target lib/main_prod.dart \
  --release

# または事前設定済みエイリアス使用
fbprod  # 本番版ビルド
```

---

## 📝 開発ガイドライン

### コーディング規約

1. **依存関係の方向**
   - 外側の層から内側の層への依存のみ許可
   - Domain層は他層に依存しない

2. **命名規則**
   - ファイル名: `snake_case.dart`
   - クラス名: `PascalCase`
   - 変数・関数: `camelCase`

3. **状態管理**
   - Riverpodプロバイダーによる状態管理
   - ViewModelパターンの採用

## 🏛 アーキテクチャ詳細仕様

### 層別責任分担ガイド

#### Domain層（ビジネスロジック）
- **役割**: ビジネスルールとロジックの定義
- **依存関係**: 他の層に依存しない
- **主要ファイル**:
  - `entities/`: エンティティ（ビジネスオブジェクト）
  - `repositories/`: リポジトリインターフェース
  - `usecases/`: ユースケース（ビジネスロジック）
  - `services/`: サービスインターフェース

#### Infrastructure層（外部システムとの接続）
- **役割**: 外部システム（Firebase、Cloud SQL）との通信
- **依存関係**: Domain層に依存
- **主要ファイル**:
  - `datasources/`: データソース実装
  - `repositories/`: リポジトリ実装
  - `services/`: サービス実装（Firebase Auth等）

#### Presentation層（UI・状態管理）
- **役割**: UI表示と状態管理
- **依存関係**: Domain層に依存
- **主要ファイル**:
  - `pages/`: 画面
  - `components/`: UIコンポーネント
  - `providers/`: 状態管理（Riverpod）

### 型定義ポリシー

#### ID型の変換ルール
1. **Domain層**: すべてのIDは`int`型で定義
2. **Presentation層**: ルーティングやUIでは`String`型で扱う
3. **Infrastructure層**: APIとの通信時は`String`型に変換

```dart
// エンティティ定義（Domain層）
class Gym {
  final int id;  // int型で定義
  final String name;
}

// ページ遷移（Presentation層）
class FacilityInfoPage extends StatelessWidget {
  final String gymId;  // String型で受け取る

  void _loadData() {
    final id = int.parse(gymId);  // 使用時にint変換
    ref.read(gymDetailProvider.notifier).loadGymDetail(id);
  }
}

// API通信（Infrastructure層）
Future<void> createTweet(Tweet tweet) async {
  final body = {
    'gym_id': tweet.gymId.toString(),  // String変換してAPI送信
    'user_id': tweet.userId.toString(),
  };
}
```

#### 型変換のエラーハンドリング
```dart
// 安全な型変換ユーティリティ
class TypeConverter {
  static int? toInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  static String toString(dynamic value) {
    return value.toString();
  }
}
```

### ツイート機能アーキテクチャ

#### 5種類のツイート表示機能

| 種類 | 説明 | 使用場所 | ログイン要否 | Provider |
|------|------|----------|--------------|----------|
| **総合ツイート** | 全ユーザーの投稿を最新順表示 | ボル活タブ > みんなのボル活 | 不要 | `generalTweetsProvider` |
| **お気に入りユーザーツイート** | お気に入り登録ユーザーの投稿 | ボル活タブ > お気に入り | 必要 | `favoriteUserTweetsProvider` |
| **自分のツイート** | ログインユーザー自身の投稿 | マイページ > ボル活タブ | 必要 | `myTweetsProvider` |
| **施設ツイート** | 特定ジムでの投稿のみ表示 | ジム詳細ページ > ボル活タブ | 不要 | `gymTweetsProvider` |
| **他ユーザーツイート** | 特定の他ユーザーの投稿 | 他ユーザープロフィール | 不要 | `otherUserTweetsProvider` |

#### 共通機能
- **ページネーション**: 20件ずつの無限スクロール
- **プルリフレッシュ**: 下に引っ張って最新データ取得
- **エラーハンドリング**: エラー状態の管理と表示
- **ローディング状態**: 初回読み込みと追加読み込みの区別

#### 状態管理パターン
```dart
// 基本的な状態構造
class XxxTweetsState {
  final List<Tweet> tweets;      // ツイート一覧
  final bool isLoading;          // ローディング中フラグ
  final bool hasMore;            // 追加データ有無
  final bool isFirstFetch;       // 初回取得フラグ
  final String? error;           // エラーメッセージ
}

// Family Providerの使用例
final gymTweetsProvider = StateNotifierProvider.family<
    GymTweetsNotifier, GymTweetsState, int>((ref, gymId) =>
    GymTweetsNotifier(ref.read(gymUseCasesProvider), gymId));
```

#### 投稿機能の制限事項
- **文字数制限**: ツイート内容は0-400文字
- **画像制限**: 最大4枚まで
- **必須項目**: ジム選択と訪問日は必須
- **同時投稿制限**: 動画と画像の同時投稿は不可

### 新機能追加フロー

1. **Domain層**: エンティティ・ユースケース定義
2. **Infrastructure層**: データソース・リポジトリ実装
3. **Presentation層**: Provider・UI実装
4. **ルーティング**: ナビゲーション設定

### 認証・アカウント管理の責任分担

#### AuthProvider（auth_provider.dart）
**責任**: 認証フローの全体調整
- Firebase Auth再認証処理（セキュリティ制約上、ここでしか実装できない）
- 認証状態の管理
- 各種認証処理の呼び出しと調整

#### UserProvider（user_provider.dart）
**責任**: ユーザー状態管理
- ユーザー情報の状態管理
- Cloud SQLのユーザーデータ操作
- ユーザー情報の更新処理

#### データの二重管理
- **Firebase Auth**: 認証情報（メール、パスワード）
- **Cloud SQL**: ユーザー情報（メール、プロフィール情報）
- **注意**: メールアドレスは両方で管理するため、両方の更新が必要

### テスト戦略

```bash
# ユニットテスト
flutter test

# ウィジェットテスト
flutter test test/widget/

# 統合テスト
flutter test integration_test/
```

---

## 📱 画面一覧

| 画面名 | ファイルパス | 機能概要 |
|--------|------------|----------|
| **ホーム** | `pages/home_page.dart` | タブナビゲーション・人気ジム表示 |
| **ジム検索** | `pages/gym_search_page.dart` | ジム検索・フィルタリング |
| **ジム詳細** | `pages/gym_detail_page.dart` | ジム情報・投稿一覧 |
| **地図** | `pages/gym_map_page.dart` | Google Maps連携 |
| **投稿作成** | `pages/tweet_post_page.dart` | ツイート投稿 |
| **投稿詳細** | `pages/tweet_detail_page.dart` | 個別投稿表示 |
| **プロフィール** | `pages/profile_page.dart` | ユーザー情報表示 |
| **プロフィール編集** | `pages/profile_edit_page.dart` | プロフィール更新 |
| **ログイン** | `pages/login_page.dart` | 認証画面 |
| **設定** | `pages/settings_page.dart` | アプリ設定 |

---

## 🔐 セキュリティ

### 認証・認可
- Firebase Authenticationによるトークンベース認証
- APIアクセス時のIDトークン検証
- ユーザー権限による機能制限

### データ保護
- HTTPS通信の強制
- Secret Managerによる機密情報管理
- 環境変数による設定分離

---

## 📊 データベース設計

### 主要テーブル

```sql
-- ユーザー
users (
  user_id VARCHAR(28) PRIMARY KEY,
  user_name VARCHAR(255),
  email VARCHAR(320),
  created_at TIMESTAMP
)

-- ジム
gyms (
  gym_id INTEGER PRIMARY KEY,
  gym_name VARCHAR(255),
  prefecture VARCHAR(20),
  latitude NUMERIC(10,8),
  longitude NUMERIC(11,8)
)

-- ツイート
tweets (
  tweet_id INTEGER PRIMARY KEY,
  user_id VARCHAR(28),
  gym_id INTEGER,
  tweet_contents TEXT,
  tweeted_date TIMESTAMP
)
```

---

## 🚢 デプロイ

### バックエンド（Cloud Run）
- Docker コンテナによるデプロイ
- Cloud SQL接続設定
- 環境変数による設定管理

### フロントエンド（App Store）
- Archive作成・署名
- App Store Connect提出
- TestFlight配信

詳細は以下のドキュメント参照：
- [`App Store配信申請手順書.md`](./App Store配信申請手順書.md)
- [`Google Cloud 環境構築手順.txt`](./Google Cloud 環境構築手順.txt)

---

## 📚 関連ドキュメント

- [App Store配信申請手順書](./App Store配信申請手順書.md)
- [iPhone実機ビルド手順書](./iPhone実機ビルド手順書（開発版）.md)
- [実装完了報告](./docs/implementation/IMPLEMENTATION_SUMMARY.md)
- [API仕様書](./docs/api/API_INTERFACE_SPECIFICATION.md)

---

## 🤝 コントリビューション

新規開発者向けセットアップ：

1. リポジトリクローン
2. Flutter環境構築（3.24.3以上）
3. 依存関係インストール: `flutter pub get`
4. Firebase設定ファイル配置
5. 開発版起動: `flutter run -t lib/main_dev.dart`

---

## 📄 ライセンス

プロプライエタリソフトウェア - 無断複製・配布禁止

---

*最終更新: 2025年9月*
