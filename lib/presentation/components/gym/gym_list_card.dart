import 'package:flutter/material.dart';
import '../../../domain/entities/gym.dart';
import '../common/gym_category.dart';
import '../../../shared/utils/gym_hours_utils.dart';

/// ジムリストカードコンポーネント
///
/// 役割:
/// - 検索結果や一覧表示用のジムカード
/// - 必要な情報を簡潔に表示
/// - タップ可能なカード
///
/// クリーンアーキテクチャにおける位置づけ:
/// - Presentation層のUIコンポーネント
/// - 再利用可能なウィジェット
class GymListCard extends StatelessWidget {
  final Gym gym;
  final VoidCallback? onTap;

  const GymListCard({
    super.key,
    required this.gym,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isOpen = GymHoursUtils.isCurrentlyOpen(gym.hours);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ジム名と所在地
            RichText(
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
                children: gym.photoUrls.isNotEmpty
                    ? gym.photoUrls
                        .take(3) // 最大3枚まで表示
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
                                    return Container(
                                      width: 132,
                                      height: 100,
                                      color: Colors.grey[300],
                                      child: const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return _buildPhotoPlaceholder();
                                  },
                                ),
                              ),
                            ))
                        .toList()
                    : [_buildPhotoPlaceholder()],
              ),
            ),
            const SizedBox(height: 8),

            // ジム利用情報
            Row(
              children: [
                const Icon(Icons.currency_yen, size: 18),
                const SizedBox(width: 4),
                Text('${gym.minimumFee}〜'),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, size: 18),
                const SizedBox(width: 4),
                Text(
                  isOpen ? 'OPEN' : 'CLOSE',
                  style: TextStyle(
                    color: isOpen ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // イキタイ・ボル活カウント
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // イキタイカウント
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

                // ボル活カウント
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
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 下線
            Container(
              width: double.infinity,
              height: 1,
              color: const Color(0xFFB1B1B1),
            ),
          ],
        ),
      ),
    );
  }

  /// 写真プレースホルダー
  Widget _buildPhotoPlaceholder() {
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
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
