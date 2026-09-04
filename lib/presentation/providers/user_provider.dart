import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user.dart';
import '../../domain/exceptions/app_exceptions.dart';
import '../../domain/usecases/auth_usecases.dart';
import '../../domain/usecases/user_usecases.dart';
import 'dependency_injection.dart';

/// ユーザー状態管理Provider
///
/// 役割:
/// - 現在ログイン中のユーザー情報を管理
/// - ユーザー認証状態の管理
/// - ユーザープロフィール更新処理
///
/// クリーンアーキテクチャにおける位置づけ:
/// - Presentation層の状態管理
/// - Domain層のUseCaseを呼び出し
/// - UIコンポーネントから参照される

/// ユーザー状態を管理するStateNotifier
class UserNotifier extends StateNotifier<AsyncValue<User?>> {
  final LoginUseCase _loginUseCase;
  final SignUpUseCase _signUpUseCase;
  final UpdateUserProfileUseCase _updateProfileUseCase;
  final UpdateUserIconUseCase _updateIconUseCase;
  final UpdateUserEmailUseCase _updateEmailUseCase;
  final DeleteUserUseCase _deleteUserUseCase;

  /// コンストラクタ
  ///
  /// [_loginUseCase] ログインユースケース
  /// [_signUpUseCase] サインアップユースケース
  /// [_updateProfileUseCase] プロフィール更新ユースケース
  /// [_updateIconUseCase] アイコン更新ユースケース
  /// [_updateEmailUseCase] メールアドレス更新ユースケース
  /// [_deleteUserUseCase] ユーザー削除ユースケース
  UserNotifier(
    this._loginUseCase,
    this._signUpUseCase,
    this._updateProfileUseCase,
    this._updateIconUseCase,
    this._updateEmailUseCase,
    this._deleteUserUseCase,
  ) : super(const AsyncValue.data(null));

