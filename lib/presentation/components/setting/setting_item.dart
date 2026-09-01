import 'package:flutter/material.dart';
import '../../theme/app_tokens.dart';
import '../../theme/app_text.dart';

/// 設定項目ウィジェット
/// 
/// 役割:
/// - 設定画面の各項目を統一的に表示
/// - タップ可能なリストアイテムとして動作
/// - 右端に矢印アイコンを表示
/// 
/// クリーンアーキテクチャにおける位置づけ:
/// - Presentation層の再利用可能なUIコンポーネント
/// - 設定画面で使用される共通Widget
class SettingItem extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final Color? textColor;
  final bool showArrow;

  const SettingItem({
    super.key,
    required this.text,
    this.onTap,
    this.textColor,
    this.showArrow = true,
  });

  @override
  Widget build(BuildContext context) {
    // 「岩と粉」: リスト項目は罫線区切りでなくカード面で表現する
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
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                text,
                style: AppText.body(
                  size: 14,
                  weight: FontWeight.w500,
                  color: textColor ?? AppColors.chalk,
                ),
              ),
              if (showArrow)
                Icon(
                  Icons.arrow_forward_ios,
                  color: textColor ?? AppColors.sunabokori,
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }
}