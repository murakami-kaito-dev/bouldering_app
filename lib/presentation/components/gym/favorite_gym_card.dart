import 'package:flutter/material.dart';
import '../../../shared/utils/navigation_helper.dart';
import '../../../shared/utils/gym_hours_utils.dart';
import '../common/gym_category.dart';
import '../common/pressable.dart';
import '../../../domain/entities/gym.dart';
import '../../theme/app_tokens.dart';
import '../../theme/app_text.dart';
import 'gym_photo_strip.dart';

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

    return Pressable(
        child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.setsuri,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.wareme),
      ),
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
          // 写真1.7枚分が見える幅（ジム詳細と同じ見せ方に統一）
              LayoutBuilder(builder: (context, constraints) {
                final photoWidth = constraints.maxWidth / 1.7 - 8;
                return GymPhotoStrip(
                  gymId: gym.id,
                  photoWidth: photoWidth,
                  height: photoWidth * 0.75, // 4:3比率
                );
              }),
          const SizedBox(height: 8),

          // ジム利用情報
          Row(
            children: [
              const Icon(Icons.currency_yen,
                  size: 18, color: AppColors.sunabokori),
              const SizedBox(width: 4),
              Text(
                '${gym.minimumFee}〜', // minimumFeeはnon-nullable（?? は不要のため削除）
                style: AppText.number(size: 16),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.access_time,
                  size: 18, color: AppColors.sunabokori),
              const SizedBox(width: 4),
              isOpened
                  ? Text(
                      'OPEN',
                      style: AppText.label(
                        size: 13,
                        color: AppColors.holdGreen,
                      ),
                    )
                  : Text(
                      "CLOSE",
                      style: AppText.label(
                        size: 13,
                        color: AppColors.holdRed,
                      ),
                    ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // イキタイカウント数
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

              // ボル活ツイート数
              Text(
                'ボル活',
                style: AppText.caption(size: 12, weight: FontWeight.w700),
              ),
              const SizedBox(width: 4),
              Text(
                '${gym.boulCount}',
                style: AppText.number(size: 18, color: AppColors.kabeBlue),
              )
            ],
          ),
        ],
      ),
    ));
  }
}
