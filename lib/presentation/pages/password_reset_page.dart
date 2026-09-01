import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../components/common/app_logo.dart';
import '../providers/auth_provider.dart';
import '../../domain/exceptions/app_exceptions.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';

class PasswordResetPage extends ConsumerStatefulWidget {
  const PasswordResetPage({super.key});

  @override
  ConsumerState<PasswordResetPage> createState() => _PasswordResetPageState();
}

class _PasswordResetPageState extends ConsumerState<PasswordResetPage> {
  // メールアドレスを管理する変数
  String _email = '';
  // ローディング表示用の変数
  bool _isLoading = false;
  // メール送信完了フラグ
  bool _isEmailSent = false;

  /// メールアドレス形式チェック（既存のログイン画面と同じ実装）
  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
  }

  /// パスワードリセットメール送信処理
  Future<void> _sendPasswordResetEmail() async {
    if (_email.trim().isEmpty) {
      _showErrorMessage('メールアドレスを入力してください');
      return;
    }

    if (!_isValidEmail(_email)) {
      _showErrorMessage('正しいメールアドレス形式で入力してください');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(authProvider.notifier).sendPasswordResetEmail(_email);

      // 送信成功
      setState(() => _isEmailSent = true);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('パスワードリセットメールを送信しました'),
            backgroundColor: AppColors.holdGreen,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'パスワードリセットメールの送信に失敗しました';

        // エラータイプに応じてメッセージを調整（既存の実装と統一）
        if (e is AuthenticationException) {
          errorMessage = e.message;
        } else if (e is ValidationException) {
          errorMessage = e.message;
        } else if (e.toString().contains('network-request-failed')) {
          errorMessage = 'ネットワークエラーです。接続を確認してください';
        }

        _showErrorMessage(errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// エラーメッセージ表示（既存の実装と統一）
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.holdRed,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// 再送信処理
  void _resendEmail() {
    setState(() => _isEmailSent = false);
    _sendPasswordResetEmail();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar相当（既存の実装と統一）
      appBar: AppBar(
        leading: _isLoading
          ? null
          : IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),

            // ロゴ（既存の実装と統一）
            const Center(child: AppLogo()),
            const SizedBox(height: 32),

            // タイトル
            Center(
              child: Text(
                'パスワードリセット',
                style: AppText.heading(size: 17),
              ),
            ),
            const SizedBox(height: 16),

            // 説明文
            Text(
              _isEmailSent 
                ? 'パスワードリセットメールを送信しました。\nメールに記載されたリンクから新しいパスワードを設定してください。'
                : 'ご登録のメールアドレスを入力してください。\nパスワードリセット用のメールをお送りします。',
              style: AppText.body(size: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            if (!_isEmailSent) ...[
              // メールアドレス入力欄（既存の実装と統一）
              Text(
                'メールアドレス',
                style: AppText.heading(size: 15),
              ),
              const SizedBox(height: 8),

              TextField(
                decoration: const InputDecoration(
                  hintText: "boulder@example.com",
                ),
                keyboardType: TextInputType.emailAddress,
                onChanged: (value) => _email = value,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 32),

              // 送信ボタン（既存の実装と統一）
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendPasswordResetEmail,
                  child: _isLoading 
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.onKabeBlue),
                        ),
                      )
                    : Text(
                        "パスワードリセットメールを送信",
                        style: AppText.label(
                          size: 14,
                          color: AppColors.onKabeBlue,
                        ),
                      ),
                ),
              ),
            ] else ...[
              // メール送信完了後の表示
              const SizedBox(height: 16),
              
              // 再送信ボタン
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _resendEmail,
                  style: OutlinedButton.styleFrom(
                    shape: const StadiumBorder(),
                    side: const BorderSide(color: AppColors.wareme),
                  ),
                  child: Text(
                    "メールを再送信",
                    style: AppText.label(size: 14),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ログイン画面に戻るボタン
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "ログイン画面に戻る",
                    style: AppText.label(
                      size: 14,
                      color: AppColors.onKabeBlue,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),

              // 注意事項
              Text(
                '注意事項：\n・メールが届かない場合は迷惑メールフォルダをご確認ください\n・リセット用のリンクの有効期限は1時間です',
                style: AppText.caption(size: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}