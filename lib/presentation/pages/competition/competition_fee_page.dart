import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/competition.dart';
import '../../components/competition/competition_confirm_dialog.dart';
import '../../providers/competition_providers.dart';
import '../../theme/app_text.dart';
import '../../theme/app_tokens.dart';

/// 無料／有料を選んで開催する画面（新規開催の最終ステップ）
///
/// 役割:
/// - 「無料で開催する」→ 確認ダイアログ（期間・課題番号・0円）→ OK で開催
/// - 「有料で開催する」→ 参加料（円）を入力 → 確認ダイアログ → OK で開催
/// - 開催に成功したら true で戻る（前の設定画面も閉じる）
///
/// 注意: 参加料は保存するだけで、参加者の決済は未実装（お試し期間は無料参加）
class CompetitionFeePage extends ConsumerStatefulWidget {
  const CompetitionFeePage({super.key, required this.draft, this.gymName});

  /// 設定画面で決めた期間・課題番号（参加料は 0 のまま渡される）
  final CompetitionInput draft;
  final String? gymName;

  @override
  ConsumerState<CompetitionFeePage> createState() => _CompetitionFeePageState();
}

class _CompetitionFeePageState extends ConsumerState<CompetitionFeePage> {
  final _feeController = TextEditingController();
  bool _showPaidForm = false;
  bool _submitting = false;

  @override
  void dispose() {
    _feeController.dispose();
    super.dispose();
  }

  Future<void> _host(int feeYen) async {
    final input = widget.draft.copyWith(entryFeeYen: feeYen);
    final ok = await showCompetitionConfirmDialog(
      context: context,
      title: input.isFree ? '無料コンペを開催する' : '有料コンペを開催する',
      message: 'コンペを開催します。よろしいですか？',
      gymName: widget.gymName,
      periodDisplay: input.periodDisplay,
      problemRangeDisplay: input.problemRangeDisplay,
      feeDisplay: input.feeDisplay,
      confirmText: 'OK',
    );
    if (!ok || !mounted) return;

    setState(() => _submitting = true);
    try {
      await ref.read(competitionActionsProvider).create(input);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(competitionErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _hostPaid() {
    final fee = int.tryParse(_feeController.text.trim());
    if (fee == null || fee < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('参加料を 1 円以上で入力してください')),
      );
      return;
    }
    _host(fee);
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.draft;
    return Scaffold(
      appBar: AppBar(title: Text('参加料を決める', style: AppText.heading(size: 17))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 設定内容のおさらい
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.setsuri,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.wareme),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('設定した内容', style: AppText.caption(size: 11, weight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text('期間　${d.periodDisplay}', style: AppText.body(size: 14)),
                Text('課題　${d.problemRangeDisplay}', style: AppText.body(size: 14)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('どちらで開催しますか？', style: AppText.heading(size: 16)),
          const SizedBox(height: 12),

          // 無料
          _OptionCard(
            icon: Icons.volunteer_activism_outlined,
            title: '無料コンペ',
            description: '参加料なし。誰でも気軽に参加できます',
            buttonLabel: '無料で開催する',
            onPressed: _submitting ? null : () => _host(0),
          ),
          const SizedBox(height: 12),

          // 有料
          _OptionCard(
            icon: Icons.payments_outlined,
            title: '有料コンペ',
            description: '参加料（円）を設定します。※ 決済はまだ対応しておらず、参加者は無料で参加できます',
            buttonLabel: _showPaidForm ? 'この金額で開催する' : '有料で開催する',
            onPressed: _submitting
                ? null
                : () {
                    if (!_showPaidForm) {
                      setState(() => _showPaidForm = true);
                    } else {
                      _hostPaid();
                    }
                  },
            child: _showPaidForm
                ? Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: TextField(
                      controller: _feeController,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(labelText: '参加料（円）', suffixText: '円', hintText: '1000'),
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.onPressed,
    this.child,
  });

  final IconData icon;
  final String title;
  final String description;
  final String buttonLabel;
  final VoidCallback? onPressed;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.setsuri,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.wareme),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.kabeBlue),
              const SizedBox(width: 8),
              Text(title, style: AppText.heading(size: 15)),
            ],
          ),
          const SizedBox(height: 4),
          Text(description, style: AppText.caption(size: 12)),
          if (child != null) child!,
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(onPressed: onPressed, child: Text(buttonLabel)),
          ),
        ],
      ),
    );
  }
}
