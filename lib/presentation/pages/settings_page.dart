import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../domain/entities/user.dart';
import '../providers/user_provider.dart';
import '../providers/auth_provider.dart';
import '../../domain/services/auth_service.dart';
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
                      Text(user.email ?? 'メールアドレス未登録',
                          style: AppText.caption(size: 12)),
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
    final provider = ref.read(authProvider.notifier).currentProviderKind;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('アカウント'),
        Card(
          child: Column(
            children: [
              // ログイン方法（Google / Apple）。退会時の本人確認も同じ方法で行う
              ListTile(
                leading: Icon(
                  provider == AuthProviderKind.apple ? Icons.apple : Icons.account_circle,
                  color: AppColors.sunabokori,
                ),
                title: Text('ログイン方法',
                    style: AppText.body(
                        size: 14, weight: FontWeight.w500, color: AppColors.chalk)),
                subtitle: Text(
                  provider == null ? '不明' : '${provider.displayName} アカウントでログイン中',
                  style: AppText.caption(size: 12),
                ),
              ),
              _buildSettingsItem(
                icon: Icons.email,
                title: 'メールアドレス（任意）',
                subtitle: user.email == null
                    ? '未登録。お知らせを受け取りたい場合に登録できます'
                    : '登録済み: ${user.email}',
                onTap: () => _showEmailDialog(context, ref, user),
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
    final provider = ref.read(authProvider.notifier).currentProviderKind;
    NavigationHelper.showConfirmDialog(
      context: context,
      title: '最終確認',
      message: 'アカウントの削除を実行しますか？\nこの操作は絶対に元に戻せません。\n\n'
          '本人確認のため、続けて ${provider?.displayName ?? 'ログイン時'} のログイン画面が表示されます。',
      confirmText: '削除を実行',
      cancelText: 'キャンセル',
    ).then((confirmed) async {
      if (confirmed && context.mounted) {
        await _executeAccountDeletion(context, ref);
      }
    });
  }

  Future<void> _executeAccountDeletion(
    BuildContext context,
    WidgetRef ref,
  ) async {
    // プログレスダイアログを表示（再認証シートの裏で待つ）
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
      // 本人確認（プロバイダで再認証）→ DB → Firebase の順に削除
      final deleted = await ref.read(authProvider.notifier).deleteAccount();

      if (!context.mounted) return;
      Navigator.of(context).pop(); // プログレスを閉じる

      if (!deleted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('本人確認がキャンセルされたため、削除しませんでした')),
        );
        return;
      }

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
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // プログレスを閉じる
        NavigationHelper.showErrorDialog(
          context: context,
          message: _toFriendlyMessage(e),
        );
      }
    }
  }

  /// 通知用メールアドレスの登録・変更・削除
  Future<void> _showEmailDialog(
      BuildContext context, WidgetRef ref, User user) async {
    // 確認リンクの押下は DB 側だけで完結するので、開く前に最新の登録状態へ揃える
    await ref.read(userProvider.notifier).refreshQuietly();
    if (!context.mounted) return;
    final current = ref.read(userProvider).valueOrNull ?? user;
    final result = await showDialog<_EmailDialogResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _EmailRegisterDialog(currentEmail: current.email),
    );
    if (result == null || !context.mounted) return;

    try {
      if (result.remove) {
        await ref.read(authProvider.notifier).removeEmail();
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('メールアドレスを削除しました')),
        );
        return;
      }

      final outcome =
          await ref.read(authProvider.notifier).registerEmail(result.email);
      if (!context.mounted) return;
      switch (outcome) {
        case EmailRegistrationResult.registered:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('このメールアドレスは登録済みです'),
              backgroundColor: AppColors.holdGreen,
            ),
          );
        case EmailRegistrationResult.verificationSent:
          // 正常な案内なので「エラー」ダイアログではなく通常のダイアログで出す
          await _showInfoDialog(
            context,
            title: '確認メールを送信しました',
            message: '「${result.email}」宛てに確認メールを送りました。\n'
                'メール内のリンクを開くと登録が完了します（アプリでの操作は不要です）。\n'
                '登録後、この設定画面を開き直すと反映されます。\n\n'
                '届かない場合は迷惑メールフォルダも確認してください。',
          );
      }
    } catch (e) {
      if (context.mounted) {
        NavigationHelper.showErrorDialog(
          context: context,
          message: _emailErrorMessage(e),
        );
      }
    }
  }

  Future<void> _showInfoDialog(BuildContext context,
      {required String title, required String message}) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: AppText.heading(size: 16)),
        content: Text(message, style: AppText.body(size: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _emailErrorMessage(Object e) {
    final s = e.toString();
    if (s.contains('EMAIL_ALREADY_REGISTERED') || s.contains('別のアカウントで登録済み')) {
      return 'このメールアドレスは別のアカウントで登録済みです。';
    }
    if (s.contains('INVALID_EMAIL_FORMAT') || s.contains('形式')) {
      return '正しいメールアドレス形式で入力してください。';
    }
    if (s.contains('TOO_MANY_REQUESTS')) {
      return '確認メールを送ったばかりです。1分ほど待ってからもう一度お試しください。';
    }
    if (s.contains('EMAIL_VERIFICATION_UNAVAILABLE')) {
      return 'メールアドレス登録は現在準備中です。';
    }
    if (s.contains('MAIL_SEND_FAILED')) {
      return '確認メールを送信できませんでした。時間をおいてお試しください。';
    }
    if (s.contains('network')) {
      return AuthNotifier.networkRequestFailedMessage;
    }
    return 'メールアドレスの登録に失敗しました: $e';
  }

  String _toFriendlyMessage(Object error) {
    final message = error.toString();
    if (message.contains('requires-recent-login')) {
      return 'セキュリティのため、もう一度ログインしてから操作してください';
    } else if (message.contains('network')) {
      return AuthNotifier.networkRequestFailedMessage;
    } else if (message.contains('データベースからのユーザー削除に失敗しました')) {
      return 'データベースからのユーザー削除に失敗しました。再度お試しください';
    } else {
      return 'アカウントの削除に失敗しました: $error';
    }
  }
}

/// --- ダイアログ ---

/// メール登録ダイアログの結果
class _EmailDialogResult {
  const _EmailDialogResult.register(this.email) : remove = false;
  const _EmailDialogResult.remove()
      : email = '',
        remove = true;

  final String email;
  final bool remove;
}

/// 通知用メールアドレスの登録・変更・削除ダイアログ
///
/// 認証には使わないので、パスワード等の再入力は求めない。
/// 登録は確認メールのリンク押下で本人確認してから確定する（AuthNotifier.registerEmail）
class _EmailRegisterDialog extends StatefulWidget {
  const _EmailRegisterDialog({required this.currentEmail});

  final String? currentEmail;

  @override
  State<_EmailRegisterDialog> createState() => _EmailRegisterDialogState();
}

class _EmailRegisterDialogState extends State<_EmailRegisterDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.currentEmail ?? '');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final email = _controller.text.trim();
    if (email.isEmpty) return;
    Navigator.of(context).pop(_EmailDialogResult.register(email));
  }

  @override
  Widget build(BuildContext context) {
    final registered = widget.currentEmail != null;
    return AlertDialog(
      title: Text(registered ? 'メールアドレスの変更' : 'メールアドレスの登録',
          style: AppText.heading(size: 16)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'お知らせの受け取りに使います（任意）。\n'
              '入力したアドレスに確認メールを送り、メール内のリンクを開くと登録が完了します。',
              style: AppText.body(size: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'メールアドレス',
                hintText: 'boulder@example.com',
              ),
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        if (registered)
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(const _EmailDialogResult.remove()),
            child: Text('登録を削除',
                style: AppText.label(size: 13, color: AppColors.holdRed)),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(registered ? '変更する' : '登録する'),
        ),
      ],
    );
  }
}
