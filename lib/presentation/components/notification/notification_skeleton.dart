import 'package:flutter/material.dart';
import '../../theme/app_tokens.dart';
import '../common/skeleton_bone.dart';

/// 通知行の骨組み（初回読込中の場所取り）
///
/// BoulLogSkeleton と同じ方針: スピナーではなく行と同じ寸法の淡い面を静的に置く
class NotificationSkeleton extends StatelessWidget {
  const NotificationSkeleton({super.key});

  Widget _bar(double width, double height) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: kSkeletonBone,
          borderRadius: BorderRadius.circular(height / 2),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 14, 16, 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.wareme)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(radius: 18, backgroundColor: kSkeletonBone),
          const SizedBox(height: 10),
          _bar(240, 13), // 一文
          const SizedBox(height: 8),
          _bar(48, 10), // 時間
          const SizedBox(height: 10),
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.setsuri,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.wareme),
            ),
          ),
        ],
      ),
    );
  }
}

/// 一覧の初回読込中に出す骨組みのリスト（スクロール不可・件数固定）
class NotificationSkeletonList extends StatelessWidget {
  const NotificationSkeletonList({super.key, this.count = 6});

  final int count;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      children: List.generate(count, (_) => const NotificationSkeleton()),
    );
  }
}
