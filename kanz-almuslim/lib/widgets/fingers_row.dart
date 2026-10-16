import 'package:flutter/material.dart';

import '../theme.dart';

/// يتحكم بالأصابع من خارجها: كل لمسة على الشاشة تطلق إصبعاً.
class FingersController {
  _FingersRowState? _state;

  /// هل يوجد إصبع جاهز للانطلاق؟
  bool get canLaunch => _state?._nextReady() != null;

  /// يطلق الإصبع التالي للأعلى. [payload] يعود مع [FingersRow.onMorphed].
  bool launch(int payload) => _state?._launchNext(payload) ?? false;

  /// سحب من أي مكان في الشاشة: الإصبع التالي يتبع اللمس.
  /// يرجع false إذا لم يوجد إصبع جاهز.
  bool dragStart() => _state?._dragBegin(null) ?? false;
  void dragUpdate(double dy) => _state?._dragMove(dy);

  /// عند رفع اللمس: ينطلق الإصبع إذا سُحب كفاية (ويُحسب عبر onSwipe)، وإلا يعود لمكانه.
  /// يرجع true إذا انطلق.
  bool dragEnd(double velocity) => _state?._dragFinish(velocity) ?? false;
}

/// يُستدعى عندما يكتمل تحوّل الإصبع إلى نقطة: مركزها (إحداثيات الشاشة) وقطرها.
typedef FingerMorphed = void Function(Offset globalCenter, double size, int payload);

/// الأصابع الخمسة أسفل شاشة التسبيح (من تصميم النسخة الأصلية).
///
/// مع كل تسبيحة يصعد إصبع ويتحوّل تدريجياً إلى نقطة مضيئة، ثم تُسلَّم
/// النقطة لـ[FingerMorphed] لتكمل طريقها حول السبحة.
/// الأصابع تختفي واحداً واحداً، وبعد اختفاء الخامس تعود كلها بارتداد ناعم.
/// يمكن أيضاً سحب أي إصبع للأعلى مباشرة.
class FingersRow extends StatefulWidget {
  const FingersRow({
    super.key,
    required this.controller,
    required this.onSwipe,
    required this.onMorphed,
    this.count = 5,
  });

  final FingersController controller;

  /// يُستدعى عند سحب إصبع للأعلى (اللمس العادي يُحسب من الشاشة)،
  /// ويرجع القيمة التي تُمرَّر لاحقاً مع [onMorphed].
  final int Function() onSwipe;
  final FingerMorphed onMorphed;
  final int count;

  @override
  State<FingersRow> createState() => _FingersRowState();
}

class _FingersRowState extends State<FingersRow> with TickerProviderStateMixin {
  static const _flyDuration = Duration(milliseconds: 240);

  /// كم يصعد الإصبع (نسبة من ارتفاعه) وحجم النقطة (نسبة من عرضه).
  static const riseFactor = 0.55;
  static const dotFactor = 0.5;
  static const _growDuration = Duration(milliseconds: 460);

  late final List<AnimationController> _fly;
  late final List<AnimationController> _grow;
  late final List<double> _drag;

  /// الإصبع الذي يتبع اللمس الآن، وارتفاع الصف (لحدود السحب).
  int? _dragging;
  double _rowHeight = 150;
  late final AnimationController _snap;
  late final List<GlobalKey> _keys;

  /// الأصابع التي انطلقت (تطير أو اختفت) ومكانها لحظة الانطلاق.
  late final List<bool> _launched;
  late final List<int> _launchSlot;

  /// اختفى تماماً (انتهى طيرانه): عندها فقط تتزحلق الأصابع الباقية لليمين.
  late final List<bool> _gone;

