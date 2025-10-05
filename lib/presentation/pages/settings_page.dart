import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user.dart';
import '../providers/user_provider.dart';
import '../providers/auth_provider.dart';
import '../components/common/loading_widget.dart';
import '../components/common/error_widget.dart';
import '../../shared/utils/navigation_helper.dart';
import '../../shared/utils/url_launcher_helper.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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
        _buildSecuritySection(context, ref, user),
        const SizedBox(height: 24),
        _buildAboutSection(context),
        const SizedBox(height: 24),
        _buildDangerZoneSection(context, ref),
      ],
    );
  }

  Widget _buildUserInfoSection(BuildContext context, User user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('アカウント情報',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    )),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage:
                      (user.userIconUrl != null && user.userIconUrl!.isNotEmpty)
                          ? NetworkImage(user.userIconUrl!)
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
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(user.email,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.grey[600])),
                      if (user.boulderingYearsExperience != null) ...[
                        const SizedBox(height: 4),
                        Text('ボルダリング歴: ${user.boulderingYearsExperience}年',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.grey[600])),
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
          ],
        ),
      ),
    );
  }

  Widget _buildSecuritySection(BuildContext context, WidgetRef ref, User user) {
    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('セキュリティ設定',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      )),
            ),
          ),
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
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('アプリについて',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      )),
            ),
          ),
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
    );
  }

  Widget _buildDangerZoneSection(BuildContext context, WidgetRef ref) {
    return Card(
      color: Colors.red[50],
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('アカウント管理',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.red[800],
                      )),
            ),
          ),
          _buildSettingsItem(
            icon: Icons.logout,
            title: 'ログアウト',
            subtitle: 'アカウントからログアウト',
            iconColor: Colors.red[600],
            titleColor: Colors.red[800],
            onTap: () => _showLogoutDialog(context, ref),
          ),
          _buildSettingsItem(
            icon: Icons.delete_forever,
            title: '退会',
            subtitle: 'アカウントとすべてのデータを削除',
            iconColor: Colors.red[600],
            titleColor: Colors.red[800],
            onTap: () => _confirmAccountDeletion(context, ref),
          ),
        ],
      ),
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
      leading: Icon(icon, color: iconColor),
      title: Text(title,
          style: TextStyle(
            color: titleColor,
            fontWeight: FontWeight.w500,
          )),
      subtitle: Text(subtitle),
      trailing: isExternalLink
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '外部サイト',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.open_in_new, size: 18, color: Colors.grey[600]),
              ],
            )
          : const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  // --- 各種ダイアログ・処理 ---

  void _showAppInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('アプリ情報'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('イワノボリタイ'),
            SizedBox(height: 8),
            Text('バージョン: 1.0.0'), // リリースごとに手動更新
            SizedBox(height: 8),
            SizedBox(height: 16),
            Text('© 2025 イワノボリタイ開発チーム'),
          ],
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
          backgroundColor: Colors.orange,
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
            backgroundColor: Colors.green,
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
            backgroundColor: Colors.green,
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
            backgroundColor: Colors.red,
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
      title: const Text('本人確認'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'セキュリティのため、パスワードを再入力してください。',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              obscureText: !_isPasswordVisible,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'パスワード',
                border: const OutlineInputBorder(),
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
            backgroundColor: Colors.red[600],
            foregroundColor: Colors.white,
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
      title: const Text('メールアドレス変更'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'セキュリティのため、新しいメールアドレスと現在のパスワードを入力してください。',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                border: Border.all(color: Colors.orange.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange, size: 20),
                      SizedBox(width: 8),
                      Text(
                        '重要なお知らせ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '認証メールの送信を押下すると、強制的にログアウトされます。',
                    style: TextStyle(fontSize: 13),
                  ),
                  Text(
                    '認証メールの認証を押下したあと、新しいメールアドレスでログインし直してください。',
                    style: TextStyle(fontSize: 13),
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
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                labelText: '現在のパスワード（再認証用）',
                border: const OutlineInputBorder(),
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
      title: const Text('パスワード変更'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'パスワードを変更します。以下を入力してください。',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '変更後は自動的にログアウトされます。\n新しいパスワードで再ログインしてください。',
                      style: TextStyle(fontSize: 12, color: Colors.orange),
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
                border: const OutlineInputBorder(),
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
                border: const OutlineInputBorder(),
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
                border: const OutlineInputBorder(),
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
            const Text(
              '※パスワードは6文字以上で入力してください',
              style: TextStyle(fontSize: 12, color: Colors.grey),
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
