import 'package:flutter/material.dart';
import '../common/gym_category.dart';

/// ジムタイプ選択UIコンポーネント
/// 
/// 役割:
/// - ボルダリング、リード、スピード等のタイプ選択UI
/// - 複数選択対応
/// - 選択状態の管理とコールバック
/// 
/// クリーンアーキテクチャにおける位置づけ:
/// - Presentation層のUIコンポーネント
/// - 単一責任の原則に従った専用コンポーネント
class GymTypeSelector extends StatelessWidget {
  const GymTypeSelector({
    super.key,
    required this.selectedTypes,
    required this.onTypeChanged,
  });

  final Map<String, bool> selectedTypes;
  final ValueChanged<Map<String, bool>> onTypeChanged;

  /// ジムタイプとカラーのマッピング
  static const Map<String, int> _typeColorMap = {
    'ボルダリング': 0xFFFF0F00,
    'リード': 0xFF00A24C,
    'スピード': 0xFF0057FF,
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: _typeColorMap.entries
            .map((entry) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildTypeButton(entry.key, entry.value),
                ))
            .toList(),
      ),
    );
  }

  /// ジムタイプボタン構築
  Widget _buildTypeButton(String type, int colorCode) {
    final isSelected = selectedTypes[type] ?? false;
    
    return GestureDetector(
      onTap: () {
        final updated = Map<String, bool>.from(selectedTypes);
        updated[type] = !isSelected;
        onTypeChanged(updated);
      },
      child: GymCategory(
        category: type,
        colorCode: colorCode,
        isSelected: isSelected,
        isTappable: true,
        onTap: () {
          final updated = Map<String, bool>.from(selectedTypes);
          updated[type] = !isSelected;
          onTypeChanged(updated);
        },
      ),
    );
  }
}