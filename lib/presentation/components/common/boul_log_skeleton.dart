import 'package:flutter/material.dart';
import '../../theme/app_tokens.dart';
import 'skeleton_bone.dart';

/// ボル活カードの骨組み（読込中の場所取り）
///
/// 役割:
/// - ツイート一覧の初回読込中に、スピナーの代わりにカードと同じ寸法の「枠」を先に置く
/// - 取得完了で本物のカードに置き換わっても、画面全体の見た目が大きく動かないようにする
///   （「待たされている感」と「後から画面が組み変わる感」を避ける）
///
/// 見た目: BoulLog と同じ外枠（節理面・割れ目の枠線・角丸14）に、
/// アイコン・名前・メタ行・本文2行ぶんの淡い面を静的に置く。アニメーションはしない。
class BoulLogSkeleton extends StatelessWidget {
  const BoulLogSkeleton({super.key});

  static const _bone = kSkeletonBone;

  Widget _bar(double width, double height) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: _bone,
          borderRadius: BorderRadius.circular(height / 2),
        ),
      );

  @override
  Widget build(BuildContext context) {
    // 外枠・余白は BoulLog（boul_log.dart）と同じ値にそろえる
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 14),
      decoration: BoxDecoration(
        color: AppColors.setsuri,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.wareme),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(radius: 24, backgroundColor: _bone),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    _bar(120, 14), // ユーザー名
                    const SizedBox(height: 8),
                    _bar(200, 11), // 訪問日・ジム名
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _bar(double.infinity, 12), // 本文1行目
          const SizedBox(height: 8),
          _bar(220, 12), // 本文2行目
        ],
      ),
    );
  }
}

/// 一覧の初回読込中に出す骨組みのリスト（スクロール不可・件数固定）
///
/// 件数は画面いっぱいに枠が並ぶ 6 枚（3 枚だと下半分が空いて「一覧が短い」ように見える）
class BoulLogSkeletonList extends StatelessWidget {
  const BoulLogSkeletonList({super.key, this.count = 6});

  final int count;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 6),
      children: List.generate(count, (_) => const BoulLogSkeleton()),
    );
  }
}
