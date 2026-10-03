import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/competition.dart';
import '../../../shared/utils/navigation_helper.dart';
import '../../components/common/error_widget.dart';
import '../../components/common/loading_widget.dart';
import '../../components/competition/competition_card.dart';
import '../../providers/competition_providers.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_text.dart';
import '../../theme/app_tokens.dart';
import 'competition_form_page.dart';

/// 開催者の管理画面（「コンペを開催する」）
///
/// 役割:
/// - 「新しいコンペを開催する」から設定画面へ（期間 → 課題番号 → 無料／有料 → 確認）
/// - 自分（管理ジム）のコンペ一覧。開催中 → 開催前 → 終了 の順。各コンペを「編集する」「順位を見る」
/// - ジム管理者（user.managedGymId）でなければ案内だけを出す
class HostCompetitionsPage extends ConsumerWidget {
  const HostCompetitionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isManager = user?.isGymManager ?? false;
    final competitions = ref.watch(hostedCompetitionsProvider);

    return Scaffold(
      appBar: AppBar(title: Text('コンペを開催する', style: AppText.heading(size: 17))),
      body: !isManager
          ? const _NotManagerNotice()
          : competitions.when(
              loading: () => const LoadingWidget(message: '開催中のコンペを読み込み中...'),
              error: (e, _) => AppErrorWidget(
                message: competitionErrorMessage(e),
                onRetry: () => ref.invalidate(hostedCompetitionsProvider),
              ),
              data: (items) => RefreshIndicator(
                onRefresh: () async => ref.refresh(hostedCompetitionsProvider.future),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    SizedBox(
                      height: 49,
                      child: ElevatedButton.icon(
                        onPressed: () => _openForm(context, null),
                        icon: const Icon(Icons.add),
                        label: const Text('新しいコンペを開催する'),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('開催したコンペ', style: AppText.caption(size: 11, weight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    if (items.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.setsuri,
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          border: Border.all(color: AppColors.wareme),
                        ),
                        child: Text(
                          'まだコンペを開催していません。\n上のボタンから期間と課題番号を決めて開催できます。',
                          style: AppText.caption(size: 12),
                        ),
                      )
                    else
                      for (final c in items)
                        CompetitionCard(
                          competition: c,
                          onTap: () => NavigationHelper.toCompetitionDetail(context, c.id, competition: c),
                          actions: [
                            OutlinedButton.icon(
                              onPressed: () => _openForm(context, c),
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              label: const Text('編集する'),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => NavigationHelper.toCompetitionLeaderboard(context, c.id,
                                  competition: c),
                              icon: const Icon(Icons.leaderboard_outlined, size: 18),
                              label: const Text('順位を見る'),
                            ),
                          ],
                        ),
                  ],
                ),
              ),
            ),
    );
  }

  /// 設定画面（新規 or 編集）を開き、完了したら案内を出す
  Future<void> _openForm(BuildContext context, Competition? existing) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CompetitionFormPage(existing: existing)),
    );
    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(existing == null ? 'コンペを開催しました' : 'コンペを更新しました')),
      );
    }
  }
}

class _NotManagerNotice extends StatelessWidget {
  const _NotManagerNotice();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 48, color: AppColors.sunabokori),
            const SizedBox(height: 12),
            Text('コンペを開催できるのはジム管理者のみです', style: AppText.heading(size: 15)),
            const SizedBox(height: 6),
            Text(
              'ジム管理者の登録は運営が行います。登録をご希望の方は運営までご連絡ください。',
              textAlign: TextAlign.center,
              style: AppText.caption(size: 12),
            ),
          ],
        ),
      ),
    );
  }
}
