import 'package:flutter/material.dart';
import '../../../shared/utils/navigation_helper.dart';
import '../../../shared/utils/gym_hours_utils.dart';
import '../common/gym_category.dart';
import '../../../domain/entities/gym.dart';

/// イキタイジム専用カードコンポーネント
///
/// 役割:
/// - イキタイジム一覧での統一された表示
/// - ジム詳細ページへの遷移
/// - マイページと他ユーザーページの両方で使用
///
/// クリーンアーキテクチャにおける位置づけ:
/// - Presentation層の共通UIコンポーネント
/// - ジム情報表示に特化した再利用可能部品
class FavoriteGymCard extends StatelessWidget {
  final Gym gym;

  const FavoriteGymCard({
    super.key,
    required this.gym,
  });

  @override
  Widget build(BuildContext context) {
    // 営業状態を判定（統一されたロジック使用）
    final isOpened = GymHoursUtils.isCurrentlyOpen(gym.hours);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ジム名と所在地を同じ行に配置
          GestureDetector(
            onTap: () {
              NavigationHelper.toGymDetail(context, gym.id);
            },
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: gym.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const TextSpan(text: ' '),
                  TextSpan(
                    text: '[${gym.prefecture}]',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // ジムカテゴリ
          Row(
            children: [
              if (gym.isBoulderingGym)
                const Padding(
                  padding: EdgeInsets.only(right: 8.0),
                  child: GymCategory(
                    category: 'ボルダリング',
                    colorCode: 0xFFFF0F00,
                  ),
                ),
              if (gym.isLeadGym)
                const Padding(
                  padding: EdgeInsets.only(right: 8.0),
                  child: GymCategory(
                    category: 'リード',
                    colorCode: 0xFF00A24C,
                  ),
                ),
              if (gym.isSpeedGym)
                const GymCategory(
                  category: 'スピード',
                  colorCode: 0xFF0057FF,
                ),
            ],
          ),
          const SizedBox(height: 8),

          // ジム写真
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: (gym.photoUrls.isNotEmpty)
                  ? gym.photoUrls
                      .map((photoUrl) => Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                photoUrl,
                                width: 132,
                                height: 100,
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const SizedBox(
                                    width: 132,
                                    height: 100,
                                    child: Center(
                                        child: CircularProgressIndicator()),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 132,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '写真なし',
                                        style: TextStyle(
                                            color: Colors.grey[700],
                                            fontSize: 14),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ))
                      .toList()
                  : [
                      Container(
                        width: 132,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '写真なし',
                            style: TextStyle(
                                color: Colors.grey[700], fontSize: 14),
                          ),
                        ),
                      )
                    ],
            ),
          ),
          const SizedBox(height: 8),

          // ジム利用情報
          Row(
            children: [
              const Icon(Icons.currency_yen, size: 18),
              const SizedBox(width: 4),
              Text('${gym.minimumFee ?? 0}〜'),
              const SizedBox(width: 16),
              const Icon(Icons.access_time, size: 18),
              const SizedBox(width: 4),
              isOpened
                  ? const Text('OPEN',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ))
                  : const Text(
                      "CLOSE",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // イキタイカウント数
              const Text(
                'イキタイ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '${gym.ikitaiCount}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                  height: 1.25,
                ),
              ),
              const SizedBox(width: 16),

              // ボル活ツイート数
              const Text(
                'ボル活',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '${gym.boulCount}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                  height: 1.25,
                ),
              )
            ],
          ),
          const SizedBox(height: 8),

          // 下線
          Container(
            width: MediaQuery.of(context).size.width,
            height: 1,
            color: const Color(0xFFB1B1B1),
          ),
        ],
      ),
    );
  }
}
