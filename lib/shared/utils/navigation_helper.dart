import 'package:flutter/material.dart';
import '../constants/app_routes.dart';
import '../../domain/exceptions/app_exceptions.dart';

/// ナビゲーションヘルパークラス
///
/// 役割:
/// - 画面遷移処理の共通化
/// - パラメータ付き遷移の簡素化
/// - 戻るボタンやモーダル表示の統一
class NavigationHelper {
  /// ジム詳細画面への遷移
  ///
  /// [context] BuildContext
  /// [gymId] 表示するジムのID
  static Future<void> toGymDetail(BuildContext context, int gymId) async {
    await Navigator.pushNamed(
      context,
      AppRoutes.gymDetail,
      arguments: {RouteParams.gymId: gymId},
    );
  }

  /// ジム検索画面への遷移
  static Future<void> toGymSearch(BuildContext context) async {
    await Navigator.pushNamed(context, AppRoutes.gymSearch);
  }

  /// ジム地図画面への遷移
  static Future<void> toGymMap(BuildContext context) async {
    await Navigator.pushNamed(context, AppRoutes.gymMap);
  }

  /// ツイート投稿画面への遷移
  ///
  /// [context] BuildContext
  /// [preSelectedGymId] 事前選択するジムID（オプション）
  static Future<void> toTweetPost(BuildContext context,
      {int? preSelectedGymId}) async {
    final arguments = preSelectedGymId != null
        ? {RouteParams.preSelectedGymId: preSelectedGymId}
        : null;

    await Navigator.pushNamed(
      context,
      AppRoutes.tweetPost,
      arguments: arguments,
    );
  }

  /// ツイート詳細画面への遷移
  ///
  /// [context] BuildContext
  /// [tweetId] 表示するツイートのID
  static Future<void> toTweetDetail(BuildContext context, int tweetId) async {
    await Navigator.pushNamed(
      context,
      AppRoutes.tweetDetail,
      arguments: {RouteParams.tweetId: tweetId},
    );
  }

  /// 他ユーザープロフィール画面への遷移
  ///
  /// [context] BuildContext
  /// [userId] 表示するユーザーのID
  static Future<void> toOtherUserProfile(
      BuildContext context, String userId) async {
    await Navigator.pushNamed(
      context,
      AppRoutes.otherUserProfile,
      arguments: {RouteParams.userId: userId},
    );
  }

  /// 他ユーザープロフィール画面への遷移（ブロック状態チェック付き）
  ///
  /// [context] BuildContext
  /// [userId] 表示するユーザーのID
  /// [blockChecker] ブロック状態を確認する関数（依存性注入）
  ///
  /// ブロック状態をチェックして、適切なページに遷移する
  /// 依存性注入により、NavigationHelperはブロック判定ロジックに依存しない
  static Future<void> toOtherUserProfileWithBlockCheck(
    BuildContext context,
    String userId,
    Future<bool> Function(String) blockChecker,
  ) async {
    try {
      final isBlocked = await blockChecker(userId);
      
      if (isBlocked) {
        // ブロック済みユーザーページに遷移
        await Navigator.pushNamed(context, AppRoutes.blockedUser);
      } else {
        // 通常のプロフィールページに遷移
        await Navigator.pushNamed(
          context,
          AppRoutes.otherUserProfile,
          arguments: {RouteParams.userId: userId},
        );
      }
    } catch (e) {
      // エラーが発生した場合は通常のプロフィールページに遷移
      await Navigator.pushNamed(
        context,
        AppRoutes.otherUserProfile,
        arguments: {RouteParams.userId: userId},
      );
    }
  }

  /// プロフィール編集画面への遷移
  static Future<void> toEditProfile(BuildContext context) async {
    await Navigator.pushNamed(context, AppRoutes.editProfile);
  }

  /// お気に入りユーザー一覧画面への遷移
  static Future<void> toFavoriteUsers(BuildContext context) async {
    await Navigator.pushNamed(context, AppRoutes.favoriteUsers);
  }

  /// イキタイジム一覧画面への遷移
  static Future<void> toFavoriteGyms(BuildContext context) async {
    await Navigator.pushNamed(context, AppRoutes.favoriteGyms);
  }

  /// 設定画面への遷移
  static Future<void> toSettings(BuildContext context) async {
    await Navigator.pushNamed(context, AppRoutes.settings);
  }

  /// ブロックリスト画面への遷移
  static Future<void> toBlockList(BuildContext context) async {
    await Navigator.pushNamed(context, AppRoutes.blockList);
  }

  /// 確認ダイアログの表示
  ///
  /// [context] BuildContext
  /// [title] ダイアログのタイトル
  /// [message] ダイアログのメッセージ
  /// [confirmText] 確認ボタンのテキスト（デフォルト: 'はい'）
  /// [cancelText] キャンセルボタンのテキスト（デフォルト: 'キャンセル'）
  ///
  /// 返り値:
  /// [bool] 確認ボタンが押された場合はtrue、キャンセルの場合はfalse
  static Future<bool> showConfirmDialog({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'はい',
    String cancelText = 'キャンセル',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmText),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// エラーダイアログの表示
  ///
  /// [context] BuildContext
  /// [title] ダイアログのタイトル（デフォルト: 'エラー'）
  /// [message] エラーメッセージ
  /// [error] 例外オブジェクト（オプション）
  static Future<void> showErrorDialog({
    required BuildContext context,
    String title = 'エラー',
    String? message,
    dynamic error,
  }) async {
    final displayMessage = message ?? ExceptionUtils.getDisplayMessage(error);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(displayMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// 成功ダイアログの表示
  ///
  /// [context] BuildContext
  /// [title] ダイアログのタイトル（デフォルト: '完了'）
  /// [message] 成功メッセージ
  static Future<void> showSuccessDialog({
    required BuildContext context,
    String title = '完了',
    required String message,
  }) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// ローディングダイアログの表示
  ///
  /// [context] BuildContext
  /// [message] ローディングメッセージ
  ///
  /// 返り値:
  /// [Function] ダイアログを閉じる関数
  static Function showLoadingDialog({
    required BuildContext context,
    String message = '処理中...',
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );

    return () => Navigator.of(context).pop();
  }

  /// ボトムシートの表示
  ///
  /// [context] BuildContext
  /// [builder] ボトムシートのウィジェットビルダー
  /// [isScrollControlled] スクロール制御の有効化（デフォルト: true）
  static Future<T?> showBottomSheet<T>({
    required BuildContext context,
    required Widget Function(BuildContext) builder,
    bool isScrollControlled = true,
  }) async {
    return await showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: builder(context),
      ),
    );
  }

  /// ルートパラメータの取得
  ///
  /// [context] BuildContext
  /// [key] パラメータのキー
  ///
  /// 返り値:
  /// [T?] 指定されたキーの値（型安全）
  static T? getRouteParam<T>(BuildContext context, String key) {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is Map<String, dynamic>) {
      return arguments[key] as T?;
    }
    return null;
  }
}
