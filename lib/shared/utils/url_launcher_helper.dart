import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// URL遷移関連のユーティリティクラス
///
/// アプリ全体で使用される外部URLへの遷移処理を共通化
class UrlLauncherHelper {
  /// 利用規約のURL
  static const String _termsOfServiceUrl =
      'https://spiral-menu-66b.notion.site/268acc8f8f00801398e2f1d368322f4b';

  /// プライバシーポリシーのURL
  static const String _privacyPolicyUrl =
      'https://spiral-menu-66b.notion.site/268acc8f8f0080caad6ed16c046baa9d';

  /// フィードバックフォームのURL
  static const String _feedbackUrl = 'https://forms.gle/oMGHSeEtHs8HAPkc9';

  /// 利用規約を外部ブラウザで開く
  ///
  /// [context] BuildContext（エラー表示用）
  static Future<void> showTermsOfService(BuildContext context) async {
    await _launchUrl(
      context: context,
      url: _termsOfServiceUrl,
      errorMessage: '利用規約を開けませんでした',
    );
  }

  /// プライバシーポリシーを外部ブラウザで開く
  ///
  /// [context] BuildContext（エラー表示用）
  static Future<void> showPrivacyPolicy(BuildContext context) async {
    await _launchUrl(
      context: context,
      url: _privacyPolicyUrl,
      errorMessage: 'プライバシーポリシーを開けませんでした',
    );
  }

  /// フィードバックフォームを外部ブラウザで開く
  ///
  /// [context] BuildContext（エラー表示用）
  static Future<void> showFeedbackForm(BuildContext context) async {
    await _launchUrl(
      context: context,
      url: _feedbackUrl,
      errorMessage: 'フィードバックフォームを開けませんでした',
    );
  }

  /// URLを外部ブラウザで開く共通処理
  ///
  /// [context] BuildContext（エラー表示用）
  /// [url] 開くURL
  /// [errorMessage] エラー時に表示するメッセージ
  static Future<void> _launchUrl({
    required BuildContext context,
    required String url,
    required String errorMessage,
  }) async {
    final uri = Uri.parse(url);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication, // 外部ブラウザで開く
        );
      } else {
        if (context.mounted) {
          _showErrorSnackBar(context, errorMessage);
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(context, 'エラーが発生しました: ${e.toString()}');
      }
    }
  }

  /// エラーメッセージを表示する
  ///
  /// [context] BuildContext
  /// [message] 表示するエラーメッセージ
  static void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
