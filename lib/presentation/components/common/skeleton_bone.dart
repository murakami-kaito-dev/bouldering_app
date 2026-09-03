import 'package:flutter/material.dart';

/// 骨組み（読込中の場所取り）の共通色
/// 節理面より一段明るい「骨」の色（wareme と setsuri の中間）。BoulLogSkeleton と同じ値
const Color kSkeletonBone = Color(0xFF262A32);

/// 文字1行ぶんの場所を確保する骨組み
///
/// 役割:
/// - 取得後に入る文字と同じ [style] で透明な文字を1行描き、その高さのまま淡い面を重ねる
/// - 高さを数値で決め打ちしないので、フォント差し替えや行間変更があっても
///   「骨組み → 本物の文字」の差し替えでレイアウトが動かない
class SkeletonTextBone extends StatelessWidget {
  const SkeletonTextBone({
    super.key,
    required this.style,
    required this.width,
  });

  /// 取得後に表示する文字のスタイル（行の高さを決めるためだけに使う）
  final TextStyle style;

  /// 骨の横幅（double.infinity で行いっぱい）
  final double width;

  @override
  Widget build(BuildContext context) {
    final boneHeight = (style.fontSize ?? 14) * 0.8;
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        // 高さ確保用の透明な文字（文言は表示されない）
        Text(' - ', style: style.copyWith(color: Colors.transparent)),
        Container(
          width: width,
          height: boneHeight,
          decoration: BoxDecoration(
            color: kSkeletonBone,
            borderRadius: BorderRadius.circular(boneHeight / 2),
          ),
        ),
      ],
    );
  }
}
