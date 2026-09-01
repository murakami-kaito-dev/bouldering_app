import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

/// 押下スプリング — 押すとキュッと縮み、離すと弾んで戻る（触感）
///
/// タップ処理は子（InkWell/GestureDetector/Button）に任せ、
/// これは「押されている間の見た目」だけを担う純粋な視覚ラッパー。
/// Listener（生ポインタイベント）なので子のタップ判定と競合しない。
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.pressedScale = 0.96,
  });

  final Widget child;

  /// 押下中の縮小率
  final double pressedScale;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  void _set(bool v) {
    if (_pressed != v && mounted) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1.0,
        // 押す時は素早く、戻る時はバネで弾む
        duration: _pressed
            ? const Duration(milliseconds: 80)
            : const Duration(milliseconds: 280),
        curve: _pressed ? Curves.easeOut : Curves.elasticOut,
        child: widget.child,
      ),
    );
  }
}
