import 'package:flutter/material.dart';

import '../../../domain/entities/competition.dart';
import '../../theme/app_text.dart';
import '../../theme/app_tokens.dart';

/// コンペ 1 件のカード（一覧・参加中・開催者管理で共用）
///
/// 役割:
/// - 状態テープ（開催中／開催前／終了）・タイトル・ジム名・期間・課題範囲・参加料・参加人数を揃えて出す
/// - 下部の操作ボタンは呼び出し側が [actions] で渡す（画面ごとに違うため）
class CompetitionCard extends StatelessWidget {
  const CompetitionCard({
    super.key,
    required this.competition,
    this.actions = const [],
    this.onTap,
  });

  final Competition competition;

  /// 下部に横並びで置くボタン群
  final List<Widget> actions;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = competition;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CompetitionStatusTape(status: c.status),
                  const SizedBox(width: 8),
                  _FeeTape(isFree: c.isFree),
                  const Spacer(),
                  Text('${c.participantCount} 人参加', style: AppText.caption(size: 11)),
                ],
              ),
              const SizedBox(height: 10),
              Text(c.displayTitle, style: AppText.heading(size: 16)),
              const SizedBox(height: 2),
              Text(
                c.prefecture == null || c.prefecture!.isEmpty
                    ? c.gymName
                    : '${c.gymName}［${c.prefecture}］',
                style: AppText.caption(size: 12, color: AppColors.kabeBlue),
              ),
              const SizedBox(height: 10),
              _InfoRow(icon: Icons.calendar_today, label: '期間', value: c.periodDisplay),
              const SizedBox(height: 4),
              _InfoRow(icon: Icons.format_list_numbered, label: '課題', value: c.problemRangeDisplay),
              const SizedBox(height: 4),
              _InfoRow(icon: Icons.payments_outlined, label: '参加料', value: c.feeDisplay),
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    for (var i = 0; i < actions.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(child: actions[i]),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 開催状態のテープ（課題テープと同じ斜めの小ラベル）
class CompetitionStatusTape extends StatelessWidget {
  const CompetitionStatusTape({super.key, required this.status});

  final CompetitionStatus status;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = switch (status) {
      CompetitionStatus.active => (AppColors.holdGreen, AppColors.onHoldGreen),
      CompetitionStatus.upcoming => (AppColors.holdCyan, AppColors.onHoldCyan),
      CompetitionStatus.ended => (AppColors.wareme, AppColors.sunabokori),
    };
    return _Tape(text: status.label, background: bg, foreground: fg);
  }
}

class _FeeTape extends StatelessWidget {
  const _FeeTape({required this.isFree});

  final bool isFree;

  @override
  Widget build(BuildContext context) {
    return _Tape(
      text: isFree ? '無料' : '有料',
      background: isFree ? AppColors.kabeBlue : AppColors.holdRed,
      foreground: isFree ? AppColors.onKabeBlue : AppColors.onHoldRed,
    );
  }
}

class _Tape extends StatelessWidget {
  const _Tape({required this.text, required this.background, required this.foreground});

  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Transform(
      transform: Matrix4.skewX(-0.14),
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadius.tape),
        ),
        child: Transform(
          transform: Matrix4.skewX(0.14),
          alignment: Alignment.center,
          child: Text(text, style: AppText.label(size: 11, color: foreground)),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.sunabokori),
        const SizedBox(width: 6),
        SizedBox(width: 44, child: Text(label, style: AppText.caption(size: 12))),
        Expanded(child: Text(value, style: AppText.body(size: 13, height: 1.3))),
      ],
    );
  }
}
