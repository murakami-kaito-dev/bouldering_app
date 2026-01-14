# Firebase Authentication 実装ドキュメント

## 概要

MockAuthServiceからFirebase Authenticationへの移行実装。実際のFirebaseプロジェクトを使用した認証機能の導入。

## アーキテクチャ設計

### クリーンアーキテクチャ準拠

```
Presentation層 (auth_provider.dart)
    ↓
Domain層 (auth_service.dart - インターフェース)
    ↓
Infrastructure層 (firebase_auth_service.dart - 実装)
    ↓
External (Firebase Authentication)
```

### MVVM パターン
- **View**: Login/SignUpページ（UI表示・ユーザー入力）
- **ViewModel**: AuthProvider（認証状態管理・ビジネスロジック）
- **Model**: Firebase User、認証状態

## 実装内容

### 1. 新規作成ファイル

#### AuthService抽象インターフェース
**ファイル**: `/lib/domain/services/auth_service.dart`
- 認証サービスの抽象インターフェース
- Firebase Authenticationをラップ
- クリーンアーキテクチャの原則に従った抽象化

```dart
abstract class AuthService {
  // 認証状態の監視
  Stream<User?> authStateChanges();
  Stream<User?> userChanges();
  
  // 認証機能
  Future<UserCredential> signInWithEmailAndPassword(String email, String password);
  Future<UserCredential> createUserWithEmailAndPassword(String email, String password);
  Future<void> signOut();
  
  // ユーザー管理
  Future<void> updateEmail(String email);
  Future<void> updatePassword(String password);
  Future<void> deleteUser();
  
  // 再認証
  Future<void> reauthenticateWithCredential(AuthCredential credential);
  
  // 現在のユーザー
  User? get currentUser;
}
```

#### Firebase認証サービス実装
**ファイル**: `/lib/infrastructure/services/firebase_auth_service.dart`
- Firebase Authenticationの具体的な実装
- AuthServiceインターフェースを実装
- エラーハンドリングとユーザー管理

```dart
class FirebaseAuthService implements AuthService {
  final FirebaseAuth _firebaseAuth;
  
  FirebaseAuthService() : _firebaseAuth = FirebaseAuth.instance;
  
  @override
  Stream<User?> authStateChanges() => _firebaseAuth.authStateChanges();
  
  @override
  Stream<User?> userChanges() => _firebaseAuth.userChanges();
  
  @override
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) {
    return _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
  }
  
  // その他のメソッド実装...
}
```

### 2. 更新ファイル

#### AuthProvider（認証状態管理）
**ファイル**: `/lib/presentation/providers/auth_provider.dart`

**変更前**: MockAuthService使用
```dart
import '../../infrastructure/services/mock_auth_service.dart';
final MockAuthService _auth = MockAuthService();
```

**変更後**: Firebase Authentication使用
```dart
import 'package:firebase_auth/firebase_auth.dart';
final FirebaseAuth _auth = FirebaseAuth.instance;
```

#### 主要な変更点
- FirebaseAuthExceptionによるエラーハンドリング
- authStateChanges()による認証状態の監視
- null安全性対応（user!.uid）

#### 依存性注入設定
**ファイル**: `/lib/presentation/providers/dependency_injection.dart`
```dart
final authServiceProvider = Provider<AuthService>((ref) {
  return FirebaseAuthService();
});
```

