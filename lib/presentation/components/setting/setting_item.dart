import 'package:flutter/material.dart';
import '../../theme/app_tokens.dart';

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
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppColors.wareme,
              width: 1,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              text,
              style: TextStyle(
                color: textColor ?? AppColors.chalk,
                fontSize: 16,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w500,
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
    );
  }
}