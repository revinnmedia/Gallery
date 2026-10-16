import 'dart:math';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../theme.dart';

/// رحلة نقطة واحدة: من مكان الإصبع تدخل داخل حلقة السبحة، وتمرّ على
/// الحبات المضاءة فتومض وتكبر قليلاً، حتى تصل إلى أول مكان فارغ.
class OrbitFlight {
  const OrbitFlight({
    required this.start,
    required this.startSize,
    required this.center,
    required this.radius,
    required this.beadRadius,
    required this.target,
    this.beads = 33,
    required this.onArrive,
  });

  /// كل الإحداثيات بالنسبة للشاشة.
  final Offset start;
  final double startSize;
  final Offset center;
  final double radius;
  final double beadRadius;
  final int target;
  final int beads;
  final VoidCallback onArrive;
}

/// طبقة شفافة فوق شاشة التسبيح ترسم النقاط الطائرة.
class OrbitLayer extends StatefulWidget {
  const OrbitLayer({super.key});

  @override
  State<OrbitLayer> createState() => OrbitLayerState();
}

class OrbitLayerState extends State<OrbitLayer> with TickerProviderStateMixin {
  static const _flashMs = 260;
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
    // لفّة واحدة مع اتجاه امتلاء السبحة حتى حبتها. إذا كانت الحبة قريبة جداً
    // من نقطة الدخول تكمل لفّة واحدة كاملة بدل قفزة قصيرة.
    final targetAngle = -f.target * 2 * pi / f.beads;
    var sweep = (th0 - targetAngle) % (2 * pi);
    if (sweep < pi / 2) sweep += 2 * pi;
    final orbitMs = (650 + 380 * sweep / (2 * pi)).round();

    final ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: orbitMs + _flashMs),
    );
    final flight = _Flight(
      ctrl: ctrl,
      split: orbitMs / (orbitMs + _flashMs),
      center: c,
      start: c + v,
      th0: th0,
      sweep: sweep,
      radius: f.radius,
      beadRadius: f.beadRadius,
      startSize: f.startSize,
      target: f.target,
      beads: f.beads,
    );
    ctrl.addListener(() {
      if (!flight.arrived && ctrl.value >= flight.split) {
        flight.arrived = true;
        f.onArrive();
      }
    });
    // نبدأ بعد إطار واحد حتى لا تتوقف النقطة لحظة التسليم من الإصبع.
    ctrl.forward(from: 16 / (orbitMs + _flashMs)).whenComplete(() {
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
    required this.start,
    required this.th0,
    required this.sweep,
    required this.radius,
    required this.beadRadius,
    required this.startSize,
    required this.target,
    required this.beads,
  });

  final AnimationController ctrl;
  final double split;
  final Offset center;
  final Offset start;
  final double th0;
  final double sweep;
  final double radius;
  final double beadRadius;
  final double startSize;
  final int target;
  final int beads;
  bool arrived = false;

  /// منحنى سرعة واحد ناعم: تنطلق بسرعة الإصبع، ثم تتباطأ تدريجياً حتى تستقر.
  static const _glide = Cubic(0.3, 0.55, 0.25, 1);

  double angle(double t) => th0 - sweep * _glide.transform(t);

  Offset pos(double t) {
    final a = angle(t);
    final onRing = center + Offset(cos(a), sin(a)) * radius;
    // تنساب من مكان الإصبع مباشرة نحو نقطتها على خط الحبات (بلا انحراف للخارج).
    final enter = Curves.easeOutCubic.transform((t / 0.18).clamp(0.0, 1.0));
    return Offset.lerp(start, onRing, enter)!;
  }

  Offset beadPos(int i) {
    final a = -i * 2 * pi / beads;
    return center + Offset(cos(a), sin(a)) * radius;
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
    _paintBeadGlow(canvas, f, t);
    // أثر قصير وخفيف يجعل الحركة السريعة تبدو انسيابية.
    for (var k = 4; k >= 1; k--) {
      final tk = t - k * 0.012;
      if (tk < 0) continue;
      canvas.drawCircle(
        f.pos(tk),
        f.size(tk) / 2 * (1 - k * 0.12),
        Paint()..color = KanzColors.beadLit.withValues(alpha: 0.16 * (1 - k / 5)),
      );
    }
    final p = f.pos(t);
    final s = f.size(t);
    canvas.drawCircle(
      p,
      s * 0.8,
      Paint()
        ..color = KanzColors.cyan.withValues(alpha: 0.3)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.35),
    );
    canvas.drawCircle(p, s / 2, Paint()..color = Color.lerp(Colors.white, KanzColors.beadLit, t * 0.6)!);
  }

  /// الحبات القريبة من النقطة تومض وتكبر قليلاً وهي تمر بها، ويزداد ذلك
  /// تدريجياً كلما اقتربت من مكانها. الحبات غير المضاءة تومض بخفة فقط.
  void _paintBeadGlow(Canvas canvas, _Flight f, double t) {
    final a = f.angle(t);
    final grow = 0.1 + 0.2 * t;
    for (var i = 0; i < f.beads; i++) {
      final ai = -i * 2 * pi / f.beads;
      // المسافة الزاوية بين النقطة والحبة (الحبات خلفها تنطفئ ببطء).
      var d = (ai - a) % (2 * pi);
      if (d > pi) d -= 2 * pi;
      final k = d >= 0 ? exp(-pow(d / 0.32, 2)) : exp(-pow(d / 0.18, 2));
      if (k < 0.03) continue;
      final at = f.beadPos(i);
      final lit = i < f.target;
      canvas.drawCircle(
        at,
        f.beadRadius * (1.5 + grow),
        Paint()
          ..color = Colors.white.withValues(alpha: (lit ? 0.35 : 0.18) * k)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, f.beadRadius * 0.7),
      );
      if (!lit) continue;
      canvas.drawCircle(
        at,
        f.beadRadius * (1 + grow * k),
        Paint()..color = Color.lerp(KanzColors.beadLit, Colors.white, 0.45 * k)!,
      );
    }
  }

  void _paintFlash(Canvas canvas, _Flight f, double p) {
    final at = f.pos(1);
    final e = Curves.easeOut.transform(p);
    canvas.drawCircle(
      at,
      f.beadRadius * (1 + 1.1 * e),
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
