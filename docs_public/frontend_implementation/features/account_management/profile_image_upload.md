# プロフィール画像アップロード機能実装ドキュメント

## 概要

Clean Architecture + MVVM パターンに従ったプロフィール画像選択・アップロード機能の実装過程とトラブルシューティング。

## アーキテクチャ設計

### クリーンアーキテクチャ準拠

```
Presentation層 (profile_edit_page.dart)
    ↓
Domain層 (usecases)
    ↓ 
Infrastructure層 (services, repositories)
    ↓
External (Google Cloud Storage, image_picker)
```

### 責任分離
- **ImagePickerService**: デバイスからの画像選択
- **StorageService**: Cloud Storageへのアップロード
- **UserRepository**: ビジネスロジックとデータアクセスの抽象化
- **UpdateUserIconUseCase**: アイコン更新の業務処理

## 実装コンポーネント

### 1. ImagePickerService インターフェース

```dart
abstract class ImagePickerService {
  Future<File?> pickSingleImage();
  Future<List<File>> pickMultipleImages({int maxImages = 4});
  Future<File?> takePicture();
  Future<File?> showImageSourceDialog();
}
```

### 2. 実装クラス
- `ImagePickerServiceImpl`: image_picker パッケージを使用した実装
- `SelectProfileImageUseCase`: プロフィール画像選択のユースケース
- `UpdateUserIconUseCase`: アイコンURL更新のユースケース

### 3. 依存性注入パターンの統一

#### Pattern 2: 依存性注入を使用（推奨）
```dart
final selectProfileImageUseCaseProvider = Provider<SelectProfileImageUseCase>((ref) {
  final imagePickerService = ref.read(imagePickerServiceProvider);
  return SelectProfileImageUseCase(imagePickerService);
});
```

既存コードでPattern 1（直接provider import）とPattern 2が混在していたため、Pattern 2に統一。

## 画像アップロードフロー

### 処理ステップ
1. **画像選択** (`ImagePickerService`)
   - デバイスのギャラリーまたはカメラから画像選択
   - ファイル形式・サイズの検証

2. **Cloud Storage アップロード** (`StorageService`)
   - Google Cloud Storageへのファイルアップロード
   - 公開アクセス権限の設定

3. **データベース URL 更新** (`UserRepository`)
   - Cloud SQL上のユーザーテーブル更新
   - プロフィール画像URLの保存

4. **UI 更新** (`refreshUser()`)
   - プロバイダー状態の更新
   - 画面の再描画

## ディレクトリ構造と命名規則

### Cloud Storage ファイル名形式
```
{prefix}_{timestamp}_{hash}.{extension}
例: user_icon_1757003271521_ad392e14fa532eaf0ac18adfc84ac4ed4165d083decbad1134738d59ab3102f6.jpg
```

### ディレクトリ構造
```
bouldering-app-media-{env}/
├── users/{user_id}/
│   └── profile/
│       └── user_icon_{timestamp}_{hash}.{ext}
└── posts/
    └── post_media_{type}_{timestamp}_{hash}.{ext}
```

## 遭遇したエラーと対応

### 1. Clean Architecture 違反

**エラー**: View 層に image_picker を直接インポート

```dart
// ❌ 修正前: View に直接実装
import 'package:image_picker/image_picker.dart';

// ✅ 修正後: Service 層を通じて実装
final useCase = ref.read(selectProfileImageUseCaseProvider);
final image = await useCase.execute();
```

**対応**: ImagePickerService インターフェースを作成し、Clean Architecture の依存関係を修正

### 2. API エンドポイント不一致

**エラー**: Status 400 - 間違ったエンドポイントへのリクエスト

**原因**: フロントエンドが `/users/{user_id}` (ユーザー名更新) に送信していたが、正しくは `/users/{user_id}/icon-url` (アイコン更新)

```dart
// ❌ 修正前
endpoint: '/users/$userId',

// ✅ 修正後  
endpoint: '/users/$userId/icon-url',
```

### 3. Cloud Storage 権限エラー (Status 403)

