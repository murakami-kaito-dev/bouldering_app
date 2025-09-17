import 'package:flutter/material.dart';

class GymCategory extends StatelessWidget {
  const GymCategory({
    super.key,
    required this.category,
    required this.colorCode,
    this.isSelected,
    this.isTappable = false,
    this.onTap,
  });

  final String category;
  final int colorCode;
  final bool? isSelected;
  final bool isTappable;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool showSelected = isSelected != null;
    final Color bgColor = showSelected
        ? (isSelected! ? Color(colorCode) : Colors.grey.shade300)
        : Color(colorCode);
    final Color textColor = showSelected
        ? (isSelected! ? Colors.white : Colors.black)
        : Colors.white;

    final categoryWidget = Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: ShapeDecoration(
          color: bgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          category,
          style: TextStyle(
            color: textColor,
            fontSize: 12,
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w600,
            height: 1.0,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );

    return isTappable
        ? GestureDetector(
            onTap: onTap,
            child: categoryWidget,
          )
        : categoryWidget;
  }
}