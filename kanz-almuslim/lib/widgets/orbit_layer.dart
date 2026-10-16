import 'dart:math';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../theme.dart';

/// رحلة نقطة واحدة: من مكان الإصبع، تلتف حول السبحة، ثم تدخل حبتها.
class OrbitFlight {
  const OrbitFlight({
    required this.start,
    required this.startSize,
    required this.center,
    required this.radius,
    required this.beadRadius,
    required this.targetAngle,
    required this.onArrive,
  });

  /// كل الإحداثيات بالنسبة للشاشة.
  final Offset start;
  final double startSize;
  final Offset center;
  final double radius;
  final double beadRadius;
  final double targetAngle;
  final VoidCallback onArrive;
}

/// طبقة شفافة فوق شاشة التسبيح ترسم النقاط الطائرة.
class OrbitLayer extends StatefulWidget {
  const OrbitLayer({super.key});

  @override
  State<OrbitLayer> createState() => OrbitLayerState();
}

class OrbitLayerState extends State<OrbitLayer> with TickerProviderStateMixin {
  static const _flashMs = 340;
  final _flights = <_Flight>[];

  void add(OrbitFlight f) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      f.onArrive();
      return;
    }
    final c = box.globalToLocal(f.center);
    final v = box.globalToLocal(f.start) - c;
    final th0 = atan2(v.dy, v.dx);
    // تدور مع اتجاه امتلاء السبحة (عكس عقارب الساعة)، لفّة واحدة تقريباً على الأقل.
    var sweep = (th0 - f.targetAngle) % (2 * pi);
    if (sweep < 0.75 * pi) sweep += 2 * pi;
    final orbitMs = (620 + 240 * sweep / pi).round();

    final ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: orbitMs + _flashMs),
    );
    final flight = _Flight(
      ctrl: ctrl,
      split: orbitMs / (orbitMs + _flashMs),
      center: c,
      r0: v.distance,
      th0: th0,
      sweep: sweep,
      radius: f.radius,
      beadRadius: f.beadRadius,
      startSize: f.startSize,
    );
    ctrl.addListener(() {
      if (!flight.arrived && ctrl.value >= flight.split) {
        flight.arrived = true;
        f.onArrive();
      }
    });
    ctrl.forward().whenComplete(() {
      if (!mounted) return;
      setState(() => _flights.remove(flight));
      ctrl.dispose();
    });
    setState(() => _flights.add(flight));
  }

  /// يلغي كل النقاط الطائرة (عند التصفير أو تغيير الذكر).
  void clear() {
    for (final f in _flights) {
      f.ctrl.dispose();
    }
    setState(_flights.clear);
  }

  @override
  void dispose() {
    for (final f in _flights) {
      f.ctrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: Listenable.merge([for (final f in _flights) f.ctrl]),
        builder: (context, _) => CustomPaint(painter: _OrbitPainter(List.of(_flights)), size: Size.infinite),
      ),
    );
  }
}

class _Flight {
  _Flight({
    required this.ctrl,
    required this.split,
    required this.center,
    required this.r0,
    required this.th0,
    required this.sweep,
    required this.radius,
    required this.beadRadius,
    required this.startSize,
  });

  final AnimationController ctrl;
  final double split;
  final Offset center;
  final double r0;
  final double th0;
  final double sweep;
  final double radius;
  final double beadRadius;
  final double startSize;
  bool arrived = false;

  /// المدار يقع خارج الحبات بقليل.
  double get outer => radius + beadRadius * 2.4;

  Offset pos(double t) {
    final a = th0 - sweep * Curves.easeInOutSine.transform(t);
    final double r;
    if (t < 0.3) {
      r = lerpDouble(r0, outer, Curves.easeOut.transform(t / 0.3))!;
    } else if (t < 0.72) {
      r = outer;
    } else {
      r = lerpDouble(outer, radius, Curves.easeInOutCubic.transform((t - 0.72) / 0.28))!;
    }
    return center + Offset(cos(a), sin(a)) * r;
  }

  /// قطر النقطة: يصغر تدريجياً من حجم الإصبع إلى حجم الحبة.
  double size(double t) => lerpDouble(startSize, beadRadius * 2, Curves.easeOutCubic.transform(t))!;
}

class _OrbitPainter extends CustomPainter {
  _OrbitPainter(this.flights);
  final List<_Flight> flights;

  @override
  void paint(Canvas canvas, Size size) {
    for (final f in flights) {
      final u = f.ctrl.value;
      if (u < f.split) {
        _paintDot(canvas, f, u / f.split);
      } else {
        _paintFlash(canvas, f, (u - f.split) / (1 - f.split));
      }
    }
  }

  void _paintDot(Canvas canvas, _Flight f, double t) {
    // ذيل خفيف خلف النقطة.
    for (var k = 9; k >= 1; k--) {
      final tk = t - k * 0.02;
      if (tk < 0) continue;
      final fade = 1 - k / 10;
      canvas.drawCircle(
        f.pos(tk),
        f.size(tk) / 2 * (0.35 + 0.6 * fade),
        Paint()..color = KanzColors.beadLit.withValues(alpha: 0.32 * fade),
      );
    }
    final p = f.pos(t);
    final s = f.size(t);
    canvas.drawCircle(
      p,
      s * 0.95,
      Paint()
        ..color = KanzColors.cyan.withValues(alpha: 0.35)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.45),
    );
    canvas.drawCircle(p, s / 2, Paint()..color = Color.lerp(Colors.white, KanzColors.beadLit, t * 0.7)!);
  }

  void _paintFlash(Canvas canvas, _Flight f, double p) {
    final at = f.pos(1);
    final e = Curves.easeOut.transform(p);
    canvas.drawCircle(
      at,
      f.beadRadius * (1 + 1.7 * e),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2 * (1 - p) + 0.4
        ..color = KanzColors.cyan.withValues(alpha: 0.85 * (1 - p)),
    );
    canvas.drawCircle(
      at,
      f.beadRadius * 1.4,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.45 * (1 - e))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, f.beadRadius * 0.8),
    );
  }

  @override
  bool shouldRepaint(_OrbitPainter old) => true;
}
