import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/bouldering_stats.dart';
import 'dependency_injection.dart';

/// ボルダリング統計データ提供Provider
/// 
/// 役割:
/// - ユーザーの月次統計データを管理
/// - UseCase経由で実際の統計データを提供
/// 
/// クリーンアーキテクチャにおける位置づけ:
/// - Presentation層のProvider
/// - Domain層のUseCaseを通してデータを取得

typedef StatisticsParams = ({String userId, int monthsAgo});

/// ボルダリング統計データProvider
final statisticsProvider = FutureProvider.family<BoulderingStats, StatisticsParams>((ref, params) async {
  try {
    final useCase = ref.read(getMonthlyStatisticsUseCaseProvider);
    return await useCase.execute(
      userId: params.userId,
      monthsAgo: params.monthsAgo,
    );
  } catch (e) {
    // エラー時は0値の統計を返してアプリの動作を継続
    return BoulderingStats(
      totalVisits: 0,
      totalGymCount: 0,
      weeklyVisitRate: 0.0,
      topGyms: [],
    );
  }
});