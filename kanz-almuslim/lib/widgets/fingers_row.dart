import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';

/// يتحكم بالأصابع من خارجها: كل لمسة على الشاشة تطلق إصبعاً.
class FingersController {
  _FingersRowState? _state;

  /// يطلق الإصبع التالي للأعلى.
  void launch() => _state?._launchNext();
}

/// الأصابع الخمسة أسفل شاشة التسبيح (من تصميم النسخة الأصلية).
///
/// مع كل تسبيحة يطير إصبع للأعلى مع توهّج خفيف ويتلاشى تدريجياً،
/// وتنتشر موجة دائرية من مكانه. بعد اختفاء الخامس تعود كلها بارتداد ناعم.
/// يمكن أيضاً سحب أي إصبع للأعلى مباشرة.
class FingersRow extends StatefulWidget {
  const FingersRow({super.key, required this.controller, required this.onCount, this.count = 5});

  final FingersController controller;

  /// يُستدعى عند سحب إصبع للأعلى (اللمس العادي يُحسب من الشاشة).
  final VoidCallback onCount;
  final int count;

  @override
  State<FingersRow> createState() => _FingersRowState();
}

class _FingersRowState extends State<FingersRow> with TickerProviderStateMixin {
  static const _flyDuration = Duration(milliseconds: 520);
  static const _growDuration = Duration(milliseconds: 460);

  late final List<AnimationController> _fly;
  late final List<AnimationController> _grow;
  late final List<double> _drag;

  @override
  void initState() {
    super.initState();
    widget.controller._state = this;
    _fly = List.generate(widget.count, (_) => AnimationController(vsync: this, duration: _flyDuration));
    _grow = List.generate(
      widget.count,
      (_) => AnimationController(vsync: this, duration: _growDuration, value: 1),
    );
    _drag = List.filled(widget.count, 0);
  }

  @override
  void didUpdateWidget(FingersRow old) {
    super.didUpdateWidget(old);
    old.controller._state = null;
    widget.controller._state = this;
  }

  @override
  void dispose() {
    widget.controller._state = null;
    for (final c in [..._fly, ..._grow]) {
      c.dispose();
    }
    super.dispose();
  }

  /// الإصبع جاهز إذا كان في مكانه (لم يطِر بعد ولا يعود الآن).
  bool _ready(int i) => _fly[i].value == 0 && !_fly[i].isAnimating && _grow[i].value >= 1;

  /// كل الأصابع طارت واختفت.
  bool get _allGone => _fly.every((f) => f.value == 1 && !f.isAnimating);

  /// يطلق أول إصبع جاهز بالترتيب. الأصابع تختفي واحداً واحداً
  /// ولا تعود إلا بعد اختفاء آخر إصبع. العدّ لا يتوقف في الأثناء.
  void _launchNext() {
    for (var i = 0; i < widget.count; i++) {
      if (_ready(i)) {
        _animate(i);
        return;
      }
    }
  }

  Future<void> _animate(int i) async {
    await _fly[i].forward(from: 0);
    if (!mounted) return;
    setState(() => _drag[i] = 0);
    if (_allGone) await _regrowAll();
  }

