import 'package:firebase_auth/firebase_auth.dart';

/// 認証サービスのインターフェース
/// 
/// 役割:
/// - 認証機能の抽象化
/// - Firebase Authenticationのラッパー
/// - 認証状態の管理
/// 
/// クリーンアーキテクチャにおける位置づけ:
/// - Domain層のサービスインターフェース
/// - Infrastructure層で具体的な実装を提供
abstract class AuthService {
  /// 現在のユーザーを取得
  User? get currentUser;

  /// 認証状態の変更を監視
  Stream<User?> authStateChanges();

  /// ユーザー情報（メールアドレス等）の変更を監視
  Stream<User?> userChanges();

  /// メールアドレスとパスワードでサインイン
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// メールアドレスとパスワードで新規ユーザー作成
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// サインアウト
  Future<void> signOut();

  /// パスワードリセットメール送信
  Future<void> sendPasswordResetEmail({required String email});

  /// メールアドレス変更
  Future<void> updateEmail({required String newEmail});

  /// メールアドレス変更（認証メール送信先）
  Future<void> verifyBeforeUpdateEmail({required String newEmail});

  /// パスワード変更
  Future<void> updatePassword({required String newPassword});

  /// アカウント削除
  Future<void> deleteAccount();
}