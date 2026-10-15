import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';

/// حلقة السبحة: ٣٣ حبة تضيء واحدة تلو الأخرى.
///
/// كما في النسخة الأصلية: أول حبة عند الساعة ٣ (يمين الدائرة)،
/// ثم تمتلئ عكس عقارب الساعة (للأعلى ثم لليسار).
class BeadRing extends StatelessWidget {
  const BeadRing({super.key, required this.lit, this.beads = 33, required this.child});

  final int lit;
  final int beads;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final side = min(c.maxWidth, c.maxHeight);
      return Center(
        child: SizedBox.square(
          dimension: side,
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: lit.toDouble()),
            duration: const Duration(milliseconds: 160),
            builder: (context, v, _) => CustomPaint(
              painter: _RingPainter(v, beads),
              child: Center(child: child),
            ),
          ),
        ),
      );
    });
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.lit, this.beads);
  final double lit;
  final int beads;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final beadR = size.width * 0.041;
    final r = size.width / 2 - beadR - 2;
    final dim = Paint()..color = KanzColors.beadDim;
    final on = Paint()..color = KanzColors.beadLit;
    for (var i = 0; i < beads; i++) {
      // عكس عقارب الساعة بدءاً من اليمين.
      final a = -i * 2 * pi / beads;
      final pos = c + Offset(cos(a), sin(a)) * r;
      final fill = (lit - i).clamp(0.0, 1.0);
      canvas.drawCircle(pos, beadR, dim);
      if (fill > 0) {
        canvas.drawCircle(pos, beadR * (0.6 + 0.4 * fill), on..color = KanzColors.beadLit.withValues(alpha: fill));
      }
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.lit != lit || old.beads != beads;
}
