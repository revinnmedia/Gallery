import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme.dart';

/// حلقة السبحة: ٣٣ حبة تضيء واحدة تلو الأخرى.
///
/// كما في النسخة الأصلية: أول حبة عند الساعة ٣ (يمين الدائرة)،
/// ثم تمتلئ عكس عقارب الساعة (للأعلى ثم لليسار).
class BeadRing extends StatelessWidget {
  const BeadRing({
    super.key,
    required this.lit,
    this.beads = 33,
    this.hidden = const {},
    this.scatter,
    required this.child,
  });

  final int lit;
  final int beads;

  /// حبات مضاءة لم تصلها نقطتها بعد، فتبقى خافتة حتى تدخلها.
  final Set<int> hidden;

  /// نهاية الدورة (٠→١): تصعد الحبات المضاءة واحدة تلو الأخرى وتختفي.
  final Animation<double>? scatter;
  final Widget child;

  /// نصف قطر الحبة لحلقة بعرض [side].
  static double beadRadius(double side) => side * 0.041;

  /// نصف قطر الحلقة التي تقع عليها مراكز الحبات.
  static double ringRadius(double side) => side / 2 - beadRadius(side) - 2;

  /// زاوية الحبة [i] (عكس عقارب الساعة بدءاً من اليمين).
  static double angleOf(int i, [int beads = 33]) => -i * 2 * pi / beads;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final side = min(c.maxWidth, c.maxHeight);
        return Center(
          child: SizedBox.square(
            dimension: side,
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: lit.toDouble()),
              duration: const Duration(milliseconds: 160),
              builder: (context, v, _) => CustomPaint(
                painter: _RingPainter(v, beads, hidden, scatter),
                child: Center(child: child),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.lit, this.beads, this.hidden, this.scatter) : super(repaint: scatter);
  final double lit;
  final int beads;
  final Set<int> hidden;
  final Animation<double>? scatter;

  /// الفارق الزمني بين انطلاق كل حبة والتي تليها.
  static const _stagger = 0.015;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final beadR = BeadRing.beadRadius(size.width);
    final r = BeadRing.ringRadius(size.width);
    final dim = Paint()..color = KanzColors.beadDim;
    final on = Paint()..color = KanzColors.beadLit;
    final sc = scatter?.value ?? 0;
    final span = 1 - _stagger * (beads - 1);
    for (var i = 0; i < beads; i++) {
      // عكس عقارب الساعة بدءاً من اليمين.
      final a = BeadRing.angleOf(i, beads);
      final pos = c + Offset(cos(a), sin(a)) * r;
      final fill = (lit - i).clamp(0.0, 1.0);
      canvas.drawCircle(pos, beadR, dim);
      if (fill > 0 && !hidden.contains(i)) {
        // الصعود: تتسارع للأعلى وتكبر قليلاً وتتلاشى.
        final p = ((sc - i * _stagger) / span).clamp(0.0, 1.0);
        if (p >= 1) continue;
        final rise = Curves.easeInCubic.transform(p);
        canvas.drawCircle(
          pos - Offset(0, rise * size.height * 0.55),
          beadR * (0.6 + 0.4 * fill) * (1 + 0.25 * p),
          on..color = KanzColors.beadLit.withValues(alpha: fill * (1 - Curves.easeIn.transform(p))),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.lit != lit || old.beads != beads || !setEquals(old.hidden, hidden);
}