  /// تعود الأصابع الخمسة معاً من الأسفل، بتتابع خفيف من اليمين.
  Future<void> _regrowAll() async {
    for (var j = 0; j < widget.count; j++) {
      _grow[j].value = 0;
      _fly[j].value = 0;
    }
    await Future<void>.delayed(const Duration(milliseconds: 120));
    for (var j = 0; j < widget.count; j++) {
      if (!mounted) return;
      _grow[j].forward(from: 0);
      if (j < widget.count - 1) await Future<void>.delayed(const Duration(milliseconds: 70));
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      const gap = 8.0;
      final w = (c.maxWidth - gap * (widget.count + 1)) / widget.count;
      final h = c.maxHeight;
      // الإصبع الأول (الأكثر إضاءة) على اليمين، والإطلاق يسير نحو اليسار.
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(widget.count, (i) {
            return Padding(
              padding: EdgeInsetsDirectional.only(start: gap, end: i == widget.count - 1 ? gap : 0),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragUpdate: (d) {
                  if (!_ready(i)) return;
                  setState(() => _drag[i] = (_drag[i] + d.delta.dy).clamp(-h * 0.6, 0));
                },
                onVerticalDragEnd: (d) {
                  final v = d.primaryVelocity ?? 0;
                  if (_ready(i) && (_drag[i] < -24 || v < -220)) {
                    widget.onCount();
                    _animate(i);
                  } else {
                    setState(() => _drag[i] = 0);
                  }
                },
                child: SizedBox(
                  width: w,
                  height: h,
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_fly[i], _grow[i]]),
                    builder: (context, _) => _FingerFrame(
                      width: w,
                      height: h,
                      fly: _fly[i].value,
                      grow: _grow[i].value,
                      drag: _drag[i],
                      lead: i == 0,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      );
    });
  }
}

/// يرسم إصبعاً واحداً في لحظة معيّنة من الحركة.
class _FingerFrame extends StatelessWidget {
  const _FingerFrame({
    required this.width,
    required this.height,
    required this.fly,
    required this.grow,
    required this.drag,
    required this.lead,
  });

  final double width;
  final double height;
  final double fly;
  final double grow;
  final double drag;
  final bool lead;

  @override
  Widget build(BuildContext context) {
    // الطيران: صعود سريع يتباطأ، تلاشٍ يتسارع، وتضيّق بسيط.
    final rise = Curves.easeOutCubic.transform(fly);
    final fade = 1 - Curves.easeInQuad.transform(fly);
    final squeeze = 1 - 0.18 * rise;
    final glow = sin(pi * fly); // يتوهج في منتصف الحركة.

    // العودة: نمو من الأسفل مع ارتداد ناعم.
    final regrow = Curves.easeOutBack.transform(grow).clamp(0.0, 1.08);

    final dy = drag - rise * (height * 1.6) + (1 - regrow) * height;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        // موجة دائرية تنتشر من مكان الإصبع عند انطلاقه.
        if (fly > 0 && fly < 1)
          Positioned(
            top: width * 0.1,
            child: IgnorePointer(
              child: Opacity(
                opacity: (1 - fly) * 0.7,
                child: Container(
                  width: width * (0.6 + 1.2 * rise),
                  height: width * (0.6 + 1.2 * rise),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: KanzColors.cyan, width: 2 * (1 - fly) + 0.5),
                  ),
                ),
              ),
            ),
          ),
        Transform.translate(
          offset: Offset(0, dy),
          child: Opacity(
            opacity: fade.clamp(0.0, 1.0),
            child: Transform.scale(
              scaleX: squeeze,
              alignment: Alignment.bottomCenter,
              child: _Finger(width: width, height: height, lead: lead, glow: glow),
            ),
          ),
        ),
      ],
    );
  }
}

class _Finger extends StatelessWidget {
  const _Finger({required this.width, required this.height, required this.lead, required this.glow});
  final double width;
  final double height;
  final bool lead;
  final double glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(width / 2)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: lead
              ? const [KanzColors.pillarActiveTop, KanzColors.pillarActiveBottom]
              : const [KanzColors.pillarTop, KanzColors.pillarBottom],
        ),
        boxShadow: [
          if (glow > 0)
            BoxShadow(
              color: KanzColors.cyan.withValues(alpha: 0.55 * glow),
              blurRadius: 22 * glow,
              spreadRadius: 1,
            ),
        ],
      ),
      alignment: Alignment.topCenter,
      padding: EdgeInsets.only(top: width * 0.2),
      child: Icon(Icons.keyboard_arrow_up, size: width * 0.62, color: KanzColors.pillarChevron),
    );
  }
}
