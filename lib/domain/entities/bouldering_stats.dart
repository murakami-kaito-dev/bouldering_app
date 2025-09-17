/// ボルダリング統計エンティティ
/// 
/// 役割:
/// - ユーザーのボルダリング活動統計データを管理
/// - 月次統計情報（訪問回数、ジム数、週間ペース、TOP5ジム）を保持
/// 
/// クリーンアーキテクチャにおける位置づけ:
/// - Domain層のEntity
/// - ビジネスロジックに依存しない純粋なデータモデル
class BoulderingStats {
  final int totalVisits;
  final int totalGymCount;
  final double weeklyVisitRate;
  final List<TopGym> topGyms;

  BoulderingStats({
    required this.totalVisits,
    required this.totalGymCount,
    required this.weeklyVisitRate,
    required this.topGyms,
  });

  factory BoulderingStats.fromJson(Map<String, dynamic> json) {
    return BoulderingStats(
      totalVisits: int.tryParse(json['total_visits']?.toString() ?? '0') ?? 0,
      totalGymCount: int.tryParse(json['total_gym_count']?.toString() ?? '0') ?? 0,
      weeklyVisitRate: double.tryParse(json['weekly_visit_rate']?.toString() ?? '0.0') ?? 0.0,
      topGyms: (json['top_gyms'] as List<dynamic>?)
          ?.map((gym) => TopGym.fromJson(gym as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  /// Mock用のファクトリーコンストラクタ
  factory BoulderingStats.mock({
    int totalVisits = 5,
    int totalGymCount = 3,
    double weeklyVisitRate = 1.2,
  }) {
    return BoulderingStats(
      totalVisits: totalVisits,
      totalGymCount: totalGymCount,
      weeklyVisitRate: weeklyVisitRate,
      topGyms: [
        TopGym(gymId: "1", gymName: "クライミングジムA", visitCount: 3),
        TopGym(gymId: "2", gymName: "ボルダリングスタジオB", visitCount: 2),
        TopGym(gymId: "3", gymName: "アウトドアクライミングC", visitCount: 1),
      ],
    );
  }
}

/// TOP5ジム情報
class TopGym {
  final String gymId;
  final String gymName;
  final int visitCount;

  TopGym({
    required this.gymId,
    required this.gymName,
    required this.visitCount,
  });

  factory TopGym.fromJson(Map<String, dynamic> json) {
    return TopGym(
      gymId: json['gym_id']?.toString() ?? '',
      gymName: json['gym_name']?.toString() ?? '',
      visitCount: int.tryParse(json['visit_count']?.toString() ?? '0') ?? 0,
    );
  }
}