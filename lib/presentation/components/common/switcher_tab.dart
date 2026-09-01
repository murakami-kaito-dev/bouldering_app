import 'package:flutter/material.dart';
import '../../theme/app_tokens.dart';
import '../../theme/app_text.dart';

/// 2択タブ（施設情報/ボル活、みんなのボル活/お気に入り 等）
///
/// 選択中はチョーク文字＋壁ブルーの下線インジケータ、非選択は砂埃。
/// （青は「選択状態の印」にだけ使い、文字を青くしない＝色の役割ルール）
class SwitcherTab extends StatelessWidget {
  const SwitcherTab({
    super.key,
    required this.leftTabName,
    required this.rightTabName,
    this.backgroundColor = AppColors.iwa,
  });

  final String leftTabName;
  final String rightTabName;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(40.0),
      child: Container(
        height: 48,
        color: backgroundColor,
        child: TabBar(
          indicatorColor: AppColors.kabeBlue,
          indicatorWeight: 3,
          labelColor: AppColors.chalk,
          unselectedLabelColor: AppColors.sunabokori,
          labelStyle: AppText.heading(size: 16),
          unselectedLabelStyle: AppText.heading(size: 16),
          tabs: [
            Tab(text: leftTabName),
            Tab(text: rightTabName),
          ],
        ),
      ),
    );
  }
}
