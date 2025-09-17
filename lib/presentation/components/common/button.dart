import 'package:flutter/material.dart';

/// 汎用ボタンコンポーネント
/// 
/// 役割:
/// - 統一されたデザインのボタンを提供
/// - カスタマイズ可能なサイズと色
/// 
/// クリーンアーキテクチャにおける位置づけ:
/// - Presentation層のCommonComponent
/// - 再利用可能なUI部品
class Button extends StatelessWidget {
  final VoidCallback onPressedFunction;
  final String buttonName;
  final double buttonWidth;
  final double buttonHeight;
  final int buttonColorCode;
  final int buttonTextColorCode;

  const Button({
    super.key,
    required this.onPressedFunction,
    required this.buttonName,
    required this.buttonWidth,
    required this.buttonHeight,
    required this.buttonColorCode,
    required this.buttonTextColorCode,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: buttonWidth,
      height: buttonHeight,
      child: ElevatedButton(
        onPressed: onPressedFunction,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(buttonColorCode),
          foregroundColor: Color(buttonTextColorCode),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          elevation: 0,
          padding: EdgeInsets.zero,
        ),
        child: Text(
          buttonName,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.50,
          ),
        ),
      ),
    );
  }
}