import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// アプリ書体（Zen Kaku Gothic New / Barlow Condensed）の先読み
///
/// google_fonts は `GoogleFonts.zenKakuGothicNew(...)` のように TextStyle を作った瞬間に、
/// その「ファミリー×ウェイト」のフォントファイルを**非同期**で読み込む（同梱アセットからでも同じ）。
/// 読込が終わるまでエンジンはそのファミリー名を知らないので、文字は端末標準の書体
/// （iOS ならヒラギノ）で描かれ、読込完了で組み直されて本来の書体に変わる。
/// 画面を初めて出すフレームでこれが起きると「1〜2 フレームだけ違う書体」になる。
///
/// そこで、アプリで使う全ウェイトを runApp より前にまとめて読み込んでおく。
/// （書体を増やしたら [preload] にも足すこと。AppText で使うのは
///   Zen: w400 / w500 / w700、Barlow: w400 / w500 / w600 / w700）
class AppFonts {
  AppFonts._();

  static const List<FontWeight> _zenWeights = [
    FontWeight.w400,
    FontWeight.w500,
    FontWeight.w700,
  ];
  static const List<FontWeight> _barlowWeights = [
    FontWeight.w400,
    FontWeight.w500,
    FontWeight.w600,
    FontWeight.w700,
  ];

  /// 使う全ウェイトの読込を開始し、完了まで待つ（失敗・遅延しても起動は止めない）
  static Future<void> preload({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    // TextStyle を作ること自体が読込のトリガ（戻り値は使わない）
    for (final w in _zenWeights) {
      GoogleFonts.zenKakuGothicNew(fontWeight: w);
    }
    for (final w in _barlowWeights) {
      GoogleFonts.barlowCondensed(fontWeight: w);
    }
    try {
      await GoogleFonts.pendingFonts().timeout(timeout);
    } catch (_) {
      // 読めなかったウェイトは従来どおり端末標準の書体で描かれる
    }
  }
}
