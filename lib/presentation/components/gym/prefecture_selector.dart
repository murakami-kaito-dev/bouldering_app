import 'package:flutter/material.dart';
import '../../../shared/constants/prefecture_constants.dart';
import '../../theme/app_tokens.dart';

/// 都道府県選択UIコンポーネント
/// 
/// 役割:
/// - 地域別都道府県選択UI提供
/// - 選択状態の管理とコールバック
/// - 再利用可能なコンポーネント
/// 
/// クリーンアーキテクチャにおける位置づけ:
/// - Presentation層のUIコンポーネント
/// - 単一責任の原則に従った専用コンポーネント
class PrefectureSelector extends StatelessWidget {
  const PrefectureSelector({
    super.key,
    required this.selectedPrefectures,
    required this.onPrefectureChanged,
  });

  final Map<String, bool> selectedPrefectures;
  final ValueChanged<Map<String, bool>> onPrefectureChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: PrefectureConstants.regionMap.entries
          .map((entry) => _buildRegionSection(entry.key, entry.value))
          .toList(),
    );
  }

  /// 地域セクション構築
  Widget _buildRegionSection(String regionName, List<String> prefectures) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
          child: Text(
            regionName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: prefectures.map((prefecture) {
            final isSelected = selectedPrefectures[prefecture] ?? false;
            return _buildPrefectureButton(prefecture, isSelected);
          }).toList(),
        ),
      ],
    );
  }

  /// 都道府県ボタン構築
  Widget _buildPrefectureButton(String prefecture, bool isSelected) {
    return GestureDetector(
      onTap: () {
        final updated = Map<String, bool>.from(selectedPrefectures);
        updated[prefecture] = !isSelected;
        onPrefectureChanged(updated);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.kabeBlue : AppColors.setsuri,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppColors.kabeBlue : AppColors.wareme,
          ),
        ),
        child: Text(
          prefecture,
          style: TextStyle(
            fontSize: 16,
            color: isSelected ? AppColors.onKabeBlue : AppColors.chalk,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}