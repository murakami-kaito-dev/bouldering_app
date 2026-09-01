import 'package:flutter/material.dart';
import '../../theme/app_tokens.dart';

class SwitcherTab extends StatelessWidget {
  const SwitcherTab(
      {super.key,
      required this.leftTabName,
      required this.rightTabName,
      this.colorCode = 0xFF15171B});
  final String leftTabName;
  final String rightTabName;
  final int colorCode;

  @override
  Widget build(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(40.0),
      child: Container(
        height: 48,
        color: Color(colorCode),
        child: TabBar(
          indicatorColor: AppColors.kabeBlue,
          labelColor: AppColors.kabeBlue,
          unselectedLabelColor: AppColors.chalk,
          labelStyle: const TextStyle(
            fontSize: 20,
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w600,
          ),
          tabs: [
            Tab(text: leftTabName),
            Tab(text: rightTabName),
          ],
        ),
      ),
    );
  }
}