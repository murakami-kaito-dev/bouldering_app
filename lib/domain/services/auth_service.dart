import 'package:firebase_auth/firebase_auth.dart';

/// ログインに使う外部 ID プロバイダ（このアプリは Google / Apple の2つだけ）
///
/// 本人確認をするのは各プロバイダで、Firebase はその証明（ID トークン）を検証して
/// アプリ用のアカウント（uid）を発行する。メール/パスワード方式は 2026-09 に撤廃。
enum AuthProviderKind { google, apple }

extension AuthProviderKindX on AuthProviderKind {
  /// Firebase 上の providerId
  String get providerId => switch (this) {
        AuthProviderKind.google => 'google.com',
        AuthProviderKind.apple => 'apple.com',
      };

  String get displayName => switch (this) {
        AuthProviderKind.google => 'Google',
        AuthProviderKind.apple => 'Apple',
      };

  static AuthProviderKind? fromProviderId(String providerId) {
    for (final kind in AuthProviderKind.values) {
      if (kind.providerId == providerId) return kind;
    }
    return null;
  }
}

/// 認証サービスのインターフェース
///
/// 役割:
/// - Firebase Authentication のラッパー（プロバイダ認証）
/// - 認証状態の監視
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

  /// Google / Apple でサインイン（初回なら Firebase 側にアカウントが作られる）
  ///
  /// 返り値: ユーザーがキャンセルしたときは null
  Future<UserCredential?> signInWith(AuthProviderKind kind);

  /// ログイン中ユーザーがどのプロバイダで入ったか（判定できなければ null）
  AuthProviderKind? currentProviderKind();

  /// 直近ログインを要求される操作（退会・メール確定）の前に、同じプロバイダで再認証する
  ///
  /// 返り値: ユーザーがキャンセルしたときは false
  Future<bool> reauthenticate();

  /// サインアウト
  Future<void> signOut();

  /// メールアドレスの本人確認メールを送る（リンク押下で Firebase アカウントの email が確定する）
  Future<void> verifyBeforeUpdateEmail({required String newEmail});

  /// アカウント削除（Firebase 側）
  Future<void> deleteAccount();
}
