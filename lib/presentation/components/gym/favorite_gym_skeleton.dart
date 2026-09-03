import 'package:flutter/material.dart';
import '../../theme/app_tokens.dart';
import '../common/gym_category.dart';
import '../common/skeleton_bone.dart';

/// イキタイジムカードの骨組み（読込中の場所取り）
///
/// 役割:
/// - イキタイジム一覧の初回読込中に、スピナーの代わりにカードと同じ寸法の「枠」を先に置く
/// - 取得完了で本物のカードに置き換わっても、画面全体の見た目が大きく動かないようにする
///
/// 見た目: FavoriteGymCard と同じ外枠（節理面・割れ目の枠線・角丸14・余白12）に、
/// ジム名・種別タグ・写真帯（1.7枚ぶん・4:3）・料金/営業・イキタイ/ボル活の行ぶんの
/// 淡い面を静的に置く。アニメーションはしない。
/// 写真帯の高さは FavoriteGymCard と同じ式（幅/1.7-8 の 4:3）で出すので、
/// 写真の有無にかかわらずカード全体の高さは本物とほぼ同じになる。
class FavoriteGymSkeleton extends StatelessWidget {
  const FavoriteGymSkeleton({super.key});

  Widget _bar(double width, double height) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: kSkeletonBone,
          borderRadius: BorderRadius.circular(height / 2),
        ),
      );

  Widget _box(double width, double height) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: kSkeletonBone,
          borderRadius: BorderRadius.circular(8), // 写真の角丸と同じ
        ),
      );

  @override
  Widget build(BuildContext context) {
    // 外枠・余白は FavoriteGymCard（favorite_gym_card.dart）と同じ値にそろえる
    return Container(
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
          _bar(180, 16), // ジム名 [都道府県]
          const SizedBox(height: 8),

          // 種別タグ: 本物のタグを透明で置いて行の高さを揃え、その上に骨を重ねる
          Stack(
            alignment: Alignment.centerLeft,
            children: [
              const Opacity(
                opacity: 0,
                child: GymCategory(
                    category: 'ボルダリング', color: AppColors.holdRed),
              ),
              _bar(72, 14),
            ],
          ),
          const SizedBox(height: 8),

          // 写真帯（1.7枚ぶんが見える幅・4:3）
          LayoutBuilder(builder: (context, constraints) {
            final photoWidth = constraints.maxWidth / 1.7 - 8;
            final height = photoWidth * 0.75;
            return SizedBox(
              height: height,
              child: Row(
                children: [
                  _box(photoWidth, height),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRect(
                      child: OverflowBox(
                        alignment: Alignment.centerLeft,
                        maxWidth: photoWidth,
                        child: _box(photoWidth, height),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),

          _bar(150, 14), // 料金・営業状態
          const SizedBox(height: 8),
          _bar(120, 14), // イキタイ・ボル活の数
        ],
      ),
    );
  }
}

/// 一覧の初回読込中に出す骨組みのリスト（スクロール不可・件数固定）
class FavoriteGymSkeletonList extends StatelessWidget {
  const FavoriteGymSkeletonList({super.key, this.count = 3});

  final int count;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 6),
      children: List.generate(count, (_) => const FavoriteGymSkeleton()),
    );
  }
}