  /// عند عودة الأصابع تأخذ أماكنها فوراً بلا انزلاق.
  bool _instant = false;
  static const _slide = Duration(milliseconds: 220);

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
    _snap = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _keys = List.generate(widget.count, (_) => GlobalKey());
    _launched = List.filled(widget.count, false);
    _launchSlot = List.filled(widget.count, 0);
    _gone = List.filled(widget.count, false);
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
    _snap.dispose();
    for (final c in [..._fly, ..._grow]) {
      c.dispose();
    }
    super.dispose();
  }

  /// الإصبع جاهز إذا كان في مكانه (لم يطِر بعد ولا يعود الآن).
  bool _ready(int i) => _fly[i].value == 0 && !_fly[i].isAnimating && _grow[i].value >= 1;

  /// كل الأصابع طارت واختفت.
  bool get _allGone => _fly.every((f) => f.value == 1 && !f.isAnimating);

  int? _nextReady() {
    for (var i = 0; i < widget.count; i++) {
      if (_ready(i)) return i;
    }
    return null;
  }

  /// يطلق أول إصبع جاهز بالترتيب. الأصابع تختفي واحداً واحداً
  /// ولا تعود إلا بعد اختفاء آخر إصبع. العدّ لا يتوقف في الأثناء.
  bool _launchNext(int payload) {
    final i = _nextReady();
    if (i == null) return false;
    _animate(i, payload);
    return true;
  }

  /// مكان الإصبع من اليمين: بعد اختفاء الإصبع المنطلق تتزحلق الباقية لليمين لتملأ الفراغ.
  int _slot(int i) {
    if (_launched[i]) return _launchSlot[i];
    var k = 0;
    for (var j = 0; j < i; j++) {
      if (!_gone[j]) k++;
    }
    return k;
  }

  bool _dragBegin(int? i) {
    final idx = i ?? _nextReady();
    if (idx == null || !_ready(idx)) return false;
    _snap.stop();
    _dragging = idx;
    return true;
  }

  void _dragMove(double dy) {
    final i = _dragging;
    if (i == null) return;
    // يتبع اللمس مباشرة، مع مقاومة خفيفة كلما ارتفع.
    final next = _drag[i] + dy * (1 - (-_drag[i] / (_rowHeight * 1.6)).clamp(0.0, 0.6));
    setState(() => _drag[i] = next.clamp(-_rowHeight * 0.9, 0.0));
  }

  bool _dragFinish(double velocity) {
    final i = _dragging;
    _dragging = null;
    if (i == null) return false;
    if (_drag[i] < -_rowHeight * 0.22 || velocity < -300) {
      _animate(i, widget.onSwipe());
      return true;
    }
    // لم يُسحب كفاية: يعود لمكانه بنعومة.
    final from = _drag[i];
    void tick() {
      if (mounted) setState(() => _drag[i] = from * (1 - Curves.easeOutBack.transform(_snap.value)));
    }

    _snap.addListener(tick);
    _snap.forward(from: 0).whenCompleteOrCancel(() => _snap.removeListener(tick));
    return false;
  }

  Future<void> _animate(int i, int payload) async {
    setState(() {
      _launchSlot[i] = _slot(i);
      _launched[i] = true;
    });
    await _fly[i].forward(from: 0);
    if (!mounted) return;
    final box = _keys[i].currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      final w = box.size.width;
      final h = box.size.height;
      final dot = w * dotFactor;
      final center = Offset(w / 2, h + _drag[i] - h * riseFactor - dot / 2);
      widget.onMorphed(box.localToGlobal(center), dot, payload);
    }
    setState(() {
      _drag[i] = 0;
      _gone[i] = true;
    });
    if (_allGone) await _regrowAll();
  }

  /// تعود الأصابع الخمسة معاً من الأسفل، بتتابع خفيف من اليمين.
  Future<void> _regrowAll() async {
    setState(() {
      _instant = true;
      for (var j = 0; j < widget.count; j++) {
        _grow[j].value = 0;
        _fly[j].value = 0;
        _launched[j] = false;
        _gone[j] = false;
      }
    });
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;
    setState(() => _instant = false);
    for (var j = 0; j < widget.count; j++) {
      if (!mounted) return;
      _grow[j].forward(from: 0);
      if (j < widget.count - 1) await Future<void>.delayed(const Duration(milliseconds: 70));
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        const gap = 8.0;
        final w = (c.maxWidth - gap * (widget.count + 1)) / widget.count;
        final h = c.maxHeight;
        _rowHeight = h;
        // الإصبع التالي (الأكثر إضاءة) دائماً على اليمين، والباقي يتزحلق إليه.
        return Stack(
          clipBehavior: Clip.none,
          // الإصبع المنطلق يُرسم فوق الباقي حتى لا يغطيه الإصبع الذي يتزحلق مكانه.
          children: [
            for (final i in [
              for (var j = 0; j < widget.count; j++)
                if (!_launched[j]) j,
              for (var j = 0; j < widget.count; j++)
                if (_launched[j]) j,
            ])
              Builder(
                builder: (context) {
                  final slot = _slot(i);
                  return AnimatedPositioned(
                    key: ValueKey(i),
                    duration: _instant ? Duration.zero : _slide,
                    curve: Curves.easeOutCubic,
                    right: gap + slot * (w + gap),
                    bottom: 0,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onVerticalDragStart: (_) => _dragBegin(i),
                      onVerticalDragUpdate: (d) => _dragMove(d.delta.dy),
                      onVerticalDragEnd: (d) => _dragFinish(d.primaryVelocity ?? 0),
                      child: SizedBox(
                        key: _keys[i],
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
                            lead: slot == 0 && !_gone[i],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
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
    // طار وتحوّل إلى نقطة: النقطة الآن في طبقة المدار.
    if (fly >= 1) return const SizedBox.shrink();

    // الصعود يتسارع حتى لحظة التحوّل، فتنطلق النقطة بسرعتها بلا توقف.
    final rise = Curves.easeInQuad.transform(fly);
    final morph = Curves.easeOutCubic.transform(fly);
    final dot = width * _FingersRowState.dotFactor;
    final w = width + (dot - width) * morph;
    final h = height + (dot - height) * morph;
    final glow = Curves.easeIn.transform(fly);

    // العودة: نمو من الأسفل مع ارتداد ناعم.
    final regrow = Curves.easeOutBack.transform(grow).clamp(0.0, 1.08);
    final dy = drag - rise * height * _FingersRowState.riseFactor + (1 - regrow) * height;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        // موجة دائرية تنتشر من مكان الإصبع عند انطلاقه.
        if (fly > 0)
          Positioned(
            bottom: height * 0.15,
            child: IgnorePointer(
              child: Opacity(
                opacity: (1 - fly) * 0.6,
                child: Container(
                  width: width * (0.7 + 1.1 * rise),
                  height: width * (0.7 + 1.1 * rise),
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
          child: _Finger(width: w, height: h, lead: lead, glow: glow, morph: morph),
        ),
      ],
    );
  }
}

class _Finger extends StatelessWidget {
  const _Finger({
    required this.width,
    required this.height,
    required this.lead,
    required this.glow,
    required this.morph,
  });
  final double width;
  final double height;
  final bool lead;
  final double glow;
  final double morph;

  @override
  Widget build(BuildContext context) {
    final top = lead ? KanzColors.pillarActiveTop : KanzColors.pillarTop;
    final bottom = lead ? KanzColors.pillarActiveBottom : KanzColors.pillarBottom;
    // يبيضّ لونه تدريجياً كلما اقترب من شكل النقطة.
    final c1 = Color.lerp(top, Colors.white, morph * 0.85)!;
    final c2 = Color.lerp(bottom, KanzColors.beadLit, morph)!;
    final arrow = (1 - morph * 2.2).clamp(0.0, 1.0);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(width / 2),
          bottom: Radius.circular(width / 2 * morph),
        ),
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [c1, c2]),
        boxShadow: [
          if (glow > 0)
            BoxShadow(
              color: KanzColors.cyan.withValues(alpha: 0.6 * glow),
              blurRadius: 4 + 18 * glow,
              spreadRadius: 1,
            ),
        ],
      ),
      alignment: Alignment.topCenter,
      padding: EdgeInsets.only(top: width * 0.2),
      child: arrow > 0
          ? Opacity(
              opacity: arrow,
              child: Icon(Icons.keyboard_arrow_up, size: width * 0.62, color: KanzColors.pillarChevron),
            )
          : null,
    );
  }
}
