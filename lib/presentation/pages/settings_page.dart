import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../domain/entities/user.dart';
import '../providers/user_provider.dart';
import '../providers/auth_provider.dart';
import '../components/common/loading_widget.dart';
import '../components/common/error_widget.dart';
import '../../shared/utils/navigation_helper.dart';
import '../../shared/utils/url_launcher_helper.dart';
import '../theme/app_tokens.dart';
import '../theme/app_text.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('設定', style: AppText.heading(size: 17)),
      ),
      body: userState.when(
        data: (user) => _buildSettingsContent(context, ref, user),
        loading: () => const Center(
          child: LoadingWidget(message: 'ユーザー情報を読み込み中...'),
        ),
        error: (error, stackTrace) => Center(
          child: AppErrorWidget(
            message: 'ユーザー情報の取得に失敗しました',
            onRetry: () => ref.read(userProvider.notifier).loadCurrentUser(),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsContent(
      BuildContext context, WidgetRef ref, User? user) {
    if (user == null) {
      return const Center(child: Text('ユーザー情報が見つかりません'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildUserInfoSection(context, user),
        const SizedBox(height: 24),
        _buildPrivacySection(context),
        const SizedBox(height: 24),
        _buildSecuritySection(context, ref, user),
        const SizedBox(height: 24),
        _buildAboutSection(context),
        const SizedBox(height: 24),
        _buildDangerZoneSection(context, ref),
        const SizedBox(height: 36),
      ],
    );
  }

  /// セクション見出し（カードの外に置く小ラベル）
  Widget _buildSectionLabel(String label, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(label,
          style: AppText.caption(
            size: 11,
            weight: FontWeight.w700,
            color: color ?? AppColors.sunabokori,
          )),
    );
  }

  Widget _buildUserInfoSection(BuildContext context, User user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('アカウント情報'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage:
                      (user.userIconUrl != null && user.userIconUrl!.isNotEmpty)
                          ? ResizeImage(
                              CachedNetworkImageProvider(user.userIconUrl!),
                              width: 180)
                          : null,
                  child: (user.userIconUrl == null || user.userIconUrl!.isEmpty)
                      ? const Icon(Icons.person, size: 30)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.userName,
                          style:
                              AppText.body(size: 14, weight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(user.email, style: AppText.caption(size: 12)),
                      if (user.boulderingYearsExperience != null) ...[
                        const SizedBox(height: 4),
                        Text('ボルダリング歴: ${user.boulderingYearsExperience}年',
                            style: AppText.caption(size: 11)),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => NavigationHelper.toEditProfile(context),
                  icon: const Icon(Icons.edit),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('ユーザー管理'),
        Card(
          child: Column(
            children: [
              _buildSettingsItem(
                icon: Icons.block,
                title: 'ブロックしたユーザー',
                subtitle: 'ブロックしたユーザーの管理',
                onTap: () => NavigationHelper.toBlockList(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSecuritySection(BuildContext context, WidgetRef ref, User user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('セキュリティ設定'),
        Card(
          child: Column(
            children: [
              _buildSettingsItem(
                icon: Icons.email,
                title: 'メールアドレス変更',
                subtitle: '現在: ${user.email}',
                onTap: () => _showEmailChangeDialog(context, ref),
              ),
              _buildSettingsItem(
                icon: Icons.lock,
                title: 'パスワード変更',
                subtitle: 'アカウントのパスワードを変更',
                onTap: () => _showPasswordChangeDialog(context, ref),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('アプリについて'),
        Card(
          child: Column(
            children: [
              _buildSettingsItem(
                icon: Icons.info,
                title: 'アプリ情報',
                subtitle: 'バージョン情報とライセンス',
                onTap: () => _showAppInfo(context),
              ),
              _buildSettingsItem(
                icon: Icons.privacy_tip,
                title: 'プライバシーポリシー',
                subtitle: 'プライバシーポリシーを確認',
                onTap: () => UrlLauncherHelper.showPrivacyPolicy(context),
                isExternalLink: true, // 外部サイトへ遷移
              ),
              _buildSettingsItem(
                icon: Icons.description,
                title: '利用規約',
                subtitle: '利用規約を確認',
                onTap: () => UrlLauncherHelper.showTermsOfService(context),
                isExternalLink: true, // 外部サイトへ遷移
              ),
              _buildSettingsItem(
                icon: Icons.feedback,
                title: 'フィードバック',
                subtitle: 'アプリの改善提案・バグ報告',
                onTap: () => UrlLauncherHelper.showFeedbackForm(context),
                isExternalLink: true, // 外部サイトへ遷移（将来的に外部フォームへ）
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDangerZoneSection(BuildContext context, WidgetRef ref) {
    // 危険ゾーン: 枠・文字を holdRed で明示する
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('アカウント管理', color: AppColors.holdRed),
        Card(
          color: AppColors.setsuri,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card),
            side: const BorderSide(color: AppColors.holdRed),
          ),
          child: Column(
            children: [
              _buildSettingsItem(
                icon: Icons.logout,
                title: 'ログアウト',
                subtitle: 'アカウントからログアウト',
                iconColor: AppColors.holdRed,
                titleColor: AppColors.holdRed,
                onTap: () => _showLogoutDialog(context, ref),
              ),
              _buildSettingsItem(
                icon: Icons.delete_forever,
                title: '退会',
                subtitle: 'アカウントとすべてのデータを削除',
                iconColor: AppColors.holdRed,
                titleColor: AppColors.holdRed,
                onTap: () => _confirmAccountDeletion(context, ref),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    Color? titleColor,
    bool isExternalLink = false, // 外部リンクかどうかのフラグ（デフォルト: false）
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.sunabokori),
      title: Text(title,
          style: AppText.body(
            size: 14,
            weight: FontWeight.w500,
            color: titleColor ?? AppColors.chalk,
          )),
      subtitle: Text(subtitle, style: AppText.caption(size: 12)),
      trailing: isExternalLink
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('外部サイト', style: AppText.caption(size: 11)),
                const SizedBox(width: 4),
                const Icon(Icons.open_in_new,
                    size: 18, color: AppColors.sunabokori),
              ],
            )
          : const Icon(Icons.chevron_right, color: AppColors.sunabokori),
      onTap: onTap,
    );
  }

  // --- 各種ダイアログ・処理 ---

  void _showAppInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('アプリ情報', style: AppText.heading(size: 16)),
        // バージョンはビルド情報から動的取得（旧実装はハードコードで実際の版とズレていた）
        content: FutureBuilder<PackageInfo>(
          future: PackageInfo.fromPlatform(),
          builder: (context, snapshot) {
            final version = snapshot.data?.version ?? '-';
            final build = snapshot.data?.buildNumber ?? '-';
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('イワノボリタイ',
                    style: AppText.body(size: 14, weight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text('バージョン: $version ($build)',
                    style: AppText.body(size: 13)),
                const SizedBox(height: 16),
                Text('© 2025 イワノボリタイ開発チーム', style: AppText.caption(size: 12)),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    NavigationHelper.showConfirmDialog(
      context: context,
      title: 'ログアウト',
      message: 'アカウントからログアウトしますか？',
      confirmText: 'ログアウト',
    ).then((confirmed) async {
      if (!confirmed) return;
      try {
        await ref.read(authProvider.notifier).logout();
        if (context.mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } catch (e) {
        if (context.mounted) {
          NavigationHelper.showErrorDialog(
            context: context,
            message: 'ログアウトに失敗しました: ${e.toString()}',
          );
        }
      }
    });
  }

  void _confirmAccountDeletion(BuildContext context, WidgetRef ref) {
    NavigationHelper.showConfirmDialog(
      context: context,
      title: '最終確認',
      message: 'アカウントの削除を実行しますか？\nこの操作は絶対に元に戻せません。',
      confirmText: '削除を実行',
      cancelText: 'キャンセル',
    ).then((confirmed) async {
      if (confirmed && context.mounted) {
        _showPasswordDialog(context, ref);
      }
    });
  }

  void _showPasswordDialog(BuildContext context, WidgetRef ref) async {
    final password = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _PasswordDialog(),
    );
    if (password != null && password.isNotEmpty && context.mounted) {
      await _executeAccountDeletion(context, ref, password);
    }
  }

  Future<void> _executeAccountDeletion(
    BuildContext context,
    WidgetRef ref,
    String password,
  ) async {
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('パスワードを入力してください'),
          backgroundColor: AppColors.holdRed,
        ),
      );
      return;
    }

    // プログレスダイアログを表示
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => WillPopScope(
        onWillPop: () async => false,
        child: const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('アカウントを削除中...'),
            ],
          ),
        ),
      ),
    );

    try {
      // 削除処理を実行
      await ref.read(authProvider.notifier).deleteAccount(password: password);

      // 成功した場合
      if (context.mounted) {
        // プログレスダイアログを閉じる
        Navigator.of(context).pop();

        // 成功メッセージを表示
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('アカウントを削除しました'),
            backgroundColor: AppColors.holdGreen,
            duration: Duration(seconds: 2),
          ),
        );

        // 少し待ってから最初の画面に戻る
        await Future.delayed(const Duration(milliseconds: 500));
        if (context.mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    } catch (e) {
      // エラーが発生した場合
      if (context.mounted) {
        // プログレスダイアログを閉じる
        Navigator.of(context).pop();

        // エラーダイアログを表示
        NavigationHelper.showErrorDialog(
          context: context,
          message: _toFriendlyMessage(e),
        );
      }
    }
  }

  void _showEmailChangeDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _EmailChangeDialog(),
    );

    if (result == null || !context.mounted) return;

    final email = result['email'] ?? '';
    final password = result['password'] ?? '';
    await _executeEmailChange(context, ref, email, password);
  }

  /// ★ 重要：ここでは Cloud SQL を更新しない（未検証のため）
  Future<void> _executeEmailChange(
    BuildContext context,
    WidgetRef ref,
    String newEmail,
    String currentPassword,
  ) async {
    if (newEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('メールアドレスを入力してください')),
      );
      return;
    }
    if (currentPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('現在のパスワードを入力してください')),
      );
      return;
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(newEmail)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('正しいメールアドレス形式で入力してください')),
      );
      return;
    }

    try {
      // 1) Firebase Auth に認証メール送信（再認証付き）→ 強制ログアウト
      await ref.read(authProvider.notifier).updateEmailInFirebaseAuth(
            newEmail: newEmail,
            currentPassword: currentPassword,
          );

      // 2) Cloud SQL はここでは更新しない。次回ログイン成功時に UID で同期される。
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '確認メールを送信しました。リンクをクリックして変更してください。\n'
              'リンクをクリック後は、新しいメールアドレス＋パスワードでログインしてください。',
            ),
            duration: Duration(seconds: 8),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('メールアドレス更新に失敗しました: ${e.toString()}')),
        );
      }
    }
  }

  void _showPasswordChangeDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _PasswordChangeDialog(),
    );

    if (result == null || !context.mounted) return;

    final current = result['current'] ?? '';
    final newPassword = result['new'] ?? '';
    final confirm = result['confirm'] ?? '';
    await _executePasswordChange(context, ref, current, newPassword, confirm);
  }

  Future<void> _executePasswordChange(
    BuildContext context,
    WidgetRef ref,
    String currentPassword,
    String newPassword,
    String confirmPassword,
  ) async {
    if (currentPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('現在のパスワードを入力してください')),
      );
      return;
    }
    if (newPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('新しいパスワードを入力してください')),
      );
      return;
    }
    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('パスワードは6文字以上で入力してください')),
      );
      return;
    }
    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('新しいパスワードが一致しません')),
      );
      return;
    }
    if (currentPassword == newPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('新しいパスワードは現在のパスワードと異なるものを設定してください')),
      );
      return;
    }

    try {
      await ref.read(authProvider.notifier).changePassword(
            currentPassword: currentPassword,
            newPassword: newPassword,
          );

      // パスワード変更成功 → 強制ログアウト
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'パスワードを変更しました。\n'
              '新しいパスワードでログインしてください。',
            ),
            duration: Duration(seconds: 5),
            backgroundColor: AppColors.holdGreen,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        // エラーメッセージを改善
        String errorMessage = 'パスワード変更に失敗しました';
        final errorString = e.toString();

        if (errorString.contains('現在のパスワードが間違っています')) {
          errorMessage = '現在のパスワードが間違っています';
        } else if (errorString.contains('requires-recent-login')) {
          errorMessage = 'セキュリティのため、再度ログインしてから操作してください';
        } else if (errorString.contains('weak-password')) {
          errorMessage = 'パスワードが弱すぎます。もっと強力なパスワードを設定してください';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.holdRed,
          ),
        );
      }
    }
  }

  String _toFriendlyMessage(Object error) {
    final message = error.toString();
    if (message.contains('パスワードが正しくありません')) {
      return 'パスワードが正しくありません';
    } else if (message.contains('試行回数が多すぎます')) {
      return '試行回数が多すぎます。しばらく待ってから再度お試しください';
    } else if (message.contains('データベースからのユーザー削除に失敗しました')) {
      return 'データベースからのユーザー削除に失敗しました。再度お試しください';
    } else {
      return 'アカウントの削除に失敗しました: $error';
    }
  }
}

