import 'package:flutter/material.dart';
import '../../shared/utils/app_clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/bouldering_stats.dart';
import '../providers/statistics_provider.dart';
import '../theme/app_tokens.dart';
import '../theme/app_text.dart';
import '../components/common/tape_chip.dart';
import 'gym_detail_page.dart';

/// 統計レポートページ
/// 
/// 役割:
/// - ユーザーの今月・前月のボルダリング統計を表示
/// - 訪問回数、ジム数、週間ペース、TOP5ジムを表示
/// 
/// クリーンアーキテクチャにおける位置づけ:
/// - Presentation層のView
/// - 統計データの詳細表示画面
class StatisticsReportPage extends ConsumerWidget {
  final String userId; // 統計を表示する対象ユーザーのID（必須）

  const StatisticsReportPage({
    super.key,
    required this.userId, // 必須パラメータ
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMonthStats = ref.watch(statisticsProvider((userId: userId, monthsAgo: 0)));
    final previousMonthStats = ref.watch(statisticsProvider((userId: userId, monthsAgo: 1)));

    // 見出しの「今月／昨月」はサーバーの集計（JST 基準）と同じく日本時間で決める
    final now = AppClock.todayJst();
    final previousMonth = DateTime(now.year, now.month - 1, 1);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.iwa,
        surfaceTintColor: AppColors.iwa,
        iconTheme: const IconThemeData(
          color: AppColors.chalk, // 戻るボタンを黒色に変更
        ),
      ),
      backgroundColor: AppColors.iwa,
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 16),
              // 数字は今月・昨月とも同じ色（同じ種類の情報は同じ見た目）。
              // 期間の状態は色ではなく課題テープの文言で示す:
              //   今月 = 「進行中」（壁ブルー） / 昨月 = 「確定」（くすんだ面）
              _buildStatsContainer(
                context,
                "今月のボル活 - ${now.year}.${now.month} -",
                currentMonthStats,
                const TapeChip(label: '進行中', color: AppColors.kabeBlue),
              ),
              const SizedBox(height: 16),
              _buildStatsContainer(
                context,
                "昨月のボル活 - ${previousMonth.year}.${previousMonth.month} -",
                previousMonthStats,
                const TapeChip(
                    label: '確定', color: AppColors.wareme, selected: false),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsContainer(
    BuildContext context,
    String title,
    AsyncValue<BoulderingStats> asyncStats,
    TapeChip periodTape,
  ) {
    String visits = "-";
    String gyms = "-";
    String pace = "-";
    List<TopGym> topGyms = [];

    asyncStats.when(
      data: (data) {
        visits = data.totalVisits.toString();
        gyms = data.totalGymCount.toString();
        pace = data.weeklyVisitRate.toString();
        topGyms = data.topGyms;
      },
      error: (error, stack) {
        visits = '?';
        gyms = '?';
        pace = '?';
        topGyms = List.generate(5, (index) => TopGym(
          gymId: '',
          gymName: '?',
          visitCount: 0,
        ));
      },
      loading: () {
        visits = '-';
        gyms = '-';
        pace = '-';
        topGyms = List.generate(5, (index) => TopGym(
          gymId: '',
          gymName: '-',
          visitCount: 0,
        ));
      },
    );

    return Container(
      width: 344,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.setsuri,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.wareme),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 今月のボル活/昨月のボル活 ＋ 期間の状態テープ（進行中/確定）
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppText.heading(size: 15),
                ),
              ),
              periodTape,
            ],
          ),
          const SizedBox(height: 12),

          // ボル活・施設数・ペースの統計情報表示部分
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatsItem('ボル活', visits, '回'),
              _buildStatsItem('施設数', gyms, '施設'),
              _buildStatsItem('ペース', pace, '回/週'),
            ],
          ),
          const SizedBox(height: 8),

          // 下線表示
          const Divider(
            color: AppColors.wareme,
            thickness: 1.0,
            indent: 0,
            endIndent: 0,
          ),
          const SizedBox(height: 8),

          // TOP5
          Text(
            'TOP5',
            style: AppText.caption(size: 11, weight: FontWeight.w700),
          ),
          const SizedBox(height: 4),

          // TOP5のジム名表示
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: topGyms.length,
            itemBuilder: (context, index) {
              final gym = topGyms[index];
              final gymName = gym.gymName;
              final visitCount = gym.visitCount;
              final gymId = gym.gymId;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      // gymNameが'?'：ジム取得エラーで表示される文字
                      // gymNameが'-'： ジム取得処理中に表示される文字
                      child: (gymId.isNotEmpty && gymName != '?' && gymName != '-')
                          ? InkWell(
                              onTap: () {
                                // ジム詳細ページに遷移
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => GymDetailPage(gymId: gymId),
                                  ),
                                );
                              },
                              child: Text(
                                gymName,
                                softWrap: true,
                                overflow: TextOverflow.visible,
                                // タップ可能＝リンクなので壁ブルー
                                style: AppText.body(
                                  size: 14,
                                  color: AppColors.kabeBlue,
                                  weight: FontWeight.w500,
                                ),
                              ),
                            )
                          : Text(
                              gymName,
                              style: AppText.body(size: 14),
                            ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$visitCount',
                          style: AppText.number(size: 16),
                        ),
                        const SizedBox(width: 3),
                        Text('回', style: AppText.caption(size: 11)),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatsItem(
      String title, String value, String unit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: AppText.caption(size: 11),
        ),
        const SizedBox(height: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              // 数字はチョーク固定。壁ブルーは「押せるもの・進行中の印」にだけ使う
              style: AppText.number(size: 30, color: AppColors.chalk),
            ),
            const SizedBox(width: 3),
            Text(
              unit,
              style: AppText.caption(size: 11),
            ),
          ],
        ),
      ],
    );
  }
}