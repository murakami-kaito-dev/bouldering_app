import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/services/auth_service.dart';
import '../../domain/usecases/auth_usecases.dart';
import 'user_provider.dart';
import 'dependency_injection.dart' as di;

/// 認証状態管理Provider (クリーンアーキテクチャ準拠版)
class AuthNotifier extends StateNotifier<bool> {
  final Ref ref;
  final AuthService _authService;
  final LoginUseCase _loginUseCase;
  final SignUpUseCase _signUpUseCase;
  final ChangePasswordUseCase _changePasswordUseCase;
  final PasswordResetUseCase _passwordResetUseCase;

  bool _isSigningUp = false;
  bool _isDeleting = false; // 退会処理中フラグ
  Timer? _debounceTimer;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<User?>? _userSub;

  // エラーメッセージ定数（省略せず掲載）
  static const String emailAlreadyInUse = "email-already-in-use";
  static const String emailAlreadyInUseTitle = "すでにメールアドレスが登録されています";
  static const String emailAlreadyInUseMessage = "入力されたメールアドレスはすでに使用されています。";
  static const String invalidEmail = "invalid-email";
  static const String invalidEmailTitle = "無効なメールアドレス";
  static const String invalidEmailMessage = "入力されたメールアドレスは無効です。";
  static const String userNotFound = "user-not-found";
  static const String userNotFoundTitle = "ユーザーが見つかりません";
  static const String userNotFoundMessage = "入力されたメールアドレスが見つかりません";
  static const String wrongPassword = "wrong-password";
  static const String wrongPasswordTitle = "パスワードエラー";
  static const String wrongPasswordMessage = "パスワードが違います。";
  static const String networkRequestFailed = "network-request-failed";
  static const String networkRequestFailedTitle = "ネットワークエラー";
  static const String networkRequestFailedMessage =
      "サーバーとの通信に失敗しました。デバイスのネットワーク設定と環境を確認して、再度試してください。";
  static const String otherErrorTitle = "不明なエラー";
  static const String otherErrorMessage =
      "不明なエラーが発生しました。入力内容に誤りがないかを確認して、再度試してください。";
  static const String weakPassword = "weak-password";
  static const String weakPasswordTitle = "パスワードエラー";
  static const String weakPasswordMessage = "パスワードが指定された条件を満たしていません。";