/// --- ダイアログ群（省略せず掲載） ---

class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog();

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _controller = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('本人確認', style: AppText.heading(size: 16)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'セキュリティのため、パスワードを再入力してください。',
              style: AppText.body(size: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              obscureText: !_isPasswordVisible,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'パスワード',
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),
              onSubmitted: (_) =>
                  Navigator.of(context).pop(_controller.text.trim()),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.holdRed,
            foregroundColor: AppColors.onHoldRed,
            textStyle: AppText.label(size: 14),
          ),
          child: const Text('削除を実行'),
        ),
      ],
    );
  }
}

class _EmailChangeDialog extends StatefulWidget {
  const _EmailChangeDialog();

  @override
  State<_EmailChangeDialog> createState() => _EmailChangeDialogState();
}

class _EmailChangeDialogState extends State<_EmailChangeDialog> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('メールアドレス変更', style: AppText.heading(size: 16)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'セキュリティのため、新しいメールアドレスと現在のパスワードを入力してください。',
              style: AppText.body(size: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.wareme,
                border: Border.all(color: AppColors.holdRed),
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning,
                          color: AppColors.holdRed, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '重要なお知らせ',
                        style: AppText.body(
                          size: 13,
                          weight: FontWeight.w700,
                          color: AppColors.holdRed,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '認証メールの送信を押下すると、強制的にログアウトされます。',
                    style: AppText.body(size: 13),
                  ),
                  Text(
                    '認証メールの認証を押下したあと、新しいメールアドレスでログインし直してください。',
                    style: AppText.body(size: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: '新しいメールアドレス',
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                labelText: '現在のパスワード（再認証用）',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: () {
            final email = _emailController.text.trim();
            final password = _passwordController.text.trim();
            Navigator.of(context).pop({'email': email, 'password': password});
          },
          child: const Text('変更'),
        ),
      ],
    );
  }
}

