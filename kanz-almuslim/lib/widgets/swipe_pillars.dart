import 'package:flutter/material.dart';

import '../theme.dart';

/// الأعمدة الخمسة أسفل شاشة التسبيح (كما في النسخة الأصلية):
/// اسحب أي عمود للأعلى فيطير ويُحسب تسبيحة، ثم يرجع من الأسفل.
class SwipePillars extends StatefulWidget {
  const SwipePillars({super.key, required this.onCount, this.count = 5});

  final VoidCallback onCount;
  final int count;

  @override
  State<SwipePillars> createState() => _SwipePillarsState();
}

class _SwipePillarsState extends State<SwipePillars>
    with TickerProviderStateMixin {
  late final List<AnimationController> _fly;
  late final List<AnimationController> _grow;
  late final List<double> _drag;

  @override
  void initState() {
    super.initState();
    _fly = List.generate(
      widget.count,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 260),
      ),
    );
    _grow = List.generate(
      widget.count,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 320),
        value: 1,
      ),
    );
    _drag = List.filled(widget.count, 0);
  }

  @override
  void dispose() {
    for (final c in [..._fly, ..._grow]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _launch(int i) async {
    if (_fly[i].isAnimating || _grow[i].value < 1) return;
    widget.onCount();
    await _fly[i].forward(from: 0);
    if (!mounted) return;
    setState(() => _drag[i] = 0);
    _grow[i].value = 0;
    _fly[i].value = 0;
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    await _grow[i].forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        const gap = 6.0;
        final w = (c.maxWidth - gap * (widget.count + 1)) / widget.count;
        final h = c.maxHeight;
        // الترتيب ثابت من اليسار لليمين، والعمود الأيمن هو المضيء.
        return Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(widget.count, (i) {
              final active = i == widget.count - 1;
              return Padding(
                padding: EdgeInsets.only(
                  left: gap,
                  right: i == widget.count - 1 ? gap : 0,
                ),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _launch(i),
                  onVerticalDragUpdate: (d) {
                    if (_fly[i].isAnimating) return;
                    setState(
                      () => _drag[i] = (_drag[i] + d.delta.dy).clamp(-h, 0),
                    );
                  },
                  onVerticalDragEnd: (d) {
                    final v = d.primaryVelocity ?? 0;
                    if (_drag[i] < -30 || v < -250) {
                      _launch(i);
                    } else {
                      setState(() => _drag[i] = 0);
                    }
                  },
                  child: SizedBox(
                    width: w,
                    height: h,
                    child: AnimatedBuilder(
                      animation: Listenable.merge([_fly[i], _grow[i]]),
                      builder: (context, _) {
                        final fly = Curves.easeIn.transform(_fly[i].value);
                        final grow = Curves.easeOut.transform(_grow[i].value);
                        final dy = _drag[i] - fly * (h + 200);
                        return ClipRect(
                          clipper: _AboveClipper(extra: 400),
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Transform.translate(
                              offset: Offset(0, dy + (1 - grow) * h),
                              child: Opacity(
                                opacity: (1 - fly * 0.7).clamp(0, 1),
                                child: _Pillar(
                                  width: w,
                                  height: h,
                                  active: active,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

/// يقص من الأسفل فقط حتى يطير العمود للأعلى فوق السبحة.
class _AboveClipper extends CustomClipper<Rect> {
  _AboveClipper({required this.extra});
  final double extra;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(-20, -size.height - extra, size.width + 20, size.height);

  @override
  bool shouldReclip(_AboveClipper old) => old.extra != extra;
}

class _Pillar extends StatelessWidget {
  const _Pillar({
    required this.width,
    required this.height,
    required this.active,
  });
  final double width;
  final double height;
  final bool active;

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
          colors: active
              ? const [
                  KanzColors.pillarActiveTop,
                  KanzColors.pillarActiveBottom,
                ]
              : const [KanzColors.pillarTop, KanzColors.pillarBottom],
        ),
      ),
      alignment: Alignment.topCenter,
      padding: EdgeInsets.only(top: width * 0.22),
      child: Icon(
        Icons.keyboard_arrow_up,
        size: width * 0.6,
        color: KanzColors.pillarChevron,
      ),
    );
  }
}
