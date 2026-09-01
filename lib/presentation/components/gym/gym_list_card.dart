import 'package:flutter/material.dart';
import '../../../domain/entities/gym.dart';
import '../common/gym_category.dart';
import '../../../shared/utils/gym_hours_utils.dart';
import '../../theme/app_tokens.dart';
import 'gym_photo_strip.dart';

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
                      color: AppColors.chalk,
                    ),
                  ),
                  const TextSpan(text: ' '),
                  TextSpan(
                    text: '[${gym.prefecture}]',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.sunabokori,
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
                      colorCode: 0xFFFF7264,
                    ),
                  ),
                if (gym.isLeadGym)
                  const Padding(
                    padding: EdgeInsets.only(right: 8.0),
                    child: GymCategory(
                      category: 'リード',
                      colorCode: 0xFF3FCF8E,
                    ),
                  ),
                if (gym.isSpeedGym)
                  const GymCategory(
                    category: 'スピード',
                    colorCode: 0xFF3EC6E0,
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // ジム写真（自前写真 or Google Places API）
            GymPhotoStrip(gymId: gym.id, maxPhotos: 3),
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
                    color: isOpen ? AppColors.holdGreen : AppColors.holdRed,
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
                    color: AppColors.chalk,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${gym.ikitaiCount}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.kabeBlue,
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
                    color: AppColors.chalk,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${gym.boulCount}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.kabeBlue,
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
              color: AppColors.sunabokori,
            ),
          ],
        ),
      ),
    );
  }

}
