import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/bouldering_stats.dart';
import '../providers/statistics_provider.dart';
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

    final now = DateTime.now();
    final previousMonth = DateTime(now.year, now.month - 1, 1);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFEF7FF),
        surfaceTintColor: const Color(0xFFFEF7FF),
        iconTheme: const IconThemeData(
          color: Colors.black, // 戻るボタンを黒色に変更
        ),
      ),
      backgroundColor: const Color(0xFFFEF7FF),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 16),
              _buildStatsContainer(
                context,
                "今月のボル活 - ${now.year}.${now.month} -",
                currentMonthStats,
                const Color(0xFF0056FF),
              ),
              const SizedBox(height: 16),
              _buildStatsContainer(
                context,
                "昨月のボル活 - ${previousMonth.year}.${previousMonth.month} -",
                previousMonthStats,
                const Color(0xFF8D8D8D),
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
    Color bgColor,
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
      decoration: ShapeDecoration(
        color: bgColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 今月のボル活/昨月のボル活
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
            color: Colors.white,
            thickness: 1.0,
            indent: 0,
            endIndent: 0,
          ),
          const SizedBox(height: 8),

          // TOP5
          const Text(
            'TOP5',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w600,
              letterSpacing: -0.50,
            ),
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
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.50,
                                ),
                              ),
                            )
                          : Text(
                              gymName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontFamily: 'Roboto',
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.50,
                              ),
                            ),
                    ),
                    Text(
                      '$visitCount 回',
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
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatsItem(String title, String value, String unit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
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
                fontSize: 32,
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
                fontSize: 12,
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