  AuthNotifier({
    required this.ref,
    required AuthService authService,
    required LoginUseCase loginUseCase,
    required SignUpUseCase signUpUseCase,
    required ChangePasswordUseCase changePasswordUseCase,
    required PasswordResetUseCase passwordResetUseCase,
  })  : _authService = authService,
        _loginUseCase = loginUseCase,
        _signUpUseCase = signUpUseCase,
        _changePasswordUseCase = changePasswordUseCase,
        _passwordResetUseCase = passwordResetUseCase,
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
      Future.microtask(() => ref.read(userProvider.notifier).login(user.uid));
    }

    // Firebase Auth の認証状態変更を監視
    _authSub = _authService.authStateChanges().listen((user) {
      // 認証状態を更新
      state = user != null;
      
      if (user == null) {
        // ログアウト検知時：ユーザー情報をクリア
        ref.read(userProvider.notifier).logout();
      } else {
        // ログイン検知時
        if (_isSigningUp) {
          // 新規登録フロー中はスキップ（signUpメソッド内で処理済み）
          return;
        }
        // 通常のログイン：ユーザー情報を読み込み（非同期で実行）
        Future.microtask(() => ref.read(userProvider.notifier).login(user.uid));
      }
    });

    // プロファイル更新（メール変更等）の監視
    _userSub = _authService.userChanges().listen((user) {
      if (user == null) return;
      
      // 連続発火防止のためデバウンス処理
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
        await _handleProfileChangeGuard(user);
      });
    });
  }

  /// 旧トークンでの操作をガード
  /// 
  /// メール変更後など、別経路で認証された際の異常系処理
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

  /// ログイン処理
  /// 
  /// Firebase Authでの認証後、Cloud SQLとの同期を行う
  Future<void> login(String email, String password) async {
    try {
      // Firebase Authでログイン
      final userCredential = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user!;
      
      // ユーザー情報を最新化
      await user.reload();
      final authEmail = user.email;

      // Firebase Auth を信頼できる情報源として Cloud SQL を同期
      if (authEmail != null) {
        await ref
            .read(userProvider.notifier)
            .updateEmailByUid(user.uid, authEmail);
      }

      // Cloud SQL からユーザー情報を取得
      await _loginUseCase.execute(user.uid);
      state = true;
    } catch (e) {
      rethrow;
    }
  }

  /// 新規登録処理
  /// 
  /// パスワード強度チェック後、Firebase Auth と Cloud SQL にユーザーを作成
  Future<void> signUp(String email, String password) async {
    // パスワード強度チェック
    if (!_isStrongPassword(password)) {
      throw Exception(weakPasswordMessage);
    }
    
    // 新規登録フラグをON（authStateChangesでの二重処理を防ぐ）
    _isSigningUp = true;
    try {
      // Firebase Authでユーザー作成
      final userCredential = await _authService.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      try {
        // Cloud SQLにユーザー情報を登録
        await ref
            .read(userProvider.notifier)
            .signUp(userCredential.user!.uid, email);
        
        // ユーザー情報を読み込み
        await ref.read(userProvider.notifier).login(userCredential.user!.uid);
        state = true;
      } catch (userError) {
        // Cloud SQL登録失敗時はFirebase Authのユーザーも削除（ロールバック）
        await userCredential.user!.delete();
        rethrow;
      }
    } finally {
      _isSigningUp = false;
    }
  }

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
  /// パスワード再認証後、データベース（Supabase/Cloud SQL）と Firebase Auth からユーザーを削除
  Future<void> deleteAccount({required String password}) async {
    // 二重呼び出し防止
    if (_isDeleting) {
      print('[DEBUG] 退会処理は既に実行中です');
      return;
    }
    
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      throw Exception('ログインしていません');
    }
    
    _isDeleting = true; // 削除処理開始フラグを立てる
    print('[DEBUG] 退会処理開始 - userId: ${currentUser.uid}');
    
    try {
      // セキュリティのため再認証を要求
      final credential = EmailAuthProvider.credential(
        email: currentUser.email!,
        password: password,
      );
      await currentUser.reauthenticateWithCredential(credential);
      print('[DEBUG] 再認証成功');

      // 1. データベース（Supabase/Cloud SQL）からユーザー情報を削除（認証トークンがまだ有効）
      bool dbDeleted = false;
      try {
        print('[DEBUG] DB削除開始');
        await ref.read(userProvider.notifier).deleteAccount(currentUser.uid);
        dbDeleted = true;
        print('[DEBUG] DB削除成功');
      } catch (dbError) {
        print('[ERROR] DB削除エラー: $dbError');
        // DB削除に失敗してもFirebase Auth削除は試みる
      }
      
      // 2. Firebase Authからユーザーを削除
      try {
        print('[DEBUG] Firebase Auth削除開始');
        await _authService.deleteAccount();
        print('[DEBUG] Firebase Auth削除成功');
      } catch (authError) {
        print('[ERROR] Firebase Auth削除エラー: $authError');
        // DB削除が成功していた場合は不整合状態
        if (dbDeleted) {
          print('[WARNING] DBは削除済みだがFirebase Authの削除に失敗');
        }
        rethrow;
      }

      // ローカル状態をクリア
      state = false;
      ref.read(userProvider.notifier).logout();
      print('[DEBUG] 退会処理完了');
    } catch (e) {
      print('[ERROR] 退会処理エラー: $e');
      rethrow;
    } finally {
      _isDeleting = false; // 処理完了後フラグをリセット
    }
  }

  /// Firebase Authメールアドレス変更：**送信→強制ログアウト**のみ
  /// データベース（Supabase/Cloud SQL）はここでは触らない（検証完了していないため）
  Future<void> updateEmailInFirebaseAuth({
    required String newEmail,
    required String currentPassword,
  }) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      throw Exception('ログインしていません');
    }
    try {
      final credential = EmailAuthProvider.credential(
        email: currentUser.email!,
        password: currentPassword,
      );
      await currentUser.reauthenticateWithCredential(credential);

      await _authService.verifyBeforeUpdateEmail(newEmail: newEmail);

      // 送信直後は**必ず**ログアウト（旧トークンを無効化）
      await _executeForceLogout();
    } catch (e) {
      final s = e.toString();
      if (s.contains('wrong-password')) {
        throw Exception('現在のパスワードが間違っています');
      }
      if (s.contains('requires-recent-login')) {
        throw Exception('セキュリティのため、再度ログインしてから操作してください');
      }
      if (s.contains('email-already-in-use')) {
        throw Exception('このメールアドレスは既に他のアカウントで使用されています');
      }
      if (s.contains('invalid-email')) {
        throw Exception('無効なメールアドレスです');
      }
      rethrow;
    }
  }

  /// パスワード変更処理
  /// 
  /// 現在のパスワードで再認証後、新しいパスワードに変更
  /// セキュリティのため変更後は強制ログアウト
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final currentUser = _authService.currentUser;
    
    if (currentUser == null) {
      throw Exception('ログインしていません');
    }
    
    try {
      // セキュリティのため現在のパスワードで再認証
      final credential = EmailAuthProvider.credential(
        email: currentUser.email!,
        password: currentPassword,
      );
      await currentUser.reauthenticateWithCredential(credential);

      // パスワード変更処理を実行
      await _changePasswordUseCase.execute(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      
      // セキュリティのため変更後は強制ログアウト
      // （ユーザーは新しいパスワードで再ログインが必要）
      await _executeForceLogout();
      
    } catch (e) {
      // エラーメッセージを分かりやすく変換
      final s = e.toString();
      if (s.contains('wrong-password')) {
        throw Exception('現在のパスワードが間違っています');
      }
      if (s.contains('requires-recent-login')) {
        throw Exception('セキュリティのため、再度ログインしてから操作してください');
      }
      if (s.contains('weak-password')) {
        throw Exception('パスワードが弱すぎます。もっと強力なパスワードを設定してください');
      }
      rethrow;
    }
  }

  static String getErrorMessage(String errorCode, {bool title = false}) {
    final errorMap = {
      emailAlreadyInUse: [emailAlreadyInUseTitle, emailAlreadyInUseMessage],
      invalidEmail: [invalidEmailTitle, invalidEmailMessage],
      userNotFound: [userNotFoundTitle, userNotFoundMessage],
      wrongPassword: [wrongPasswordTitle, wrongPasswordMessage],
      networkRequestFailed: [
        networkRequestFailedTitle,
        networkRequestFailedMessage
      ],
      weakPassword: [weakPasswordTitle, weakPasswordMessage],
    };
    final messages = errorMap[errorCode];
    if (messages == null) {
      return title ? otherErrorTitle : otherErrorMessage;
    }
    return title ? messages[0] : messages[1];
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

  /// パスワードリセットメール送信処理
  /// 
  /// 役割:
  /// - 指定されたメールアドレスにパスワードリセットメールを送信
  /// - PasswordResetUseCaseを通じてクリーンアーキテクチャに準拠
  /// 
  /// パラメータ:
  /// - [email] パスワードリセットメールを送信するメールアドレス
  /// 
  /// 例外:
  /// - ValidationException: バリデーションエラー
  /// - AuthenticationException: 認証エラー（メールアドレス不存在等）
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _passwordResetUseCase.execute(email);
    } catch (e) {
      // UseCaseの例外をそのまま上位層に伝播
      rethrow;
    }
  }

  /// パスワード強度チェック
  /// 
  /// 要件：8文字以上、大文字・小文字・数字を各1文字以上含む
  bool _isStrongPassword(String password) {
    final RegExp strongPasswordRegExp =
        RegExp(r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)[A-Za-z\d@\$!%*?&]{8,}$');
    return strongPasswordRegExp.hasMatch(password);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _authSub?.cancel();
    _userSub?.cancel();
    super.dispose();
  }
}

/// 新しい認証ProviderのFactory
final authProvider = StateNotifierProvider<AuthNotifier, bool>((ref) {
  final authService = ref.read(di.authServiceProvider);
  final loginUseCase = ref.read(di.loginUseCaseProvider);
  final signUpUseCase = ref.read(di.signUpUseCaseProvider);
  final changePasswordUseCase = ref.read(di.changePasswordUseCaseProvider);
  final passwordResetUseCase = ref.read(di.passwordResetUseCaseProvider);

  return AuthNotifier(
    ref: ref,
    authService: authService,
    loginUseCase: loginUseCase,
    signUpUseCase: signUpUseCase,
    changePasswordUseCase: changePasswordUseCase,
    passwordResetUseCase: passwordResetUseCase,
  );
});
