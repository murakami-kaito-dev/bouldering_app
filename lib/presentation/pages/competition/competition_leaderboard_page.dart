import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/competition.dart';
import '../../components/common/error_widget.dart';
import '../../components/common/loading_widget.dart';
import '../../components/competition/competition_card.dart';
import '../../providers/competition_providers.dart';
import '../../theme/app_text.dart';
import '../../theme/app_tokens.dart';

/// ライブリーダーボード（「順位を見る」／参加直後の画面）
///
/// 役割:
/// - 参加者を完登数の多い順に表示（同数は同順位）
/// - 自分の行を強調し、初回表示で自分の位置までスクロールする
/// - 参加者本人・開催中なら、画面下の「完登を記録する」から登った課題を登録／取り消しできる
/// - 引っ張って更新で順位を取り直す（ポーリングはしない）
class CompetitionLeaderboardPage extends ConsumerStatefulWidget {
  const CompetitionLeaderboardPage({super.key, required this.competitionId, this.initial});

  final int competitionId;

  /// 呼び出し元が持っていたコンペ（取得完了までタイトル表示に使う）
  final Competition? initial;

  @override
  ConsumerState<CompetitionLeaderboardPage> createState() => _CompetitionLeaderboardPageState();
}

class _CompetitionLeaderboardPageState extends ConsumerState<CompetitionLeaderboardPage> {
  final ScrollController _scrollController = ScrollController();

  /// 行の高さ（自分の位置へのスクロール量を計算するために固定する）
  static const double _rowExtent = 68;

  bool _scrolledToMe = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 初回のデータ到着後に 1 回だけ、自分の行が画面中央に来るようスクロールする
  void _scrollToMeOnce(CompetitionLeaderboard board) {
    if (_scrolledToMe) return;
    final index = board.myIndex;
    if (index < 0) return;
    _scrolledToMe = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final viewport = _scrollController.position.viewportDimension;
      final target = (index * _rowExtent) - (viewport / 2 - _rowExtent / 2);
      final max = _scrollController.position.maxScrollExtent;
      final offset = target.clamp(0.0, max > 0 ? max : 0.0);
      if (offset <= 0) return; // 画面に収まっている（スクロール不要）
      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _refresh() async {
    ref.invalidate(competitionLeaderboardProvider(widget.competitionId));
    try {
      await ref.read(competitionLeaderboardProvider(widget.competitionId).future);
    } catch (_) {
      // 失敗時は画面側の error 表示に任せる
    }
  }

  @override
  Widget build(BuildContext context) {
    final board = ref.watch(competitionLeaderboardProvider(widget.competitionId));
    final title = board.valueOrNull?.competition.displayTitle ?? widget.initial?.displayTitle ?? '順位表';

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: AppText.heading(size: 17), overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: '更新',
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: board.when(
        loading: () => const LoadingWidget(message: '順位表を読み込み中...'),
        error: (e, _) => AppErrorWidget(
          message: competitionErrorMessage(e),
          onRetry: () => ref.invalidate(competitionLeaderboardProvider(widget.competitionId)),
        ),
        data: (data) {
          _scrollToMeOnce(data);
          return Column(
            children: [
              _Header(board: data),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: data.entries.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 72),
                            Icon(Icons.groups_outlined, size: 56, color: AppColors.sunabokori),
                            SizedBox(height: 12),
                            Text(
                              'まだ参加者がいません',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 15, color: AppColors.sunabokori),
                            ),
                          ],
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemExtent: _rowExtent,
                          padding: EdgeInsets.zero,
                          itemCount: data.entries.length,
                          itemBuilder: (context, i) => _LeaderboardRow(
                            entry: data.entries[i],
                            problemCount: data.competition.problemCount,
                          ),
                        ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: board.valueOrNull == null
          ? null
          : _RecordBar(board: board.valueOrNull!, competitionId: widget.competitionId),
    );
  }
}

/// 上部の要約（期間・課題・自分の順位）
class _Header extends StatelessWidget {
  const _Header({required this.board});

  final CompetitionLeaderboard board;

