import 'package:flutter/material.dart';
import '../../theme/app_tokens.dart';
import '../../theme/app_text.dart';

/// 課題テープ — このアプリのシグネチャ部品
///
/// ジムで課題（ルート）を示す「少し斜めに貼られたビニールテープ」をUIの目印にする。
/// 種別タグ（ボルダリング/リード/スピード）・状態ラベル・選択チップに使う。
/// クライマーが毎日見ている記号なので、説明なしで伝わる。
///
/// 形: skewX(-8°)の平行四辺形・角丸2・太字ラベル。
/// 色: テープ色の上には必ず対応する濃色文字（app_tokensのon系）を載せる。
class TapeChip extends StatelessWidget {
  const TapeChip({
    super.key,
    required this.label,
    required this.color,
    this.selected,
    this.onTap,
    this.fontSize = 11,
  });

  /// ジム種別テープ: ボルダリング（ホールド赤）
  const TapeChip.bouldering({super.key, this.selected, this.onTap})
      : label = 'ボルダリング',
        color = AppColors.holdRed,
        fontSize = 11;

  /// ジム種別テープ: リード（ホールド緑）
  const TapeChip.lead({super.key, this.selected, this.onTap})
      : label = 'リード',
        color = AppColors.holdGreen,
        fontSize = 11;

  /// ジム種別テープ: スピード（ホールドシアン）
  const TapeChip.speed({super.key, this.selected, this.onTap})
      : label = 'スピード',
        color = AppColors.holdCyan,
        fontSize = 11;

  final String label;
  final Color color;

  /// null: 常時テープ表示（タグ用途）
  /// true: 選択中（テープ色） / false: 非選択（くすんだ面＋砂埃文字）
  final bool? selected;
  final VoidCallback? onTap;
  final double fontSize;

  /// テープ色に対する文字色（読める濃色）の対応
  static Color _onColorFor(Color c) {
    if (c == AppColors.holdRed) return AppColors.onHoldRed;
    if (c == AppColors.holdGreen) return AppColors.onHoldGreen;
    if (c == AppColors.holdCyan) return AppColors.onHoldCyan;
    if (c == AppColors.kabeBlue) return AppColors.onKabeBlue;
    return AppColors.onChalk;
  }

  @override
  Widget build(BuildContext context) {
    final bool dimmed = selected == false;
    final Color bg = dimmed ? AppColors.wareme : color;
    final Color fg = dimmed ? AppColors.sunabokori : _onColorFor(color);

    // 斜めのテープ本体。skewは描画のみ（レイアウト枠は変えない）ので、
    // 端の食み出しぶんだけ小さな余白を持たせる
    final chip = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Transform(
        transform: Matrix4.skewX(-0.14), // ≈ -8度
        alignment: Alignment.center,
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 4, 10, 5),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppRadius.tape),
          ),
          child: Transform(
            transform: Matrix4.skewX(0.14), // 文字は水平に戻す
            alignment: Alignment.center,
            child: Text(
              label,
              style: AppText.label(size: fontSize, color: fg),
            ),
          ),
        ),
      ),
    );

    if (onTap == null) return chip;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: chip,
    );
  }
}
