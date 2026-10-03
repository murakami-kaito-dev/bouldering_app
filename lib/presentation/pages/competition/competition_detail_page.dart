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
import 'competition_list_page.dart';

/// コンペの確認画面（「確認する」）
///
/// 役割:
/// - ジムが設定した期間・課題番号・有料／無料・参加料を見せる
/// - 末尾の「参加する」は一覧の「参加する」と同じ動作（参加 → 順位表へ）
/// - 参加済みなら「順位を見る」
class CompetitionDetailPage extends ConsumerWidget {
  const CompetitionDetailPage({super.key, required this.competitionId, this.initial});

  final int competitionId;

  /// 呼び出し元が持っていたコンペ（取得完了まで表示に使う）
  final Competition? initial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(competitionDetailProvider(competitionId));
    final c = detail.valueOrNull ?? initial;

    return Scaffold(
      appBar: AppBar(title: Text('コンペの確認', style: AppText.heading(size: 17))),
      body: c == null
          ? detail.when(
              loading: () => const LoadingWidget(message: 'コンペを読み込み中...'),
              error: (e, _) => AppErrorWidget(
                message: competitionErrorMessage(e),
                onRetry: () => ref.invalidate(competitionDetailProvider(competitionId)),
              ),
              data: (_) => const SizedBox.shrink(),
            )
          : _DetailBody(competition: c),
      bottomNavigationBar: c == null ? null : _BottomAction(competition: c),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.competition});

  final Competition competition;

  @override
  Widget build(BuildContext context) {
    final c = competition;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            CompetitionStatusTape(status: c.status),
            const SizedBox(width: 8),
            Text('${c.participantCount} 人参加', style: AppText.caption(size: 12)),
          ],
        ),
        const SizedBox(height: 10),
        Text(c.displayTitle, style: AppText.display(size: 22)),
        const SizedBox(height: 4),
        Text(
          c.prefecture == null || c.prefecture!.isEmpty ? c.gymName : '${c.gymName}［${c.prefecture}］',
          style: AppText.body(size: 14, color: AppColors.kabeBlue),
        ),
        const SizedBox(height: 20),
        _Section(
          title: '開催期間',
          value: c.periodDisplay,
          note: '終了日の 23:59:59 まで（日本時間）',
        ),
        _Section(
          title: 'コンペ課題',
          value: c.problemRangeDisplay,
          note: '登った課題を自分で記録します。1 課題 = 1 点',
        ),
        _Section(
          title: '参加料',
          value: '${c.feeKindDisplay}　${c.feeDisplay}',
          note: c.isFree ? null : '※ 参加料の決済は未対応です（お試し期間中は無料で参加できます）',
        ),
        _Section(
          title: '順位の決まり方',
          value: '完登した課題の数が多い順',
          note: '同じ数のときは同順位',
        ),
        if (c.isHost) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.setsuri,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.kabeBlue),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_outlined, color: AppColors.kabeBlue, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('あなたはこのコンペの開催者です（編集は「コンペを開催する」から）',
                      style: AppText.caption(size: 12, color: AppColors.chalk)),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.value, this.note});

  final String title;
  final String value;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.setsuri,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.wareme),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.caption(size: 11, weight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(value, style: AppText.body(size: 16, weight: FontWeight.w700, height: 1.3)),
          if (note != null) ...[
            const SizedBox(height: 4),
            Text(note!, style: AppText.caption(size: 11)),
          ],
        ],
      ),
    );
  }
}

/// 画面下の操作（参加する／順位を見る）
class _BottomAction extends ConsumerWidget {
  const _BottomAction({required this.competition});

  final Competition competition;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = competition;
    final Widget button;
    if (c.isJoined) {
      button = ElevatedButton.icon(
        onPressed: () => NavigationHelper.toCompetitionLeaderboard(context, c.id, competition: c),
        icon: const Icon(Icons.leaderboard_outlined),
        label: const Text('順位を見る'),
      );
    } else if (c.isActive) {
      button = ElevatedButton.icon(
        onPressed: () => joinCompetitionFlow(context, ref, c),
        icon: const Icon(Icons.flag_outlined),
        label: const Text('参加する'),
      );
    } else {
      button = ElevatedButton(
        onPressed: null,
        child: Text(c.status == CompetitionStatus.upcoming ? '開催前のため参加できません' : '終了しました'),
      );
    }

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: SizedBox(height: 49, width: double.infinity, child: button),
    );
  }
}
