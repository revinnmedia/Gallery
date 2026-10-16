import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';

/// الخلفية المتدرجة الأصلية مع نقش نجمة ثمانية خفيف.
class PatternBackground extends StatelessWidget {
  const PatternBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: KanzColors.backgroundGradient),
      child: CustomPaint(
        painter: _StarPatternPainter(Colors.white.withValues(alpha: 0.05)),
        child: child,
      ),
    );
  }
}

class _StarPatternPainter extends CustomPainter {
  _StarPatternPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    const cell = 64.0;
    for (var y = -cell / 2; y < size.height + cell; y += cell) {
      for (var x = -cell / 2; x < size.width + cell; x += cell) {
        _star(canvas, Offset(x, y), cell * 0.32, paint);
      }
    }
  }

  /// نجمة ثمانية: مربعان متداخلان أحدهما مدوّر ٤٥ درجة.
  void _star(Canvas canvas, Offset c, double r, Paint p) {
    for (final rot in [0.0, pi / 4]) {
      final path = Path();
      for (var i = 0; i < 4; i++) {
        final a = rot + i * pi / 2 + pi / 4;
        final pt = c + Offset(cos(a), sin(a)) * r;
        i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
      }
      path.close();
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(_StarPatternPainter old) => old.color != color;
}
