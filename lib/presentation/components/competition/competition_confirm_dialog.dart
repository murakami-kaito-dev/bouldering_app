import 'package:flutter/material.dart';

import '../../theme/app_text.dart';
import '../../theme/app_tokens.dart';

/// コンペの開催・編集・参加の最終確認ダイアログ
///
/// 期間・課題番号・参加料を並べて見せ、OK（true）／キャンセル（false）を返す。
/// 開催（無料・有料）と編集で同じ見た目にする
Future<bool> showCompetitionConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String periodDisplay,
  required String problemRangeDisplay,
  required String feeDisplay,
  String? gymName,
  String confirmText = 'OK',
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Text(title, style: AppText.heading(size: 17)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.iwa,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.wareme),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (gymName != null) ...[
                  _Line(label: 'ジム', value: gymName),
                  const SizedBox(height: 6),
                ],
                _Line(label: '期間', value: periodDisplay),
                const SizedBox(height: 6),
                _Line(label: '課題', value: problemRangeDisplay),
                const SizedBox(height: 6),
                _Line(label: '参加料', value: feeDisplay),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(message, style: AppText.body(size: 14)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmText),
        ),
      ],
    ),
  );
  return result ?? false;
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 52, child: Text(label, style: AppText.caption(size: 12))),
        Expanded(child: Text(value, style: AppText.body(size: 14, height: 1.3))),
      ],
    );
  }
}
