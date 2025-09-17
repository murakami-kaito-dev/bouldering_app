import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/services/auth_service.dart';

/// Firebase Authentication サービスの実装
/// 
/// 役割:
/// - Firebase Authenticationの具体的な実装
/// - 認証機能の提供
/// - エラーハンドリング
/// 
/// クリーンアーキテクチャにおける位置づけ:
/// - Infrastructure層のサービス実装
/// - Domain層のAuthServiceインターフェースを実装
class FirebaseAuthService implements AuthService {
  final FirebaseAuth _firebaseAuth;

  /// コンストラクタ
  /// 
  /// [_firebaseAuth] Firebase Authenticationインスタンス（テスト時にモック可能）
  FirebaseAuthService({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  /// 現在ログイン中のユーザー情報を取得
  /// 
  /// 返り値:
  /// - ログイン中の場合: Userオブジェクト
  /// - 未ログインの場合: null
  @override
  User? get currentUser => _firebaseAuth.currentUser;

  /// 認証状態の変更を監視するStream
  /// 
  /// 用途:
  /// - ログイン/ログアウト状態の変化を検知
  /// - アプリ全体の認証状態管理
  /// 
  /// 返り値:
  /// - ログイン時: Userオブジェクト
  /// - ログアウト時: null
  @override
  Stream<User?> authStateChanges() => _firebaseAuth.authStateChanges();

  /// ユーザー情報の変更を監視するStream
  /// 
  /// 用途:
  /// - メールアドレス変更、プロフィール更新等の検知
  /// - ユーザー情報の同期
  /// 
  /// 返り値:
  /// - ユーザー情報更新時: 更新されたUserオブジェクト
  /// - ログアウト時: null
  @override
  Stream<User?> userChanges() => _firebaseAuth.userChanges();

  /// メールアドレスとパスワードでログイン処理
  /// 
  /// 役割:
  /// - Firebase Authenticationを使用したユーザー認証
  /// - 既存のユーザーアカウントでのサインイン
  /// 
  /// パラメータ:
  /// - [email] ログインに使用するメールアドレス
  /// - [password] ログインに使用するパスワード
  /// 
  /// 返り値:
  /// - 成功時: UserCredentialオブジェクト
  /// 
  /// 例外:
  /// - user-not-found: 該当するメールアドレスが存在しない
  /// - wrong-password: パスワードが間違っている
  /// - invalid-email: 無効なメールアドレス形式
  /// - network-request-failed: ネットワーク接続エラー
  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      // Firebase Authのエラーをそのまま投げる
      // Presentation層でエラーコードに応じた処理を行う
      rethrow;
    }
  }