class _PasswordChangeDialog extends StatefulWidget {
  const _PasswordChangeDialog();

  @override
  State<_PasswordChangeDialog> createState() => _PasswordChangeDialogState();
}

class _PasswordChangeDialogState extends State<_PasswordChangeDialog> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('パスワード変更', style: AppText.heading(size: 16)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'パスワードを変更します。以下を入力してください。',
              style: AppText.body(size: 14),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.wareme,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: AppColors.holdRed),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber,
                      color: AppColors.holdRed, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '変更後は自動的にログアウトされます。\n新しいパスワードで再ログインしてください。',
                      style:
                          AppText.caption(size: 12, color: AppColors.holdRed),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _currentPasswordController,
              obscureText: !_isCurrentPasswordVisible,
              decoration: InputDecoration(
                labelText: '現在のパスワード',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isCurrentPasswordVisible
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _isCurrentPasswordVisible = !_isCurrentPasswordVisible;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _newPasswordController,
              obscureText: !_isNewPasswordVisible,
              decoration: InputDecoration(
                labelText: '新しいパスワード',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isNewPasswordVisible
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _isNewPasswordVisible = !_isNewPasswordVisible;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              obscureText: !_isConfirmPasswordVisible,
              decoration: InputDecoration(
                labelText: '新しいパスワード（確認）',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isConfirmPasswordVisible
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '※パスワードは6文字以上で入力してください',
              style: AppText.caption(size: 12),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: () {
            final current = _currentPasswordController.text.trim();
            final newPass = _newPasswordController.text.trim();
            final confirm = _confirmPasswordController.text.trim();
            Navigator.of(context).pop({
              'current': current,
              'new': newPass,
              'confirm': confirm,
            });
          },
          child: const Text('変更'),
        ),
      ],
    );
  }
}
