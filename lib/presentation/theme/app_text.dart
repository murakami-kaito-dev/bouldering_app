import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_tokens.dart';

/// タイポグラフィ「岩と粉」
///
/// 3つの役割で書体を使い分ける:
/// - display: 見出し・ジム名・タイトル → Zen Kaku Gothic New（幾何学ゴシック）
/// - num:     統計・料金・日付などの数字 → Barlow Condensed（記録の顔）
/// - body:    本文・説明 → Zen Kaku Gothic New Regular / システム
///
/// 色は既定でチョーク（主文字）。副次的な文字は color: AppColors.sunabokori を渡す。
class AppText {
  AppText._();

  /// 大見出し（画面タイトル・アプリ名）
  static TextStyle display({
    double size = 28,
    FontWeight weight = FontWeight.w700,
    Color color = AppColors.chalk,
    double height = 1.25,
  }) =>
      GoogleFonts.zenKakuGothicNew(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: 0.02,
      );

  /// 小見出し・強調
  static TextStyle heading({
    double size = 18,
    Color color = AppColors.chalk,
  }) =>
      GoogleFonts.zenKakuGothicNew(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.35,
      );

  /// 本文
  static TextStyle body({
    double size = 14,
    Color color = AppColors.chalk,
    FontWeight weight = FontWeight.w400,
    double height = 1.6,
  }) =>
      GoogleFonts.zenKakuGothicNew(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
      );

  /// 副文字（ラベル・注記・メタ情報）
  static TextStyle caption({
    double size = 12,
    Color color = AppColors.sunabokori,
    FontWeight weight = FontWeight.w400,
  }) =>
      GoogleFonts.zenKakuGothicNew(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: 1.4,
      );

  /// 数字（統計・料金・日付・カウント）。記録アプリの顔
  static TextStyle number({
    double size = 20,
    Color color = AppColors.chalk,
    FontWeight weight = FontWeight.w600,
  }) =>
      GoogleFonts.barlowCondensed(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: 1.0,
        letterSpacing: 0.2,
      );

  /// テープ・ボタンのラベル
  static TextStyle label({
    double size = 12,
    Color color = AppColors.chalk,
    FontWeight weight = FontWeight.w700,
  }) =>
      GoogleFonts.zenKakuGothicNew(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: 1.0,
        letterSpacing: 0.02,
      );
}
