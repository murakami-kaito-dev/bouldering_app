import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../domain/services/auth_service.dart';

/// Firebase Authentication サービスの実装（Google / Apple のプロバイダ認証）
///
/// 役割:
/// - Google: google_sign_in（ネイティブのアカウント選択）で証明を受け取り、Firebase に渡す
/// - Apple: firebase_auth の AppleAuthProvider（iOS 標準の Sign in with Apple シート）
/// - 認証状態の監視・再認証・サインアウト・アカウント削除
///
/// クリーンアーキテクチャにおける位置づけ:
/// - Infrastructure層のサービス実装
/// - Domain層の AuthService インターフェースを実装
class FirebaseAuthService implements AuthService {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  /// [firebaseAuth] / [googleSignIn] はテスト時にモック可能
  FirebaseAuthService({FirebaseAuth? firebaseAuth, GoogleSignIn? googleSignIn})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn() {
    // Firebase が送るメール（確認メール等）を日本語テンプレートにする
    // （未指定だと英語の「Verify your email for …」で届く）
    _firebaseAuth.setLanguageCode('ja');
  }

  @override
  User? get currentUser => _firebaseAuth.currentUser;

  @override
  Stream<User?> authStateChanges() => _firebaseAuth.authStateChanges();

  @override
  Stream<User?> userChanges() => _firebaseAuth.userChanges();

  @override
  Future<UserCredential?> signInWith(AuthProviderKind kind) async {
    switch (kind) {
      case AuthProviderKind.google:
        final credential = await _googleCredential();
        if (credential == null) return null; // キャンセル
        return _firebaseAuth.signInWithCredential(credential);
      case AuthProviderKind.apple:
        try {
          return await _firebaseAuth.signInWithProvider(_appleProvider());
        } on FirebaseAuthException catch (e) {
          if (_isCancelled(e)) return null;
          rethrow;
        }
    }
  }

  @override
  AuthProviderKind? currentProviderKind() {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;
    for (final info in user.providerData) {
      final kind = AuthProviderKindX.fromProviderId(info.providerId);
      if (kind != null) return kind;
    }
    return null;
  }

  @override
  Future<bool> reauthenticate() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw Exception('ログインしていません');
    final kind = currentProviderKind();
    if (kind == null) throw Exception('ログイン方法を判定できませんでした');

    try {
      switch (kind) {
        case AuthProviderKind.google:
          final credential = await _googleCredential();
          if (credential == null) return false;
          await user.reauthenticateWithCredential(credential);
          return true;
        case AuthProviderKind.apple:
          await user.reauthenticateWithProvider(_appleProvider());
          return true;
      }
    } on FirebaseAuthException catch (e) {
      if (_isCancelled(e)) return false;
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      // Google 側のセッションも切る（次回に別アカウントを選べるように）
      await _googleSignIn.signOut();
    } catch (_) {
      // Google 未ログイン等は無視
    }
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      throw Exception('サインアウトに失敗しました: $e');
    }
  }

  @override
  Future<void> verifyBeforeUpdateEmail({required String newEmail}) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw Exception('ログインしていません');
    await user.verifyBeforeUpdateEmail(newEmail);
  }

  @override
  Future<void> deleteAccount() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw Exception('ログインしていません');
    await user.delete();
  }

  // --- private ---

  /// Google のアカウント選択を出し、Firebase に渡す証明を作る（キャンセルなら null）
  Future<AuthCredential?> _googleCredential() async {
    GoogleSignInAccount? account;
    try {
      account = await _googleSignIn.signIn();
    } on PlatformException catch (e) {
      if (e.code == GoogleSignIn.kSignInCanceledError) return null;
      rethrow;
    }
    if (account == null) return null;
    final auth = await account.authentication;
    return GoogleAuthProvider.credential(
      idToken: auth.idToken,
      accessToken: auth.accessToken,
    );
  }

  AppleAuthProvider _appleProvider() => AppleAuthProvider()
    ..addScope('email')
    ..addScope('name');

  /// ユーザーがシートを閉じた（キャンセル）と判定できるエラー
  bool _isCancelled(FirebaseAuthException e) =>
      e.code.contains('cancel'); // canceled / web-context-cancelled
}
