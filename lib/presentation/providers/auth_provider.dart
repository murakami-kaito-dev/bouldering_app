import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/services/auth_service.dart';
import '../../domain/exceptions/app_exceptions.dart';
import 'user_provider.dart';
import 'dependency_injection.dart' as di;

/// 通知用メールアドレス登録の結果
enum EmailRegistrationResult {
  /// すでに本人確認済みのメールだったので、その場で登録できた
  registered,

  /// 確認メールを送った。リンク押下 → 再ログイン後に登録が完了する
  verificationSent,
}

/// 認証状態管理Provider（Google / Apple のプロバイダ認証）
///
/// 役割:
/// - Firebase Auth の認証状態（ログイン中か）を state（bool）で持つ
/// - サインイン成功後、アプリ側ユーザー情報の読込（初回なら登録）を行う
/// - 退会（プロバイダで再認証 → DB → Firebase の順に削除）
/// - 通知用メールアドレスの登録（確認メールによる本人確認つき）
///
/// メール/パスワード方式は 2026-09 に撤廃。本人確認は各プロバイダが行い、
/// メールアドレスは認証には使わない（設定画面から任意で登録する連絡先）。
class AuthNotifier extends StateNotifier<bool> {
  final Ref ref;
  final AuthService _authService;

  bool _isSigningIn = false; // サインイン処理中（authStateChanges との二重処理防止）
  bool _isDeleting = false; // 退会処理中フラグ
  Timer? _debounceTimer;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<User?>? _userSub;

  /// 確認メール送信後、リンク押下→再ログインで登録を完了させるための保留メール
  static const String pendingEmailKey = 'pending_email_registration';

  // エラーメッセージ定数
  static const String networkRequestFailed = "network-request-failed";
  static const String networkRequestFailedTitle = "ネットワークエラー";
  static const String networkRequestFailedMessage =
      "サーバーとの通信に失敗しました。デバイスのネットワーク設定と環境を確認して、再度試してください。";
  static const String otherErrorTitle = "ログインに失敗しました";
  static const String otherErrorMessage =
      "ログインに失敗しました。時間をおいて再度お試しください。";

  AuthNotifier({
    required this.ref,
    required AuthService authService,
  })  : _authService = authService,
        super(false) {
    _checkLoginStatus();
  }

