import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../pages/statistics_report_page.dart';
import '../providers/statistics_provider.dart';
import '../theme/app_tokens.dart';
import '../theme/app_text.dart';
import 'common/tape_chip.dart';

/// 今月のボル活コンポーネント
///
/// 役割:
/// - ユーザーの今月のボルダリング活動統計を表示
/// - ボル活回数、施設数、週間ペースを表示
///
/// 見た目（岩と粉 Phase 2b）:
/// - 青ベタ面をやめ、節理面のカードに。主役はコンデンス書体の数字
/// - 数字はチョーク（統計レポート画面と同じ見た目）。青は「統計レポートへのリンク」と
///   「進行中」テープにだけ使う（色の役割ルール: 青＝押せるもの・進行中の印）
class ThisMonthBoulLog extends ConsumerWidget {
  final String userId; // 統計を表示する対象ユーザーのID（必須）
  final int monthsAgo;

  const ThisMonthBoulLog({
    super.key,
    required this.userId, // 必須パラメータ
    this.monthsAgo = 0, // デフォルトは今月
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statisticsAsync = ref.watch(statisticsProvider((
      userId: userId,
      monthsAgo: monthsAgo,
    )));

    // 読込中もカードの枠・見出し・単位は先に置き、数値だけを取得後に表示する
    // （スピナー→カードの差し替えで画面が大きく組み変わるのを避ける）
    return statisticsAsync.when(
      loading: () => _buildContainer(context, null, null, null),
      error: (error, stackTrace) => _buildContainer(context, '0', '0', '0.0'),
      data: (statistics) => _buildContainer(
        context,
        statistics.totalVisits.toString(),
        statistics.totalGymCount.toString(),
        statistics.weeklyVisitRate.toStringAsFixed(1),
      ),
    );
  }

  /// 今月のボル活を表示するウィジェット
  Widget _buildContainer(
    BuildContext context,
    String? visits, // null = 取得中（数値は非表示・場所だけ確保）
    String? gyms,
    String? pace,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.setsuri,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.wareme),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text('今月のボル活', style: AppText.caption(size: 12)),
                  const SizedBox(width: 8),
                  const TapeChip(
                      label: '進行中', color: AppColors.kabeBlue, fontSize: 10),
                ],
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          StatisticsReportPage(userId: userId),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Text('統計レポート',
                        style: AppText.caption(
                            size: 12, color: AppColors.kabeBlue)),
                    const Icon(Icons.chevron_right,
                        size: 16, color: AppColors.kabeBlue),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ボル活・施設数・ペース（数字が顔）
          Row(
            children: [
              Expanded(child: _buildStatsItem('ボル活', visits, '回')),
              _divider(),
              Expanded(child: _buildStatsItem('施設', gyms, '施設')),
              _divider(),
              Expanded(child: _buildStatsItem('ペース', pace, '回/週')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 34,
        color: AppColors.wareme,
        margin: const EdgeInsets.symmetric(horizontal: 12),
      );

  /// ボル活・施設数・(ボル活)ペースを表示するウィジェット
  Widget _buildStatsItem(String title, String? value, String unit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            // 取得中は同じ大きさの透明な数字で高さ・ベースラインを確保しておき、
            // 取得できた瞬間にその値へ差し替える（レイアウトは動かない）
            Opacity(
              opacity: value == null ? 0 : 1,
              child: Text(
                value ?? '0',
                style: AppText.number(
                  size: 30,
                  color: AppColors.chalk,
                  weight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 3),
            Text(unit, style: AppText.caption(size: 11)),
          ],
        ),
        const SizedBox(height: 2),
        Text(title, style: AppText.caption(size: 11)),
      ],
    );
  }
}
