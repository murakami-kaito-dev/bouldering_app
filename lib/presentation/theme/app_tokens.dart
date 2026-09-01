import 'package:flutter/material.dart';

/// デザイントークン「岩と粉」（v2.1テーマ）
///
/// コンセプト: 夜のボルダリングウォール。
/// 色は「壁にあるもの」（岩・チョーク・ホールド・テープ）だけを使い、
/// 全ての色に役割を与える。**このファイル以外で色リテラルを定義しない。**
///
/// 提案書: .claude/docs/design/theme-proposal-iwa-to-kona.md
class AppColors {
  AppColors._();

  /// 岩肌: 画面の背景
  static const iwa = Color(0xFF15171B);

  /// 節理: カード・シート等の面
  static const setsuri = Color(0xFF1E2126);

  /// ナビ面: ボトムナビ・バー類（節理よりわずかに明るい）
  static const navi = Color(0xFF181B20);

  /// 割れ目: 罫線・区切り・非活性の面
  static const wareme = Color(0xFF2D313A);

  /// チョーク: 主文字（純白ではなく、わずかに温かい白）
  static const chalk = Color(0xFFF2F0EA);

  /// 砂埃: 副文字・ヒント・アイコンの非選択
  static const sunabokori = Color(0xFF9AA0AA);

  /// 壁ブルー: ブランド色。主ボタン・リンク・選択状態
  /// （現行ブランド #0056FF の、暗い壁で映える進化形）
  static const kabeBlue = Color(0xFF5B8CFF);

  /// 壁ブルーの上に載せる文字色（濃紺）
  static const onKabeBlue = Color(0xFF0C1A3A);

  /// ホールド赤: ボルダリング種別・エラー・破壊的操作
  static const holdRed = Color(0xFFFF7264);

  /// ホールド緑: リード種別・営業中・成功
  static const holdGreen = Color(0xFF3FCF8E);

  /// ホールドシアン: スピード種別
  static const holdCyan = Color(0xFF3EC6E0);
}

/// 角丸は3種だけ
class AppRadius {
  AppRadius._();

  /// テープ: 種別チップ・小さなラベル
  static const double tape = 2;

  /// カード: 面・入力欄・ダイアログ
  static const double card = 14;

  /// ピル: ボタン・検索バー・アバター
  static const double pill = 999;
}
