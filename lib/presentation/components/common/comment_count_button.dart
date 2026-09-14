import 'package:flutter/material.dart';
import '../../theme/app_text.dart';
import '../../theme/app_tokens.dart';
import 'pressable.dart';

/// 吹き出し＋コメント件数（ボル活カードの操作行に置く）
///
/// タップでスレッド画面（TweetDetailPage）へ。色は砂埃（副次的な操作）で、
/// いいねのハートと横並びにしても主張しすぎないようにする。
class CommentCountButton extends StatelessWidget {
  final int count;
  final VoidCallback? onTap;

  const CommentCountButton({
    super.key,
    required this.count,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const color = AppColors.sunabokori;

    return Pressable(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.chat_bubble_outline_rounded,
                  size: 18, color: color),
              const SizedBox(width: 4),
              Text(
                '$count',
                style: AppText.number(size: 15, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
