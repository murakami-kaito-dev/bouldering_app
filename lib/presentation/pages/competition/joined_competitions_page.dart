import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/utils/navigation_helper.dart';
import '../../components/common/error_widget.dart';
import '../../components/common/loading_widget.dart';
import '../../components/competition/competition_card.dart';
import '../../providers/competition_providers.dart';
import '../../theme/app_text.dart';
import '../../theme/app_tokens.dart';

/// 参加中のコンペ一覧（「参加中のコンペの順位表を見る」）
///
/// 役割:
/// - 自分が参加しているコンペを、開催中 → 開催前 → 終了 の順に表示
/// - 各コンペの「順位を見る」で順位表へ。「確認する」で設定内容へ
class JoinedCompetitionsPage extends ConsumerWidget {
  const JoinedCompetitionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final competitions = ref.watch(joinedCompetitionsProvider);

    return Scaffold(
      appBar: AppBar(title: Text('参加中のコンペ', style: AppText.heading(size: 17))),
      body: competitions.when(
        loading: () => const LoadingWidget(message: '参加中のコンペを読み込み中...'),
        error: (e, _) => AppErrorWidget(
          message: competitionErrorMessage(e),
          onRetry: () => ref.invalidate(joinedCompetitionsProvider),
        ),
        data: (items) => RefreshIndicator(
          onRefresh: () async => ref.refresh(joinedCompetitionsProvider.future),
          child: items.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    const SizedBox(height: 80),
                    const Icon(Icons.leaderboard_outlined, size: 64, color: AppColors.sunabokori),
                    const SizedBox(height: 16),
                    const Text(
                      '参加中のコンペはありません',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: AppColors.sunabokori),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '開催中のコンペに参加すると、ここから順位表を見られます',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AppColors.sunabokori),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: OutlinedButton(
                        onPressed: () => NavigationHelper.toCompetitionList(context),
                        child: const Text('開催中のコンペを見る'),
                      ),
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
                      onTap: () => NavigationHelper.toCompetitionLeaderboard(context, c.id, competition: c),
                      actions: [
                        OutlinedButton(
                          onPressed: () =>
                              NavigationHelper.toCompetitionDetail(context, c.id, competition: c),
                          child: const Text('確認する'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => NavigationHelper.toCompetitionLeaderboard(context, c.id,
                              competition: c),
                          icon: const Icon(Icons.leaderboard_outlined, size: 18),
                          label: const Text('順位を見る'),
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