  /// メールアドレスとパスワードで新規ユーザー作成
  /// 
  /// 役割:
  /// - Firebase Authenticationで新規アカウントを作成
  /// - 新規ユーザーの登録処理
  /// 
  /// パラメータ:
  /// - [email] 新規登録に使用するメールアドレス
  /// - [password] 新規登録に使用するパスワード
  /// 
  /// 返り値:
  /// - 成功時: UserCredentialオブジェクト
  /// 
  /// 例外:
  /// - email-already-in-use: すでに使用されているメールアドレス
  /// - weak-password: 弱いパスワード（6文字未満等）
  /// - invalid-email: 無効なメールアドレス形式
  /// - network-request-failed: ネットワーク接続エラー
  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      rethrow;
    }
  }

  /// ログアウト処理
  /// 
  /// 役割:
  /// - Firebase Authenticationからのサインアウト
  /// - 認証状態をクリア
  /// 
  /// 処理内容:
  /// - Firebase Authセッションの終了
  /// - 認証状態変更イベント（null）の発火
  /// - ローカルの認証情報クリア
  /// 
  /// 例外:
  /// - サインアウトに失敗した場合のException
  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      throw Exception('サインアウトに失敗しました: $e');
    }
  }

  /// パスワードリセットメール送信処理
  /// 
  /// 役割:
  /// - 指定されたメールアドレスにパスワードリセット用メールを送信
  /// - Firebase Authenticationの標準機能を利用
  /// 
  /// 処理の流れ:
  /// 1. Firebase Authが指定されたメールアドレスを確認
  /// 2. そのメールアドレスが登録済みの場合、パスワードリセット用のリンクを含むメールを送信
  /// 3. ユーザーがメール内のリンクをクリック
  /// 4. Firebase提供の画面で新しいパスワードを設定
  /// 5. 新しいパスワードでログイン可能になる
  /// 
  /// 注意:
  /// - 登録されていないメールアドレスの場合は「user-not-found」エラーが発生
  /// - セキュリティ上、存在しないメールアドレスでもエラー内容でそれが分かる
  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      rethrow;
    } catch (e) {
      // Firebase Auth以外の予期しないエラーをキャッチ（ネットワークエラー等）
      rethrow;
    }
  }

  /// メールアドレス更新処理（非推奨）
  /// 
  /// 注意: このメソッドは非推奨です。verifyBeforeUpdateEmail()を使用してください。
  /// 
  /// 役割:
  /// - 現在のユーザーのメールアドレスを直接更新
  /// - セキュリティ上の理由で非推奨
  /// 
  /// パラメータ:
  /// - [newEmail] 新しいメールアドレス
  /// 
  /// 例外:
  /// - ログインしていない場合のException
  /// - requires-recent-login: 最近の認証が必要
  @override
  Future<void> updateEmail({required String newEmail}) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('ユーザーがログインしていません');
      }
      await user.updateEmail(newEmail);
    } on FirebaseAuthException catch (e) {
      rethrow;
    }
  }

  /// メールアドレス変更（認証メール送信）処理
  /// 
  /// 役割:
  /// - メールアドレス変更前に認証メールを送信
  /// - セキュアなメールアドレス変更方法
  /// 
  /// 処理の流れ:
  /// 1. 新しいメールアドレスに認証用メールを送信
  /// 2. ユーザーが認証リンクをクリック
  /// 3. メールアドレスが変更される
  /// 
  /// パラメータ:
  /// - [newEmail] 新しいメールアドレス
  /// 
  /// 例外:
  /// - ログインしていない場合のException
  /// - invalid-email: 無効なメールアドレス形式
  /// - requires-recent-login: 最近の認証が必要
  @override
  Future<void> verifyBeforeUpdateEmail({required String newEmail}) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('ユーザーがログインしていません');
      }
      await user.verifyBeforeUpdateEmail(newEmail);
    } on FirebaseAuthException catch (e) {
      rethrow;
    }
  }

  /// パスワード更新処理
  /// 
  /// 役割:
  /// - 現在ログイン中のユーザーのパスワードを更新
  /// - Firebase Authenticationでのパスワード変更
  /// 
  /// 注意:
  /// - セキュリティ上、事前に再認証が必要な場合がある
  /// - 古い認証情報では「requires-recent-login」エラーが発生
  /// 
  /// パラメータ:
  /// - [newPassword] 新しいパスワード
  /// 
  /// 例外:
  /// - ログインしていない場合のException
  /// - requires-recent-login: 最近の認証が必要
  /// - weak-password: 弱いパスワード
  @override
  Future<void> updatePassword({required String newPassword}) async {
    try {
      // 現在のユーザーを取得
      final user = _firebaseAuth.currentUser;
      
      // ログイン状態の確認
      if (user == null) {
        throw Exception('ユーザーがログインしていません');
      }
      
      // Firebase Authでパスワードを更新
      await user.updatePassword(newPassword);
      
    } on FirebaseAuthException catch (e) {
      // Firebase Authのエラーをそのまま上位層へ伝播
      rethrow;
    } catch (e) {
      // その他の予期しないエラーも上位層へ伝播
      rethrow;
    }
  }

  /// アカウント削除処理
  /// 
  /// 役割:
  /// - Firebase Authentication上のユーザーアカウントを完全削除
  /// - すべての認証情報とプロフィール情報を削除
  /// 
  /// 注意:
  /// - 削除後は元に戻せない
  /// - セキュリティ上、事前に再認証が必要な場合がある
  /// - アプリのデータベース上のユーザー情報は別途削除が必要
  /// 
  /// 処理内容:
  /// - Firebase Authからのアカウント削除
  /// - 認証状態の自動クリア
  /// - 関連するセッション情報の削除
  /// 
  /// 例外:
  /// - ログインしていない場合のException
  /// - requires-recent-login: 最近の認証が必要
  @override
  Future<void> deleteAccount() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('ユーザーがログインしていません');
      }
      await user.delete();
    } on FirebaseAuthException catch (e) {
      rethrow;
    }
  }
}