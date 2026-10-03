import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/competition.dart';
import '../../../shared/utils/navigation_helper.dart';
import '../../components/common/error_widget.dart';
import '../../components/common/loading_widget.dart';
import '../../components/competition/competition_card.dart';
import '../../providers/competition_providers.dart';
import '../../theme/app_text.dart';
import '../../theme/app_tokens.dart';

/// 開催中のコンペ一覧（「コンペに参加する」）
///
/// 役割:
/// - 全国の開催中コンペを表示（ログイン中の人のホームジムのコンペが先頭）
/// - 各コンペに「確認する」「参加する」「順位を見る」
/// - 参加すると順位表へ進む（本人の位置までスクロール）
class CompetitionListPage extends ConsumerWidget {
  const CompetitionListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final competitions = ref.watch(activeCompetitionsProvider);

    return Scaffold(
      appBar: AppBar(title: Text('開催中のコンペ', style: AppText.heading(size: 17))),
      body: competitions.when(
        loading: () => const LoadingWidget(message: 'コンペを読み込み中...'),
        error: (e, _) => AppErrorWidget(
          message: competitionErrorMessage(e),
          onRetry: () => ref.invalidate(activeCompetitionsProvider),
        ),
        data: (items) => RefreshIndicator(
          onRefresh: () async => ref.refresh(activeCompetitionsProvider.future),
          child: items.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 96),
                    Icon(Icons.emoji_events_outlined, size: 64, color: AppColors.sunabokori),
                    SizedBox(height: 16),
                    Text(
                      '開催中のコンペはありません',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: AppColors.sunabokori),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'ジムがコンペを開催するとここに表示されます',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AppColors.sunabokori),
                    ),
                  ],
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final c = items[i];
                    return CompetitionCard(
                      competition: c,
                      onTap: () => NavigationHelper.toCompetitionDetail(context, c.id, competition: c),
                      actions: [
                        OutlinedButton(
                          onPressed: () =>
                              NavigationHelper.toCompetitionDetail(context, c.id, competition: c),
                          child: const Text('確認する'),
                        ),
                        ElevatedButton(
                          onPressed: c.isJoined ? null : () => joinCompetitionFlow(context, ref, c),
                          child: Text(c.isJoined ? '参加済み' : '参加する'),
                        ),
                        OutlinedButton(
                          onPressed: () => NavigationHelper.toCompetitionLeaderboard(context, c.id,
                              competition: c),
                          child: const Text('順位を見る'),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ),
    );
  }
}

/// 参加の共通フロー（一覧・確認画面から使う）
///
/// 確認ダイアログ → 参加 API → 順位表へ（本人の位置までスクロール）
Future<void> joinCompetitionFlow(BuildContext context, WidgetRef ref, Competition c) async {
  final ok = await NavigationHelper.showConfirmDialog(
    context: context,
    title: 'コンペに参加する',
    message: '${c.displayTitle}（${c.gymName}）に参加します。\n'
        '期間: ${c.periodDisplay}\n課題: ${c.problemRangeDisplay}\n参加料: ${c.feeDisplay}'
        '${c.isFree ? '' : '\n※ 参加料の決済は未対応です（お試し期間中は無料で参加できます）'}',
    confirmText: '参加する',
  );
  if (!ok || !context.mounted) return;

  try {
    final joined = await ref.read(competitionActionsProvider).join(c.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${joined.displayTitle} に参加しました')),
    );
    await NavigationHelper.toCompetitionLeaderboard(context, joined.id, competition: joined);
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(competitionErrorMessage(e))),
    );
  }
}
