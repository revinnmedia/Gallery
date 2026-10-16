import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';

/// دائرة التقدّم حول العداد (بلون دائرة "المئة" في النسخة الأصلية).
class CounterRing extends StatelessWidget {
  const CounterRing({super.key, required this.progress, required this.child, this.size = 260});

  final double progress;
  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: progress.clamp(0, 1)),
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        builder: (context, value, _) => CustomPaint(
          painter: _RingPainter(value),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 10;
    final track = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;
    canvas.drawCircle(center, radius, track);

    final inner = Paint()..color = Colors.white.withValues(alpha: 0.08);
    canvas.drawCircle(center, radius - 18, inner);

    if (progress <= 0) return;
    final arc = Paint()
      ..shader = const SweepGradient(
        startAngle: -pi / 2,
        endAngle: 3 * pi / 2,
        colors: [KanzColors.cyan, KanzColors.mint, KanzColors.cyan],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 12;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}
