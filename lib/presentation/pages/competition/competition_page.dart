import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/utils/navigation_helper.dart';
import '../../components/common/app_logo.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_text.dart';
import '../../theme/app_tokens.dart';
import '../login_or_signup_page.dart';

/// 「コンペ」タブ（デモ機能）
///
/// 役割:
/// - 未ログインなら案内（通知タブと同じ方式。ログイン画面へ）
/// - ログイン済みなら 3 つの入口を出す
///   1. コンペに参加する（開催中のコンペ一覧）
///   2. 参加中のコンペの順位表を見る
///   3. コンペを開催する（ジム管理者 = user.managedGymId がある人にだけ表示）
///
/// クリーンアーキテクチャにおける位置づけ:
/// - Presentation 層の View（入口だけ。中身は各ページ）
class CompetitionPage extends ConsumerWidget {
  const CompetitionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(title: Text('コンペ', style: AppText.heading(size: 17))),
      body: isLoggedIn ? const _CompetitionMenu() : const _UnloggedCompetitionPrompt(),
    );
  }
}

class _CompetitionMenu extends ConsumerWidget {
  const _CompetitionMenu();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isManager = user?.isGymManager ?? false;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 見出しカード
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.setsuri,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.wareme),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.emoji_events_outlined, color: AppColors.kabeBlue),
                  const SizedBox(width: 8),
                  Text('ジムのコンペに参加しよう', style: AppText.heading(size: 16)),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '開催中のコンペに参加して、登った課題を記録。順位はライブで更新されます。',
                style: AppText.caption(size: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _MenuButton(
          icon: Icons.flag_outlined,
          title: 'コンペに参加する',
          subtitle: '開催中のコンペを探して参加する',
          onTap: () => NavigationHelper.toCompetitionList(context),
        ),
        const SizedBox(height: 12),
        _MenuButton(
          icon: Icons.leaderboard_outlined,
          title: '参加中のコンペの順位表を見る',
          subtitle: '参加しているコンペの順位と完登の記録',
          onTap: () => NavigationHelper.toCompetitionJoined(context),
        ),
        if (isManager) ...[
          const SizedBox(height: 12),
          _MenuButton(
            icon: Icons.campaign_outlined,
            title: 'コンペを開催する',
            subtitle: '管理しているジムのコンペを開催・編集する',
            accent: true,
            onTap: () => NavigationHelper.toCompetitionHost(context),
          ),
        ],
      ],
    );
  }
}

/// 入口ボタン（カード型）
class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.accent = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.setsuri,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: accent ? AppColors.kabeBlue : AppColors.wareme),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent ? AppColors.kabeBlue : AppColors.wareme,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accent ? AppColors.onKabeBlue : AppColors.chalk),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppText.heading(size: 15)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppText.caption(size: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.sunabokori),
            ],
          ),
        ),
      ),
    );
  }
}

/// 未ログイン時の案内（通知タブと同じ構成）
class _UnloggedCompetitionPrompt extends StatelessWidget {
  const _UnloggedCompetitionPrompt();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.setsuri,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.wareme),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: AppLogo()),
            const SizedBox(height: 16),
            Text('ログインするとコンペに参加できます', style: AppText.heading(size: 15)),
            const SizedBox(height: 4),
            Text(
              'ジムが開催するコンペに参加して、登った課題を記録。順位表はライブで更新されます．',
              style: AppText.caption(size: 12),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 49,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginOrSignUpPage(),
                    ),
                  );
                },
                child: Text(
                  '新規登録 / ログイン',
                  style: AppText.label(size: 14, color: AppColors.onKabeBlue),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
