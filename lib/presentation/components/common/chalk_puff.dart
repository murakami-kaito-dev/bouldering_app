import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_tokens.dart';
import '../../theme/app_text.dart';

/// 投稿完了のお祝い演出 — チョークの粉がふわっと舞い、メッセージが浮かぶ
///
/// 「登れた瞬間を褒める」ための、このアプリ唯一の派手な演出。
/// ルートNavigatorのOverlayに重ねるので、シートが閉じた後でも表示され続ける。
Future<void> showChalkPuffCelebration(
  BuildContext context, {
  String message = 'ボル活を記録しました',
}) async {
  final overlay = Navigator.of(context, rootNavigator: true).overlay;
  if (overlay == null) return;

  HapticFeedback.mediumImpact();
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _ChalkPuffToast(
      message: message,
      onDone: () => entry.remove(),
    ),
  );
  overlay.insert(entry);
}

class _ChalkPuffToast extends StatefulWidget {
  const _ChalkPuffToast({required this.message, required this.onDone});

  final String message;
  final VoidCallback onDone;

  @override
  State<_ChalkPuffToast> createState() => _ChalkPuffToastState();
}

class _ChalkPuffToastState extends State<_ChalkPuffToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    // 粉の配置は毎回同じで良い（乱数シード固定＝リビルドでも揺れない）
    final rand = math.Random(7);
    _particles = List.generate(22, (i) {
      final angle = rand.nextDouble() * math.pi * 2;
      return _Particle(
        angle: angle,
        distance: 46 + rand.nextDouble() * 74,
        size: 3.5 + rand.nextDouble() * 5.5,
        delay: rand.nextDouble() * 0.25,
        drift: 10 + rand.nextDouble() * 18,
      );
    });
    _controller.forward().whenCompleteOrCancel(widget.onDone);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          // メッセージカード: バネで出現(0〜0.3) → 表示 → フェードアウト(0.75〜1.0)
          final appear =
              Curves.easeOutBack.transform((t / 0.3).clamp(0.0, 1.0));
          final fade = t < 0.75 ? 1.0 : 1.0 - (t - 0.75) / 0.25;

          return Stack(
            alignment: Alignment.center,
            children: [
              // チョークの粉
              CustomPaint(
                size: const Size(280, 280),
                painter: _PuffPainter(t, _particles),
              ),
              // メッセージ
              Opacity(
                opacity: fade.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: 0.8 + 0.2 * appear,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 13),
                    decoration: BoxDecoration(
                      color: AppColors.setsuri,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: AppColors.wareme),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Text(
                      widget.message,
                      style: AppText.heading(size: 15),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Particle {
  const _Particle({
    required this.angle,
    required this.distance,
    required this.size,
    required this.delay,
    required this.drift,
  });

  final double angle;
  final double distance;
  final double size;
  final double delay;

  /// 上方向への流れ（粉が舞い上がる感じ）
  final double drift;
}

class _PuffPainter extends CustomPainter {
  _PuffPainter(this.t, this.particles);

  final double t;
  final List<_Particle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint();

    for (final p in particles) {
      // 各粒はdelayぶん遅れて出発し、easeOutで減速しながら飛ぶ
      final local = ((t - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (local <= 0) continue;
      final eased = Curves.easeOutCubic.transform(local);

      final pos = center +
          Offset(math.cos(p.angle), math.sin(p.angle)) * p.distance * eased -
          Offset(0, p.drift * eased); // ふわっと上へ

      paint.color = AppColors.chalk.withOpacity((1 - local) * 0.85);
      canvas.drawCircle(pos, p.size * (0.7 + 0.3 * (1 - local)), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PuffPainter oldDelegate) =>
      oldDelegate.t != t;
}