#### アプリ初期化
**ファイル**: `/lib/main_dev.dart`
```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

### 3. 設定ファイル配置

#### 開発用Firebase設定
**ファイル**: `/lib/shared/config/firebase_options_dev.dart`
- 開発用Firebaseプロジェクトの設定
- FlutterFire CLIで自動生成

## 実装機能

### 実装済み機能
- ✅ メールアドレス/パスワードによるログイン
- ✅ 新規ユーザー登録
- ✅ ログアウト
- ✅ 認証状態の永続化
- ✅ 自動ログイン（アプリ再起動時）
- ✅ メールアドレス変更
- ✅ パスワード変更
- ✅ アカウント削除
- ✅ 再認証機能

### 今後実装可能な機能
- パスワードリセット（メール送信）
- メール認証確認
- ソーシャルログイン（Google, Apple等）
- 二要素認証
- 電話番号認証

## エラーハンドリング

### Firebase Authenticationエラーコード対応
```dart
try {
  // 認証処理
} on FirebaseAuthException catch (e) {
  switch (e.code) {
    case 'email-already-in-use':
      return 'このメールアドレスは既に使用されています';
    case 'invalid-email':
      return 'メールアドレスの形式が正しくありません';
    case 'user-not-found':
      return 'ユーザーが見つかりません';
    case 'wrong-password':
      return 'パスワードが間違っています';
    case 'weak-password':
      return 'パスワードが弱すぎます';
    case 'network-request-failed':
      return 'ネットワークエラーが発生しました';
    default:
      return '認証エラーが発生しました: ${e.message}';
  }
}
```

## セキュリティ要件

### パスワード要件
```dart
bool _isStrongPassword(String password) {
  final RegExp strongPasswordRegExp =
      RegExp(r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)[A-Za-z\d@\$!%*?&]{8,}$');
  return strongPasswordRegExp.hasMatch(password);
}
```
- 最低8文字
- 大文字・小文字・数字を含む
- 特殊文字の使用推奨

### 再認証セキュリティ
- アカウント削除前の再認証必須
- メールアドレス変更前の再認証必須
- パスワード変更前の再認証必須

## 環境設定

### 開発環境
- **プロジェクト**: `bouldering-app-dev`
- **設定ファイル**: `firebase_options_dev.dart`
- **起動コマンド**: `flutter run -t lib/main_dev.dart`

### 本番環境（将来）
- **プロジェクト**: `bouldering-app-prod`
- **設定ファイル**: `firebase_options_prod.dart`
- **起動コマンド**: `flutter run -t lib/main_prod.dart --release`

## 認証状態管理

### AuthProviderの設計
```dart
class AuthNotifier extends StateNotifier<bool> {
  bool _isSigningUp = false; // 新規登録処理中フラグ
  
  void _checkLoginStatus() {
    // 認証状態の変更を監視
    _authService.authStateChanges().listen((User? user) {
      state = user != null;
      
      if (user == null) {
        ref.read(userProvider.notifier).logout();
      } else {
        if (!_isSigningUp) {
          ref.read(userProvider.notifier).login(user.uid);
        }
      }
    });
    
    // ユーザー情報の変更を監視（メールアドレス自動同期用）
    _authService.userChanges().listen((user) async {
      if (user != null) {
        await _syncEmailWithCloudSQL(user);
      }
    });
  }
}
```

## Firebase Console設定

### 必要な設定
1. **Authentication有効化**
   - Firebase Console → Authentication
   - Sign-in method → Email/Password を有効化

2. **セキュリティルール**
   - 適切なセキュリティルールの設定
   - 不正アクセスの防止

3. **プロジェクト設定**
   - iOS: `GoogleService-Info.plist` の配置
   - Android: `google-services.json` の配置

## テスト方法

### 基本機能テスト
```bash
# 開発環境でアプリ起動
flutter run -t lib/main_dev.dart
```

1. **新規登録テスト**
   - マイページタブを選択
   - 「登録・ログイン」ボタンをタップ
   - メールアドレスとパスワードを入力
   - 「新規登録」をタップ

2. **ログインテスト**
   - 登録済みのメールアドレスとパスワードでログイン
   - ログイン状態が維持されることを確認

3. **永続化テスト**
   - ログイン後、アプリを完全に終了
   - 再起動してマイページを確認
   - ログイン状態が維持されていることを確認

### 高度な機能テスト
1. **メールアドレス変更**
2. **パスワード変更**
3. **アカウント削除**
4. **再認証機能**

## トラブルシューティング

### よくあるエラー

#### 1. "No Firebase App '[DEFAULT]' has been created"
- `main_dev.dart`でFirebase.initializeApp()が呼ばれているか確認
- Firebase設定ファイルが正しく配置されているか確認

#### 2. 認証エラー
- Firebase ConsoleでEmail/Password認証が有効か確認
- ネットワーク接続を確認
- APIキーの有効性を確認

#### 3. ビルドエラー
```bash
flutter clean
flutter pub get
# iOS の場合
cd ios && pod install
```

## 今後の改善点

### 1. エラーメッセージの改善
- より詳細なエラーメッセージ
- ユーザーフレンドリーな表示
- 多言語対応

### 2. 追加認証方法
- Googleログイン
- Appleログイン
- 電話番号認証
- ソーシャルメディア認証

### 3. セキュリティ強化
- 二要素認証
- メール認証
- reCAPTCHA導入
- 生体認証連携

### 4. ユーザー体験向上
- オフライン対応
- 自動再接続
- プログレス表示
- エラー回復機能

---
*最終更新: 2025-09-17*
*実装完了度: 100%*