  /// 初期化時のログイン状態チェックと認証状態の監視設定
  void _checkLoginStatus() {
    // 現在のログイン状態を確認
    final user = _authService.currentUser;
    state = user != null;
    if (user != null) {
      // 既にログイン済みの場合はユーザー情報を読み込み（非同期で実行して初期化の競合を回避）
      Future.microtask(() => _loadUserQuietly(user));
    }

    // Firebase Auth の認証状態変更を監視
    _authSub = _authService.authStateChanges().listen((user) {
      // 認証状態を更新
      state = user != null;

      if (user == null) {
        // ログアウト検知時：ユーザー情報をクリア
        ref.read(userProvider.notifier).logout();
      } else {
        // サインイン処理中は signInWith() 側で読み込むのでスキップ
        if (_isSigningIn) return;
        Future.microtask(() => _loadUserQuietly(user));
      }
    });

    // プロファイル更新（メール確定等）の監視
    _userSub = _authService.userChanges().listen((user) {
      if (user == null) return;

      // 連続発火防止のためデバウンス処理
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
        await _handleProfileChangeGuard(user);
      });
    });
  }

  /// 起動時・状態変化時のユーザー読込（失敗は userProvider のエラー状態で画面に出る）
  Future<void> _loadUserQuietly(User user) async {
    try {
      await ref.read(userProvider.notifier).loginOrRegister(user.uid);
      await _completePendingEmailRegistration(user);
    } catch (e) {
      debugPrint('[AUTH] ユーザー情報の読込に失敗: $e');
    }
  }

  /// 旧トークンでの操作をガード
  ///
  /// メール確定後など、別経路で認証された際の異常系処理。
  /// トークンが失効している場合は強制ログアウトを実行
  Future<void> _handleProfileChangeGuard(User user) async {
    try {
      // トークンの有効性を確認
      await user.reload();
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('user-token-expired') || msg.contains('token-expired')) {
        // トークン失効時は強制ログアウト
        await _executeForceLogout();
      }
    }
  }

  // --- パブリックAPI ---

  /// Google / Apple でサインイン（初回ならアプリ側のユーザー情報も作る）
  ///
  /// 返り値: 成功で true。ユーザーがキャンセルしたら false
  /// 例外: プロバイダ側・通信・DB 登録の失敗
  Future<bool> signInWith(AuthProviderKind kind) async {
    _isSigningIn = true;
    try {
      final credential = await _authService.signInWith(kind);
      if (credential == null) return false; // キャンセル
      final user = credential.user;
      if (user == null) {
        throw const AuthenticationException(message: 'ログインに失敗しました');
      }

      try {
        // DB のユーザー情報を読込（無ければ登録＝初回ログイン）
        await ref.read(userProvider.notifier).loginOrRegister(user.uid);
      } catch (e) {
        // DB 側に進めなかった場合は Firebase のセッションを残さない
        // （次回タップで最初からやり直せる。Firebase アカウント自体は残る）
        await _authService.signOut();
        rethrow;
      }

      await _completePendingEmailRegistration(user);
      state = true;
      return true;
    } finally {
      _isSigningIn = false;
    }
  }

  /// ログイン中ユーザーが使ったプロバイダ（設定画面の表示用）
  AuthProviderKind? get currentProviderKind => _authService.currentProviderKind();

  Future<void> logout() async {
    try {
      await _authService.signOut();
      state = false;
      ref.read(userProvider.notifier).logout();
    } catch (e) {
      throw Exception("ログアウトに失敗しました：$e");
    }
  }

  /// アカウント削除処理
  ///
  /// 同じプロバイダで再認証（本人確認）したうえで、DB → Firebase Auth の順に削除する
  ///
  /// 返り値: 本人確認をキャンセルしたら false（何も削除しない）
  Future<bool> deleteAccount() async {
    // 二重呼び出し防止
    if (_isDeleting) {
      debugPrint('[AUTH] 退会処理は既に実行中です');
      return false;
    }

    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      throw Exception('ログインしていません');
    }

    _isDeleting = true;
    try {
      // セキュリティのため再認証を要求（Firebase は退会に直近ログインを求める）
      final ok = await _authService.reauthenticate();
      if (!ok) return false;

      // 1. DB からユーザー情報を削除（認証トークンがまだ有効）
      bool dbDeleted = false;
      try {
        await ref.read(userProvider.notifier).deleteAccount(currentUser.uid);
        dbDeleted = true;
      } catch (dbError) {
        debugPrint('[AUTH] DB削除エラー: $dbError');
        // DB削除に失敗してもFirebase Auth削除は試みる
      }

      // 2. Firebase Authからユーザーを削除
      try {
        await _authService.deleteAccount();
      } catch (authError) {
        if (dbDeleted) {
          debugPrint('[AUTH] DBは削除済みだがFirebase Authの削除に失敗: $authError');
        }
        rethrow;
      }

      // ローカル状態をクリア
      state = false;
      ref.read(userProvider.notifier).logout();
      await _clearPendingEmail();
      return true;
    } finally {
      _isDeleting = false;
    }
  }

  /// 通知用メールアドレスの登録（本人確認つき）
  ///
  /// - 入力したメールが Firebase アカウントの確認済みメールと同じなら、その場で DB に登録
  ///   （例: Google アカウントのメール。Google が本人確認済み）
  /// - それ以外は確認メールを送る。リンク押下で Firebase アカウントのメールが確定し、
  ///   古いセッションは失効する → 次回ログイン時に [_completePendingEmailRegistration] が
  ///   DB へ登録して完了する
  ///
  /// 例外: 形式エラー・別アカウントで登録済み（ValidationException）・通信エラー
  Future<EmailRegistrationResult> registerEmail(String newEmail) async {
    final user = _authService.currentUser;
    if (user == null) throw Exception('ログインしていません');
    final email = newEmail.trim();

    if (user.email == email && user.emailVerified) {
      await ref.read(userProvider.notifier).updateEmailByUid(user.uid, email);
      return EmailRegistrationResult.registered;
    }

    try {
      await _authService.verifyBeforeUpdateEmail(newEmail: email);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        // 直近ログインが必要 → 同じプロバイダで再認証してやり直す
        final ok = await _authService.reauthenticate();
        if (!ok) throw Exception('本人確認がキャンセルされました');
        await _authService.verifyBeforeUpdateEmail(newEmail: email);
      } else if (e.code == 'invalid-email') {
        throw Exception('メールアドレスの形式が正しくありません');
      } else {
        rethrow;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(pendingEmailKey, email);
    return EmailRegistrationResult.verificationSent;
  }

  /// 通知用メールアドレスを未登録に戻す
  Future<void> removeEmail() async {
    final user = _authService.currentUser;
    if (user == null) throw Exception('ログインしていません');
    await ref.read(userProvider.notifier).updateEmailByUid(user.uid, null);
    await _clearPendingEmail();
  }

  /// 確認メールのリンク押下後、再ログインしたタイミングで DB への登録を完了させる
  Future<void> _completePendingEmailRegistration(User user) async {
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getString(pendingEmailKey);
    if (pending == null) return;

    // Firebase 側でそのメールが確定（本人確認済み）していれば DB に登録
    if (user.email == pending && user.emailVerified) {
      try {
        await ref.read(userProvider.notifier).updateEmailByUid(user.uid, pending);
      } catch (e) {
        // 別アカウントで登録済み等。設定画面から入力し直すと同じ判定でその場で案内される
        debugPrint('[AUTH] 保留中メールの登録に失敗: $e');
      }
      await prefs.remove(pendingEmailKey);
    }
  }

  Future<void> _clearPendingEmail() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(pendingEmailKey);
  }

  static String getErrorMessage(String errorCode, {bool title = false}) {
    if (errorCode == networkRequestFailed) {
      return title ? networkRequestFailedTitle : networkRequestFailedMessage;
    }
    return title ? otherErrorTitle : otherErrorMessage;
  }

  /// 認証トークンの有効性チェック
  ///
  /// アプリ復帰時などに呼び出し、トークンが失効していれば強制ログアウト
  /// UI層から明示的に呼び出される想定
  Future<void> checkAuthRevoked() async {
    final u = _authService.currentUser;
    if (u == null) return;

    try {
      // トークンの有効性を確認
      await u.reload();
    } catch (e) {
      final s = e.toString();
      if (s.contains('user-token-expired') || s.contains('token-expired')) {
        // トークン失効時は強制ログアウト
        await _executeForceLogout();
      }
    }
  }

  /// Firebaseログイン済みなのにユーザー情報が未取得なら取得し直す（自己回復）
  ///
  /// 機内モード等のオフラインで起動すると、Firebaseの認証セッション自体は
  /// 端末内で復元される一方、ユーザー情報API（Supabase）の取得が失敗し、
  /// 通信が回復しても「未ログイン扱い」のまま固まってしまう。
  /// アプリ復帰時（app.dart）や再読み込みボタンからこれを呼んで回復させる。
  Future<void> retryUserLoadIfNeeded() async {
    final user = _authService.currentUser;
    if (user == null) return;

    final userState = ref.read(userProvider);
    // 注意: エラー状態の AsyncValue に .value でアクセスすると保持している例外が
    // その場で再スローされる（Riverpod 2.x の仕様）。必ず valueOrNull を使うこと
    if (userState.isLoading || userState.valueOrNull != null) return;

    await _loadUserQuietly(user);
  }

  /// 強制ログアウト処理
  ///
  /// Firebase Authからサインアウトし、ローカル状態をクリア
  /// エラーが発生してもローカル状態は必ずクリアする
  Future<void> _executeForceLogout() async {
    try {
      // Firebase Authからサインアウト
      await _authService.signOut();
    } finally {
      // 失敗してもローカル状態は必ずクリア
      ref.read(userProvider.notifier).logout();
      state = false;
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _authSub?.cancel();
    _userSub?.cancel();
    super.dispose();
  }
}

/// 認証ProviderのFactory
final authProvider = StateNotifierProvider<AuthNotifier, bool>((ref) {
  final authService = ref.read(di.authServiceProvider);
  return AuthNotifier(ref: ref, authService: authService);
});