  /// ログイン処理
  ///
  /// [userId] ログインするユーザーID
  ///
  /// 処理フロー:
  /// 1. 状態をロード中に設定
  /// 2. LoginUseCaseでユーザー情報取得
  /// 3. 成功時は状態更新、失敗時はエラー状態設定
  Future<void> login(String userId) async {
    if (userId.trim().isEmpty) {
      state = AsyncValue.error(
        Exception('ユーザーIDを入力してください'),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncValue.loading();

    try {
      final user = await _loginUseCase.execute(userId);

      if (user != null) {
        state = AsyncValue.data(user);
      } else {
        state = AsyncValue.error(
          Exception('ユーザーが見つかりません'),
          StackTrace.current,
        );
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// SNS ログイン後のユーザー情報読込（未登録なら登録してから読込）
  ///
  /// [userId] Firebase の uid
  ///
  /// 処理フロー:
  /// 1. LoginUseCase で DB のユーザー情報を取得
  /// 2. 無ければ（USER_NOT_FOUND ＝ 初回ログイン）SignUpUseCase で行を作って再取得
  /// 3. 失敗時は状態をエラーにしたうえで例外を投げる（呼び出し側が画面に知らせる）
  Future<void> loginOrRegister(String userId) async {
    state = const AsyncValue.loading();
    try {
      User? user;
      try {
        user = await _loginUseCase.execute(userId);
      } on AuthenticationException catch (e) {
        if (e.code != 'USER_NOT_FOUND') rethrow;
        // 初回ログイン: アプリ側のユーザー情報を作る
        await _signUpUseCase.execute(userId);
        user = await _loginUseCase.execute(userId);
      }
      state = AsyncValue.data(user);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  /// ログアウト処理
  ///
  /// ユーザー状態をクリアし、未ログイン状態に戻す
  void logout() {
    state = const AsyncValue.data(null);
  }

  /// アカウント削除処理
  ///
  /// [userId] 削除するユーザーのID
  /// Cloud SQLからユーザー情報を完全削除
  Future<void> deleteAccount(String userId) async {
    try {
      // DeleteUserUseCaseを実行
      final success = await _deleteUserUseCase.execute(userId);

      if (success) {
        // 状態をクリア
        state = const AsyncValue.data(null);
      } else {
        throw Exception('ユーザーの削除に失敗しました');
      }
    } catch (e, stackTrace) {
      throw Exception('アカウントの削除に失敗しました: $e');
    }
  }

  /// プロフィール更新処理
  ///
  /// [userName] ユーザー名（オプション）
  /// [userIntroduce] 自己紹介文（オプション）
  /// [favoriteGym] お気に入りジム（オプション）
  /// [gender] 性別（オプション）
  /// [birthday] 生年月日（オプション）
  /// [boulStartDate] ボルダリング開始日（オプション）
  /// [homeGymId] ホームジムID（オプション）
  ///
  /// 処理フロー:
  /// 1. ログイン状態確認
  /// 2. UpdateUserProfileUseCaseで更新実行
  /// 3. 成功時は現在の状態を更新
  Future<void> updateProfile({
    String? userName,
    String? userIntroduce,
    String? favoriteGym,
    int? gender,
    DateTime? birthday,
    DateTime? boulStartDate,
    int? homeGymId,
  }) async {
    final currentUser = state.value;
    if (currentUser == null) {
      state = AsyncValue.error(
        Exception('ログインが必要です'),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncValue.loading();

    try {
      final success = await _updateProfileUseCase.execute(
        userId: currentUser.id,
        userName: userName,
        userIntroduce: userIntroduce,
        favoriteGym: favoriteGym,
        gender: gender,
        birthday: birthday,
        boulStartDate: boulStartDate,
        homeGymId: homeGymId,
      );

      if (success) {
        // 状態を更新
        final updatedUser = currentUser.copyWith(
          userName: userName ?? currentUser.userName,
          userIntroduce: userIntroduce ?? currentUser.userIntroduce,
          favoriteGym: favoriteGym ?? currentUser.favoriteGym,
          gender: gender ?? currentUser.gender,
          birthday: birthday ?? currentUser.birthday,
          boulStartDate: boulStartDate ?? currentUser.boulStartDate,
          homeGymId: homeGymId ?? currentUser.homeGymId,
        );

        state = AsyncValue.data(updatedUser);
      } else {
        // 失敗しても画面の土台（ユーザー情報）は壊さない。呼び出し元がダイアログで知らせる
        state = AsyncValue.data(currentUser);
        throw Exception('プロフィール更新に失敗しました');
      }
    } catch (e) {
      // 一部の項目だけ保存されている可能性があるので、次回の再取得で揃う。
      // 状態をエラーにすると編集画面が「取得に失敗」に落ちて戻れなくなるため、前のデータに戻す
      state = AsyncValue.data(currentUser);
      rethrow;
    }
  }

  /// ユーザーアイコン更新処理
  ///
  /// [imagePath] アップロードする画像ファイルのパス
  ///
  /// 処理フロー:
  /// 1. ログイン状態確認
  /// 2. UpdateUserIconUseCaseで画像アップロードと更新実行
  /// 3. 成功時は現在の状態を更新
  Future<void> updateUserIcon(String imagePath) async {
    final currentUser = state.value;
    if (currentUser == null) {
      state = AsyncValue.error(
        Exception('ログインが必要です'),
        StackTrace.current,
      );
      return;
    }

    if (imagePath.trim().isEmpty) {
      state = AsyncValue.error(
        Exception('画像ファイルを選択してください'),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncValue.loading();

    try {
      final success =
          await _updateIconUseCase.execute(currentUser.id, imagePath);

      if (success) {
        // アイコン更新成功時は再ログインしてURLを取得
        await login(currentUser.id);
      } else {
        state = AsyncValue.data(currentUser);
        throw Exception('アイコン更新に失敗しました');
      }
    } catch (e) {
      // 失敗しても前のユーザー情報に戻す（編集画面を「取得に失敗」に落とさない）
      state = AsyncValue.data(currentUser);
      rethrow;
    }
  }

  /// 現在のユーザー情報を再取得
  ///
  /// ユーザー情報が更新された可能性がある場合に使用
  Future<void> refreshUser() async {
    // 注意: エラー状態の AsyncValue に .value でアクセスすると例外が再スローされる。必ず valueOrNull
    final currentUser = state.valueOrNull;

    if (currentUser != null) {
      await login(currentUser.id);
    }
  }

  /// 現在のユーザー情報を読み込み
  ///
  /// 設定画面などで現在のユーザー情報を表示する際に使用
  Future<void> loadCurrentUser() async {
    final currentUser = state.valueOrNull;
    if (currentUser != null) {
      await refreshUser();
    } else {
      state = AsyncValue.error(
        Exception('ログインが必要です'),
        StackTrace.current,
      );
    }
  }

  /// 通知用メールアドレスを DB に登録／解除する（UID 指定）
  ///
  /// [uid] Firebase の uid
  /// [newEmail] 登録するメールアドレス。null なら未登録に戻す
  ///
  /// 注意:
  /// - 本人確認（確認メールのリンク押下）が済んだメールだけを渡すこと。
  ///   バックエンドも Firebase トークンの確認済みメールしか保存しない
  /// - 別アカウントで登録済みの場合は ValidationException(EMAIL_ALREADY_REGISTERED)
  Future<void> updateEmailByUid(String uid, String? newEmail) async {
    final success = await _updateEmailUseCase.execute(uid, newEmail);
    if (!success) {
      throw Exception('メールアドレスの更新に失敗しました');
    }
    // 現在のユーザーが対象なら画面の状態も即時更新
    final current = state.valueOrNull;
    if (current != null && current.id == uid) {
      state = AsyncValue.data(
        current.copyWith(email: newEmail, clearEmail: newEmail == null),
      );
    }
  }
}

/// ユーザー状態管理Provider
///
/// アプリケーション全体でユーザー状態を管理
final userProvider =
    StateNotifierProvider<UserNotifier, AsyncValue<User?>>((ref) {
  final loginUseCase = ref.read(loginUseCaseProvider);
  final signUpUseCase = ref.read(signUpUseCaseProvider);
  final updateProfileUseCase = ref.read(updateUserProfileUseCaseProvider);
  final updateIconUseCase = ref.read(updateUserIconUseCaseProvider);
  final updateEmailUseCase = ref.read(updateUserEmailUseCaseProvider);
  final deleteUserUseCase = ref.read(deleteUserUseCaseProvider);

  return UserNotifier(
    loginUseCase,
    signUpUseCase,
    updateProfileUseCase,
    updateIconUseCase,
    updateEmailUseCase,
    deleteUserUseCase,
  );
});

/// ログイン状態を判定するProvider
///
/// UIでログイン状態を簡単に確認するためのヘルパー
final isLoggedInProvider = Provider<bool>((ref) {
  final userState = ref.watch(userProvider);
  return userState.maybeWhen(
    data: (user) => user != null,
    orElse: () => false,
  );
});

/// 現在のユーザー情報Provider
///
/// ログイン中のユーザー情報を取得するためのヘルパー
final currentUserProvider = Provider<User?>((ref) {
  final userState = ref.watch(userProvider);
  return userState.maybeWhen(
    data: (user) => user,
    orElse: () => null,
  );
});

/// 認証サービスProvider
///
/// 認証関連の処理を提供するヘルパー
final authServiceProvider = Provider<UserNotifier>((ref) {
  return ref.read(userProvider.notifier);
});
