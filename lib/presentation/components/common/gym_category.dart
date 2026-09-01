import 'package:flutter/material.dart';
import 'tape_chip.dart';

/// ジム種別タグ（ボルダリング/リード/スピード）
///
/// 見た目は「課題テープ」（TapeChip）。
/// Phase 2aで int の colorCode API を Color 型に刷新し、描画をテープに統一した。
class GymCategory extends StatelessWidget {
  const GymCategory({
    super.key,
    required this.category,
    required this.color,
    this.isSelected,
    this.isTappable = false,
    this.onTap,
  });

  final String category;
  final Color color;
  final bool? isSelected;
  final bool isTappable;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TapeChip(
        label: category,
        color: color,
        selected: isSelected,
        onTap: isTappable ? onTap : null,
      ),
    );
  }
}
