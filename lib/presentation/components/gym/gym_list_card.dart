import 'package:flutter/material.dart';
import '../../../domain/entities/gym.dart';
import '../common/gym_category.dart';
import '../../../shared/utils/gym_hours_utils.dart';
import '../../theme/app_tokens.dart';
import '../../theme/app_text.dart';
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.setsuri,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.wareme),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ジム名と所在地
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: gym.name,
                      style: AppText.heading(size: 16),
                    ),
                    const TextSpan(text: ' '),
                    TextSpan(
                      text: '[${gym.prefecture}]',
                      style: AppText.caption(size: 12),
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
                        color: AppColors.holdRed,
                      ),
                    ),
                  if (gym.isLeadGym)
                    const Padding(
                      padding: EdgeInsets.only(right: 8.0),
                      child: GymCategory(
                        category: 'リード',
                        color: AppColors.holdGreen,
                      ),
                    ),
                  if (gym.isSpeedGym)
                    const GymCategory(
                      category: 'スピード',
                      color: AppColors.holdCyan,
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
                  const Icon(Icons.currency_yen,
                      size: 18, color: AppColors.sunabokori),
                  const SizedBox(width: 4),
                  Text(
                    '${gym.minimumFee}〜',
                    style: AppText.number(size: 16),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.access_time,
                      size: 18, color: AppColors.sunabokori),
                  const SizedBox(width: 4),
                  Text(
                    isOpen ? 'OPEN' : 'CLOSE',
                    style: AppText.label(
                      size: 13,
                      color: isOpen ? AppColors.holdGreen : AppColors.holdRed,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // イキタイ・ボル活カウント
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // イキタイカウント
                  Text(
                    'イキタイ',
                    style: AppText.caption(size: 12, weight: FontWeight.w700),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${gym.ikitaiCount}',
                    style: AppText.number(size: 18, color: AppColors.kabeBlue),
                  ),
                  const SizedBox(width: 16),

                  // ボル活カウント
                  Text(
                    'ボル活',
                    style: AppText.caption(size: 12, weight: FontWeight.w700),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${gym.boulCount}',
                    style: AppText.number(size: 18, color: AppColors.kabeBlue),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
