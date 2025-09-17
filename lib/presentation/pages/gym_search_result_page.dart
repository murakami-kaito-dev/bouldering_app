import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/gym.dart';
import '../components/gym/gym_list_card.dart';
import '../../shared/services/navigation_service.dart';

/// ジム検索結果ページ
///
/// 役割:
/// - 検索条件に一致したジムの一覧表示
/// - ジム詳細ページへの遷移
///
/// クリーンアーキテクチャにおける位置づけ:
/// - Presentation層のView
/// - ドメインエンティティ（Gym）を直接受け取る
/// - UIロジックのみを担当
class GymSearchResultPage extends ConsumerWidget {
  final List<Gym> gyms;

  const GymSearchResultPage({
    super.key,
    required this.gyms,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (gyms.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFFEF7FF),
          surfaceTintColor: const Color(0xFFFEF7FF),
          iconTheme: const IconThemeData(
            color: Colors.black, // 戻るボタンを黒色に変更
          ),
          title: const Text(
            '検索結果',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: const Center(
          child: Text('該当するジムはありません'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFEF7FF),
        surfaceTintColor: const Color(0xFFFEF7FF),
        iconTheme: const IconThemeData(
          color: Colors.black, // 戻るボタンを黒色に変更
        ),
        title: Text(
          '検索結果（${gyms.length}件）',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: gyms.length,
        itemBuilder: (context, index) {
          final gym = gyms[index];
          return GymListCard(
            gym: gym,
            onTap: () {
              // NavigationServiceを使用してジム詳細ページへ遷移
              NavigationService.navigateToGymDetail(
                context: context,
                gymId: gym.id,
              );
            },
          );
        },
      ),
    );
  }
}
