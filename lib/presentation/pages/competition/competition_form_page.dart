import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/competition.dart';
import '../../../shared/utils/app_clock.dart';
import '../../components/competition/competition_confirm_dialog.dart';
import '../../providers/competition_providers.dart';
import '../../theme/app_text.dart';
import '../../theme/app_tokens.dart';
import 'competition_fee_page.dart';

/// コンペの設定画面（新規開催 と 編集 で共用）
///
/// 役割:
/// - 期間（開始日・終了日。日本時間の日付。終了日は 23:59:59 まで）
/// - 課題番号の範囲（何番から何番まで）
/// - 任意のタイトル
/// - 新規: 「決定」→ 無料／有料を選ぶ画面（competition_fee_page）へ
/// - 編集: 参加料もここで変更し、「保存」→ 確認ダイアログ → 更新
///
/// 時刻の基準は JST（AppClock）。端末のタイムゾーンに関係なく日本時間の日付で扱う
class CompetitionFormPage extends ConsumerStatefulWidget {
  const CompetitionFormPage({super.key, this.existing});

  /// 編集対象（null なら新規開催）
  final Competition? existing;

  @override
  ConsumerState<CompetitionFormPage> createState() => _CompetitionFormPageState();
}

class _CompetitionFormPageState extends ConsumerState<CompetitionFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _fromController;
  late final TextEditingController _toController;
  late final TextEditingController _feeController;

  late DateTime _startDate;
  late DateTime _endDate;
  late bool _isPaid;
  bool _submitting = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    final today = AppClock.todayJst();
    _titleController = TextEditingController(text: e?.title ?? '');
    _fromController = TextEditingController(text: e?.problemFrom.toString() ?? '1');
    _toController = TextEditingController(text: e?.problemTo.toString() ?? '');
    _feeController = TextEditingController(text: (e != null && e.entryFeeYen > 0) ? e.entryFeeYen.toString() : '');
    _startDate = e?.startDate ?? today;
    _endDate = e?.endDate ?? today.add(const Duration(days: 6));
    _isPaid = e != null && e.entryFeeYen > 0;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _fromController.dispose();
    _toController.dispose();
    _feeController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final today = AppClock.todayJst();
    final initial = isStart ? _startDate : _endDate;
    // 編集では既に始まっている期間も扱えるよう、下限は「今日」か「元の開始日」の早い方
    final existingStart = widget.existing?.startDate;
    final first = (existingStart != null && existingStart.isBefore(today)) ? existingStart : today;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(first) ? first : initial,
      firstDate: first,
      lastDate: today.add(const Duration(days: 365 * 2)),
      helpText: isStart ? '開始日を選択（日本時間）' : '終了日を選択（日本時間）',
    );
    if (picked == null) return;
    setState(() {
      final d = AppClock.dateOnly(picked);
      if (isStart) {
        _startDate = d;
        if (_endDate.isBefore(_startDate)) _endDate = _startDate;
      } else {
        _endDate = d;
        if (_startDate.isAfter(_endDate)) _startDate = _endDate;
      }
    });
  }

  CompetitionInput? _buildInput() {
    if (!_formKey.currentState!.validate()) return null;
    final from = int.parse(_fromController.text.trim());
    final to = int.parse(_toController.text.trim());
    final fee = _isPaid ? (int.tryParse(_feeController.text.trim()) ?? 0) : 0;
    return CompetitionInput(
      title: _titleController.text,
      startDate: _startDate,
      endDate: _endDate,
      problemFrom: from,
      problemTo: to,
      entryFeeYen: fee,
    );
  }

  /// 新規: 無料／有料の選択画面へ。開催が完了したら true で戻る
  Future<void> _decide() async {
    final input = _buildInput();
    if (input == null) return;
    // 新規開催では開催ジム = 本人の管理ジム（サーバーが users.managed_gym_id から決める）
    final gymName = widget.existing?.gymName;
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CompetitionFeePage(draft: input, gymName: gymName),
      ),
    );
    if (created == true && mounted) Navigator.of(context).pop(true);
  }

  /// 編集: 確認ダイアログ → 更新
  Future<void> _save() async {
    final input = _buildInput();
    if (input == null) return;
    final ok = await showCompetitionConfirmDialog(
      context: context,
      title: 'コンペを更新する',
      message: 'この内容でコンペを更新します。よろしいですか？',
      gymName: widget.existing!.gymName,
      periodDisplay: input.periodDisplay,
      problemRangeDisplay: input.problemRangeDisplay,
      feeDisplay: input.feeDisplay,
      confirmText: 'OK',
    );
    if (!ok || !mounted) return;

    setState(() => _submitting = true);
    try {
      await ref.read(competitionActionsProvider).update(widget.existing!.id, input);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'コンペを編集する' : 'コンペを開催する', style: AppText.heading(size: 17)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_isEdit)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(widget.existing!.gymName,
                    style: AppText.body(size: 14, color: AppColors.kabeBlue)),
              ),
            _SectionLabel('タイトル（任意）'),
            TextFormField(
              controller: _titleController,
              maxLength: 50,
              decoration: const InputDecoration(hintText: '例: 10月ボルダーコンペ（空ならジム名で表示）'),
            ),
            const SizedBox(height: 16),
            _SectionLabel('開催期間（日本時間）'),
            Row(
              children: [
                Expanded(child: _DateField(label: '開始日', date: _startDate, onTap: () => _pickDate(isStart: true))),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('〜', style: TextStyle(color: AppColors.sunabokori)),
                ),
                Expanded(child: _DateField(label: '終了日', date: _endDate, onTap: () => _pickDate(isStart: false))),
              ],
            ),
            const SizedBox(height: 6),
            Text('開始日の 0:00 から終了日の 23:59:59 まで開催します', style: AppText.caption(size: 11)),
            const SizedBox(height: 20),
            _SectionLabel('コンペ課題の番号'),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _fromController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(labelText: '何番から', hintText: '1'),
                    validator: (v) {
                      final n = int.tryParse((v ?? '').trim());
                      if (n == null || n < 1) return '1 以上の番号';
                      return null;
                    },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 18, left: 8, right: 8),
                  child: Text('〜', style: TextStyle(color: AppColors.sunabokori)),
                ),
                Expanded(
                  child: TextFormField(
                    controller: _toController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(labelText: '何番まで', hintText: '30'),
                    validator: (v) {
                      final to = int.tryParse((v ?? '').trim());
                      final from = int.tryParse(_fromController.text.trim());
                      if (to == null || to < 1) return '1 以上の番号';
                      if (from != null && to < from) return '始まりの番号以上';
                      if (from != null && to - from + 1 > 300) return '課題数は 300 まで';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('例: 1〜30 なら 30 課題。1 課題 = 1 点で順位を決めます', style: AppText.caption(size: 11)),
            if (_isEdit) ...[
              const SizedBox(height: 20),
              _SectionLabel('参加料'),
              Row(
                children: [
                  Expanded(
                    child: _ChoiceChip(
                      label: '無料',
                      selected: !_isPaid,
                      onTap: () => setState(() => _isPaid = false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ChoiceChip(
                      label: '有料',
                      selected: _isPaid,
                      onTap: () => setState(() => _isPaid = true),
                    ),
                  ),
                ],
              ),
              if (_isPaid) ...[
                const SizedBox(height: 10),
                TextFormField(
                  controller: _feeController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: '参加料（円）', suffixText: '円'),
                  validator: (v) {
                    if (!_isPaid) return null;
                    final n = int.tryParse((v ?? '').trim());
                    if (n == null || n < 1) return '1 円以上を入力';
                    return null;
                  },
                ),
              ],
            ],
            const SizedBox(height: 32),
            SizedBox(
              height: 49,
              child: ElevatedButton(
                onPressed: _submitting ? null : (_isEdit ? _save : _decide),
                child: Text(_isEdit ? '保存する' : '決定'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: AppText.caption(size: 11, weight: FontWeight.w700)),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.date, required this.onTap});

  final String label;
  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.setsuri,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.wareme),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppText.caption(size: 10)),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: AppColors.sunabokori),
                const SizedBox(width: 6),
                Text('${date.year}/${date.month}/${date.day}', style: AppText.number(size: 18)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.kabeBlue : AppColors.setsuri,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: selected ? AppColors.kabeBlue : AppColors.wareme),
        ),
        child: Text(label, style: AppText.label(size: 13, color: selected ? AppColors.onKabeBlue : AppColors.chalk)),
      ),
    );
  }
}