  @override
  Widget build(BuildContext context) {
    final c = board.competition;
    final myCount = board.myCompletedProblems.length;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: AppColors.setsuri,
        border: Border(bottom: BorderSide(color: AppColors.wareme)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CompetitionStatusTape(status: c.status),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(c.gymName,
                          style: AppText.caption(size: 12, color: AppColors.kabeBlue),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('${c.periodDisplay}・${c.problemRangeDisplay}', style: AppText.caption(size: 11)),
                const SizedBox(height: 2),
                Text('${c.participantCount} 人参加・${c.feeDisplay}', style: AppText.caption(size: 11)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (board.myRank != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('あなたの順位', style: AppText.caption(size: 10)),
                Text('${board.myRank} 位', style: AppText.number(size: 26, color: AppColors.kabeBlue)),
                Text('$myCount / ${c.problemCount} 完登', style: AppText.caption(size: 11)),
              ],
            )
          else
            Text('未参加', style: AppText.caption(size: 12)),
        ],
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({required this.entry, required this.problemCount});

  final LeaderboardEntry entry;
  final int problemCount;

  @override
  Widget build(BuildContext context) {
    final isTop3 = entry.rank <= 3;
    final rankColor = switch (entry.rank) {
      1 => AppColors.holdRed,
      2 => AppColors.holdCyan,
      3 => AppColors.holdGreen,
      _ => AppColors.sunabokori,
    };
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: entry.isMe ? AppColors.setsuri : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: entry.isMe ? AppColors.kabeBlue : AppColors.wareme),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              '${entry.rank}',
              textAlign: TextAlign.center,
              style: AppText.number(size: isTop3 ? 24 : 20, color: rankColor),
            ),
          ),
          const SizedBox(width: 6),
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.wareme,
            backgroundImage: (entry.userIconUrl != null && entry.userIconUrl!.isNotEmpty)
                ? ResizeImage(CachedNetworkImageProvider(entry.userIconUrl!), width: 108)
                : null,
            child: (entry.userIconUrl == null || entry.userIconUrl!.isEmpty)
                ? const Icon(Icons.person, size: 18, color: AppColors.sunabokori)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              entry.isMe ? '${entry.userName}（あなた）' : entry.userName,
              style: AppText.body(size: 14, weight: entry.isMe ? FontWeight.w700 : FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${entry.completedCount}', style: AppText.number(size: 22)),
              Text('/ $problemCount 完登', style: AppText.caption(size: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

/// 画面下の「完登を記録する」（参加者本人・開催中のときだけ）
class _RecordBar extends ConsumerWidget {
  const _RecordBar({required this.board, required this.competitionId});

  final CompetitionLeaderboard board;
  final int competitionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = board.competition;
    if (!c.isJoined) return const SizedBox.shrink();

    final done = board.myCompletedProblems.length;
    final label = c.isActive
        ? '完登を記録する（$done / ${c.problemCount}）'
        : (c.status == CompetitionStatus.ended ? '終了しました（記録は締め切り）' : '開催前です');

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: SizedBox(
        height: 49,
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: c.isActive ? () => _openRecorder(context, ref) : null,
          icon: const Icon(Icons.check_circle_outline),
          label: Text(label),
        ),
      ),
    );
  }

  Future<void> _openRecorder(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProblemRecorderSheet(
        competition: board.competition,
        initialCompleted: board.myCompletedProblems,
      ),
    );
    // シートを閉じたら最新の順位を取り直す（記録のたびに invalidate 済みだが念のため）
    ref.invalidate(competitionLeaderboardProvider(competitionId));
  }
}

/// 課題番号を並べて、タップで「完了」を付け外しするシート
class _ProblemRecorderSheet extends ConsumerStatefulWidget {
  const _ProblemRecorderSheet({required this.competition, required this.initialCompleted});

  final Competition competition;
  final Set<int> initialCompleted;

  @override
  ConsumerState<_ProblemRecorderSheet> createState() => _ProblemRecorderSheetState();
}

class _ProblemRecorderSheetState extends ConsumerState<_ProblemRecorderSheet> {
  late Set<int> _completed = {...widget.initialCompleted};
  final Set<int> _busy = {};

  Future<void> _toggle(int problemNo) async {
    if (_busy.contains(problemNo)) return;
    final willComplete = !_completed.contains(problemNo);
    setState(() {
      _busy.add(problemNo);
      // 楽観更新（失敗したら戻す）
      if (willComplete) {
        _completed.add(problemNo);
      } else {
        _completed.remove(problemNo);
      }
    });
    try {
      final latest = await ref
          .read(competitionActionsProvider)
          .setCompleted(widget.competition.id, problemNo, willComplete);
      if (mounted) setState(() => _completed = latest);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (willComplete) {
          _completed.remove(problemNo);
        } else {
          _completed.add(problemNo);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(competitionErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _busy.remove(problemNo));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.competition;
    final numbers = [for (var n = c.problemFrom; n <= c.problemTo; n++) n];

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.setsuri,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.wareme,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('完登を記録する', style: AppText.heading(size: 16)),
                        const SizedBox(height: 2),
                        Text('登れた課題の番号をタップ。もう一度タップで取り消し',
                            style: AppText.caption(size: 12)),
                      ],
                    ),
                  ),
                  Text('${_completed.length} / ${c.problemCount}',
                      style: AppText.number(size: 24, color: AppColors.kabeBlue)),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: GridView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 72,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1,
                ),
                itemCount: numbers.length,
                itemBuilder: (context, i) {
                  final n = numbers[i];
                  final done = _completed.contains(n);
                  final busy = _busy.contains(n);
                  return Material(
                    color: done ? AppColors.holdGreen : AppColors.iwa,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    child: InkWell(
                      onTap: busy ? null : () => _toggle(n),
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          border: Border.all(color: done ? AppColors.holdGreen : AppColors.wareme),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Text(
                              '$n',
                              style: AppText.number(
                                size: 22,
                                color: done ? AppColors.onHoldGreen : AppColors.chalk,
                              ),
                            ),
                            if (done)
                              const Positioned(
                                right: 4,
                                top: 4,
                                child: Icon(Icons.check, size: 14, color: AppColors.onHoldGreen),
                              ),
                            if (busy)
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('順位表に戻る'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