**エラー**: `HTTP request failed, statusCode: 403` でアップロード後の画像にアクセスできない

**原因**: アップロードしたファイルに公開読み取り権限が設定されていない

```dart
// ファイルを公開アクセス可能に設定
await storage.objectAccessControls.insert(
  gcs.ObjectAccessControl()
    ..entity = 'allUsers'
    ..role = 'READER',
  bucketName,
  fileName,
);
```

### 4. パブリックアクセス防止エラー (Status 412)

**エラー**: `DetailedApiRequestError(status: 412, message: The member bindings allUsers and allAuthenticatedUsers are not allowed since public access prevention is enforced.)`

**原因**: Google Cloud Storage バケットで「パブリックアクセス防止」が有効で、プログラム的な公開権限設定がブロックされる

**対応**: Google Cloud Console での設定変更が必要

## Google Cloud Storage 設定変更

### 必要な設定変更

#### 1. パブリックアクセス防止の無効化
1. Google Cloud Console → Cloud Storage → ブラウザ
2. バケット `bouldering-app-media-dev` を選択
3. **権限** タブ → **パブリックアクセスの防止** 
4. **「パブリックアクセスを防止しない」** に変更
5. 保存

#### 2. バケットレベルでの公開設定
1. 同じ権限タブで **「プリンシパルを追加」**
2. 新しいプリンシパル: `allUsers`
3. ロール: `Storage Object Viewer`
4. 保存

#### 3. 設定確認方法
- バケット権限タブで「パブリック」表示を確認
- アップロード済みファイル URL に直接アクセスして画像表示を確認

## トラブルシューティング

### デバッグログの追加

問題特定のため、各層にデバッグログを追加：

```dart
// UseCase レベル
print('[UPDATE_USER_ICON_USECASE DEBUG] 開始: userId=$userId, imagePath=$imagePath');

// Repository レベル  
print('[USER_REPOSITORY DEBUG] uploadUserIcon開始: userId=$userId, imagePath=$imagePath');

// DataSource レベル
print('[USER_DATASOURCE DEBUG] uploadUserIcon開始: $imagePath');
print('[USER_DATASOURCE DEBUG] ファイル存在確認: ${imageFile.existsSync()}');
```

### よくある問題と解決方法

#### 1. アップロード後に画像が表示されない
- **確認項目**: Cloud Storage バケットの公開設定
- **解決方法**: バケット権限設定を確認・変更

#### 2. Status 400 エラー
- **確認項目**: API エンドポイントの正確性
- **解決方法**: バックエンドルーティング定義と照合

#### 3. Status 412 エラー  
- **確認項目**: バケットのパブリックアクセス防止設定
- **解決方法**: Google Cloud Console での設定変更

#### 4. ファイルが見つからない
- **確認項目**: ファイルパスの存在確認
- **デバッグ**: `File.existsSync()` でファイル存在を確認

## セキュリティ考慮事項

### 現在の実装 (開発環境)
- バケット全体を公開設定
- 全ユーザーが Storage Object Viewer ロール

### 本番環境での推奨事項
1. **署名付き URL** の使用
2. **Cloud CDN** での配信
3. **IAM 細分化** (特定リソースのみアクセス許可)
4. **有効期限付きトークン** の実装

## 今後の改善点

### 1. Pattern 1 から Pattern 2 への移行
既存の他のページで Pattern 1 を使用している箇所を Pattern 2 に統一する

### 2. エラーハンドリングの強化
- ネットワークエラー対応
- ファイルサイズ制限
- 形式チェック強化

### 3. パフォーマンス最適化
- 画像圧縮機能
- プログレスバー表示
- キャッシュ機能

## 学習ポイント

1. **Clean Architecture の重要性**: 適切な責任分離により、トラブルシューティングが容易
2. **インフラ設定の影響**: アプリコードだけでなく、クラウドサービス設定も重要
3. **デバッグログの価値**: 各層でのログにより問題箇所の特定が迅速に
4. **依存性注入パターンの統一**: コードの保守性と可読性の向上

---
*最終更新: 2025-09-17*
*実装完了度: 100%*