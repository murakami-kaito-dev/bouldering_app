import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../pages/statistics_report_page.dart';
import '../providers/statistics_provider.dart';
import '../components/common/loading_widget.dart';

/// 今月のボル活コンポーネント
/// 
/// 役割:
/// - ユーザーの今月のボルダリング活動統計を表示
/// - ボル活回数、施設数、週間ペースを表示
/// 
/// クリーンアーキテクチャにおける位置づけ:
/// - Presentation層のComponent
/// - ユーザー統計情報表示に特化したUI部品
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

    return statisticsAsync.when(
      loading: () => const LoadingWidget(),
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
    String visits,
    String gyms,
    String pace,
  ) {
    return Center(
      child: Container(
        width: 400,
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
        decoration: ShapeDecoration(
          color: const Color(0xFF0056FF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    // 今月のボル活 テキスト
                    const Text(
                      '今月のボル活',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.50,
                      ),
                    ),
                    // 統計情報更新ボタン（Mock実装では非表示）
                    // TODO: 本格実装時はリフレッシュボタンを実装
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StatisticsReportPage(userId: userId),
                      ),
                    );
                  },
                  child: const Text(
                    '統計レポート >',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.50,
                    ),
                  ),
                ),
              ],
            ),

            // ボル活・施設数・ペース 表記部分
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatsItem('ボル活', visits, '回'),
                _buildStatsItem('施設数', gyms, '施設'),
                _buildStatsItem('ペース', pace, '回 / 週'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// ボル活・施設数・(ボル活)ペースを表示するウィジェット
  Widget _buildStatsItem(String title, String value, String unit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w600,
            letterSpacing: -0.50,
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w600,
                letterSpacing: -0.50,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              unit,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w600,
                letterSpacing: -0.50,
              ),
            ),
          ],
        ),
      ],
    );
  }
}