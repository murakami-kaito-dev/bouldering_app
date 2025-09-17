import 'dart:async';
import '../../shared/data/mock_data.dart';

/// Firebase Authenticationのモック実装
/// 
/// 役割:
/// - Firebase Authの機能をローカルでシミュレート
/// - 認証状態の管理とイベント通知
/// - テスト・開発用の認証機能提供
class MockAuthService {
  static final MockAuthService _instance = MockAuthService._internal();
  factory MockAuthService() => _instance;
  MockAuthService._internal();

  // 認証状態変更を通知するストリーム
  final StreamController<MockUser?> _authStateController = 
      StreamController<MockUser?>.broadcast();

  MockUser? _currentUser;

  /// 認証状態変更ストリーム
  Stream<MockUser?> get authStateChanges => _authStateController.stream;

  /// 現在のユーザー
  MockUser? get currentUser => _currentUser;

  /// メールアドレスとパスワードでサインイン
  Future<MockUserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    // 認証処理をシミュレート
    await Future.delayed(const Duration(milliseconds: 500));

    final success = MockData.authenticateUser(email, password);
    if (success) {
      final userId = MockData.currentLoggedInUserId!;
      final user = MockUser(
        uid: userId,
        email: email,
        displayName: MockData.mockUsers[userId]?.userName,
      );
      
      _currentUser = user;
      _authStateController.add(user);
      
      return MockUserCredential(user: user);
    } else {
      throw MockFirebaseAuthException(
        code: 'user-not-found',
        message: 'ユーザーが見つかりません',
      );
    }
  }

  /// メールアドレスとパスワードでユーザー作成
  Future<MockUserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    // ユーザー作成処理をシミュレート
    await Future.delayed(const Duration(milliseconds: 800));

    // 既存ユーザーチェック
    if (MockData.mockAuthCredentials.containsKey(email)) {
      throw MockFirebaseAuthException(
        code: 'email-already-in-use',
        message: 'このメールアドレスは既に使用されています',
      );
    }

    // 新しいユーザーIDを生成
    final newUserId = 'user${DateTime.now().millisecondsSinceEpoch}';
    
    // モックデータに認証情報を追加
    MockData.mockAuthCredentials[email] = {
      'password': password,
      'userId': newUserId,
    };

    final user = MockUser(
      uid: newUserId,
      email: email,
      displayName: null,
    );
    
    _currentUser = user;
    MockData.setLoggedInUser(newUserId);
    _authStateController.add(user);
    
    return MockUserCredential(user: user);
  }

  /// サインアウト
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    _currentUser = null;
    MockData.logout();
    _authStateController.add(null);
  }

  /// 初期認証状態の確認
  void checkInitialAuthState() {
    // 開発環境では初期状態を常に未ログインに設定
    // これにより、アプリ起動時は必ず未ログイン状態から開始される
    Future.delayed(const Duration(milliseconds: 100), () {
      _currentUser = null;
      MockData.logout(); // 明示的にログアウト状態にする
      _authStateController.add(null);
    });
  }

  /// リソースの解放
  void dispose() {
    _authStateController.close();
  }
}

/// Firebase AuthのUserCredentialのモック
class MockUserCredential {
  final MockUser user;

  MockUserCredential({required this.user});
}

/// Firebase AuthのUserのモック
class MockUser {
  final String uid;
  final String? email;
  final String? displayName;

  MockUser({
    required this.uid,
    this.email,
    this.displayName,
  });
}

/// Firebase AuthのExceptionのモック
class MockFirebaseAuthException implements Exception {
  final String code;
  final String message;

  MockFirebaseAuthException({
    required this.code,
    required this.message,
  });

  @override
  String toString() => 'MockFirebaseAuthException: [$code] $message';
}

/// Firebase Authのエラーコード定数
class MockFirebaseAuthErrorCodes {
  static const String emailAlreadyInUse = "email-already-in-use";
  static const String invalidEmail = "invalid-email";
  static const String userNotFound = "user-not-found";
  static const String wrongPassword = "wrong-password";
  static const String networkRequestFailed = "network-request-failed";
  static const String weakPassword = "weak-password";
}