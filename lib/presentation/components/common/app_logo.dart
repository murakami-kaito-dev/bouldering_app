import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // アプリアイコン
      SvgPicture.asset(
        'lib/view/assets/app_main_icon.svg',
      ),
      // アプリ名テキスト
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          'イワノボリタイ',
          textAlign: TextAlign.center,
          style: GoogleFonts.rocknRollOne(
            color: Colors.black,
            fontSize: 28,
            fontWeight: FontWeight.w400,
            height: 1.2,
            letterSpacing: -0.5,
          ),
        ),
      ),
    ]);
  }
}