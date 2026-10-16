import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n.dart';
import '../services/cloud_service.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/bead_ring.dart';
import '../widgets/fingers_row.dart';
import '../widgets/orbit_layer.dart';
import '../widgets/pattern_background.dart';
import 'manage_dhikr_screen.dart';

class TasbeehScreen extends StatefulWidget {
  const TasbeehScreen({super.key});

  @override
  State<TasbeehScreen> createState() => _TasbeehScreenState();
}

class _TasbeehScreenState extends State<TasbeehScreen> with TickerProviderStateMixin {
  late final AnimationController _pulse;
  bool _celebrating = false;
  final _fingers = FingersController();
  final _orbit = GlobalKey<OrbitLayerState>();
  final _ring = GlobalKey();

  /// حبات أُضيئت لكن نقطتها ما زالت في الطريق إليها.
  final List<int> _incoming = [];

  /// نهاية الدورة: اهتزاز الشاشة، ثم تصعد الحبات وتختفي ويبدأ عدّ جديد.
  late final AnimationController _shake;
  late final AnimationController _scatter;

  /// اكتملت الدورة وننتظر وصول نقطة الحبة الأخيرة لنبدأ.
  bool _clearOnArrive = false;

  /// اختفت الحبات: نعرض صفراً حتى التسبيحة التالية.
  bool _fresh = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 140));
    _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
    _scatter = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  }

  @override
  void dispose() {
    _pulse.dispose();
    _shake.dispose();
    _scatter.dispose();
    super.dispose();
  }

  /// عدد الحبات المضاءة: ٣٣ دائماً؛ إذا كانت الدورة أطول تضيء بالنسبة.
  static int _litFor(AppState state) {
    final target = state.current.target;
    final cycle = state.displayCount;
    return target == 33 || target <= 0 ? cycle : (cycle * 33 / target).round();
  }

  void _onTap() {
    if (_celebrating) return;
    if (!_fingers.canLaunch) {
      _count();
      return;
    }
    _fingers.launch(_count(fly: true));
  }

  /// تسبيحة واحدة (من لمس الشاشة أو سحب إصبع).
  /// يرجع رقم الحبة التي ستطير إليها النقطة، أو -1.
  int _count({bool fly = false}) {
    if (_celebrating) return -1;
    final state = context.read<AppState>();
    // لمسة أثناء صعود الحبات: نُنهي الحركة فوراً ونبدأ الدورة الجديدة.
    if (_fresh || _scatter.isAnimating || _clearOnArrive) {
      _scatter.value = 0;
      _clearOnArrive = false;
      _fresh = false;
    }
    final before = _litFor(state);
    final result = state.tap();
    final after = _litFor(state);
    _pulse.forward(from: 0);
    if (result.hundred) _celebrate();
    if (result.cycleDone) {
      if (fly) {
        _clearOnArrive = true;
      } else {
        _cycleComplete();
      }
    }
    if (after <= 0) return -1;
    final bead = after - 1;
    if (fly && after != before) setState(() => _incoming.add(bead));
    return bead;
  }

  /// تحوّل الإصبع إلى نقطة: نطلقها حول السبحة إلى حبتها.
  void _onMorphed(Offset start, double size, int bead) {
    final box = _ring.currentContext?.findRenderObject() as RenderBox?;
    final orbit = _orbit.currentState;
    if (bead < 0 || box == null || !box.hasSize || orbit == null) {
      _arrived(bead);
      return;
    }
    final side = min(box.size.width, box.size.height);
    orbit.add(
      OrbitFlight(
        start: start,
        startSize: size,
        center: box.localToGlobal(box.size.center(Offset.zero)),
        radius: BeadRing.ringRadius(side),
        beadRadius: BeadRing.beadRadius(side),
        target: bead,
        onArrive: () => _arrived(bead),
      ),
    );
  }

  void _arrived(int bead) {
    if (!mounted) return;
    if (_incoming.remove(bead)) setState(() {});
    if (_clearOnArrive && bead == 32) {
      _clearOnArrive = false;
      _cycleComplete();
    }
  }

  /// اكتملت الدورة: ترتجّ الشاشة، وتصعد الحبات بتتابع سريع وتختفي.
  Future<void> _cycleComplete() async {
    _shake.forward(from: 0);
    await _scatter.forward(from: 0);
    if (mounted && _scatter.value == 1) setState(() => _fresh = true);
  }

  /// عند التصفير أو تغيير الذكر تُلغى النقاط الطائرة.
  void _clearFlights() {
    _orbit.currentState?.clear();
    _scatter.value = 0;
    _clearOnArrive = false;
    _fresh = false;
    setState(_incoming.clear);
  }

  /// الذكر التالي/السابق (بالأسهم أو بالسحب أفقياً على السبحة).
  void _step(AppState state, int delta) {
    final n = state.dhikrs.length;
    if (n < 2) return;
    _clearFlights();
    state.selectDhikr((state.currentIndex + delta) % n);
  }

  Future<void> _celebrate() async {
    _celebrating = true;
    final state = context.read<AppState>();
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _CelebrationDialog(total: state.total),
    );
    _celebrating = false;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final d = state.current;
    final cycle = _fresh ? 0 : state.displayCount;
    final lit = _fresh ? 0 : _litFor(state);

    return PatternBackground(
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _shake,
            builder: (context, child) {
              final t = _shake.value;
              final dx = t == 0 || t == 1 ? 0.0 : sin(t * pi * 7) * 9 * (1 - t);
              return Transform.translate(offset: Offset(dx, 0), child: child);
            },
            child: SafeArea(
              child: Column(
                children: [
                  _TopBar(
                    today: state.todayTotal,
                    total: state.total,
                    soundOn: state.soundOn,
                    onSound: () => state.setSound(!state.soundOn),
                    onReset: state.currentCycle == 0
                        ? null
                        : () {
                            _clearFlights();
                            state.resetCycle();
                          },
                    onManage: () =>
                        Navigator.of(context)
                            .push(MaterialPageRoute(builder: (_) => const ManageDhikrScreen())),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _onTap,
                      child: Column(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(2, 10, 2, 6),
                              child: Stack(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 22),
                                    child: GestureDetector(
                                      onHorizontalDragEnd: (e) {
                                        final v = e.primaryVelocity ?? 0;
                                        if (v.abs() > 200) _step(state, v > 0 ? 1 : -1);
                                      },
                                      child: ScaleTransition(
                                        scale: Tween(begin: 1.0, end: 0.97).animate(
                                          CurvedAnimation(
                                            parent: _pulse,
                                            curve: Curves.easeOut,
                                            reverseCurve: Curves.easeIn,
                                          ),
                                        ),
                                        child: BeadRing(
                                          key: _ring,
                                          lit: lit,
                                          hidden: _incoming.toSet(),
                                          scatter: _scatter,
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                fmtNum(context, cycle),
                                                style: const TextStyle(
                                                  fontSize: 64,
                                                  fontWeight: FontWeight.w300,
                                                  color: Colors.white,
                                                  height: 1.1,
                                                ),
                                              ),
                                              Text(
                                                '/ ${fmtNum(context, d.target)}',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.white.withValues(alpha: 0.7),
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              // اسم الذكر داخل السبحة (من التصميم الأصلي).
                                              AnimatedSwitcher(
                                                duration: const Duration(milliseconds: 220),
                                                child: ConstrainedBox(
                                                  key: ValueKey(d.id),
                                                  constraints: const BoxConstraints(
                                                    maxWidth: 210,
                                                    maxHeight: 64,
                                                  ),
                                                  child: FittedBox(
                                                    fit: BoxFit.scaleDown,
                                                    child: Text(
                                                      d.text,
                                                      textAlign: TextAlign.center,
                                                      style: const TextStyle(
                                                        fontSize: 26,
                                                        height: 1.4,
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // أسهم تبديل الذكر حول النقاط (في العربية: الأيمن للسابق).
                          Row(
                            children: [
                              const SizedBox(width: 12),
                              _Arrow(right: true, onTap: () => _step(state, -1)),
                              Expanded(
                                child: _Dots(count: state.dhikrs.length, index: state.currentIndex),
                              ),
                              _Arrow(right: false, onTap: () => _step(state, 1)),
                              const SizedBox(width: 12),
                            ],
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            // الأصابع تأخذ مساحة مريحة تتناسب مع طول الشاشة.
                            height: (MediaQuery.sizeOf(context).height * 0.24).clamp(150.0, 215.0),
                            child: FingersRow(
                              controller: _fingers,
                              onSwipe: () => _count(fly: true),
                              onMorphed: _onMorphed,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned.fill(child: OrbitLayer(key: _orbit)),
        ],
      ),
    );
  }
}

/// الرأس (من التصميم الأصلي): العنوان، ثم بطاقة الاسم مع الكأس والمجموع.
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.today,
    required this.total,
    required this.onManage,
    required this.soundOn,
    required this.onSound,
    required this.onReset,
  });
  final int today;
  final int total;
  final VoidCallback onManage;
  final bool soundOn;
  final VoidCallback onSound;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    final name = context.watch<CloudService>().displayName;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      child: Column(
        children: [
          SizedBox(
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  tr(context, 'appName'),
                  style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w500),
                ),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: _RoundButton(
                    icon: Icons.format_list_bulleted,
                    tooltip: tr(context, 'manageDhikr'),
                    onPressed: onManage,
                  ),
                ),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _RoundButton(
                        icon: Icons.refresh,
                        tooltip: tr(context, 'resetCycle'),
                        onPressed: onReset,
                      ),
                      const SizedBox(width: 6),
                      _RoundButton(
                        icon: soundOn ? Icons.volume_up : Icons.volume_off,
                        tooltip: tr(context, 'sound'),
                        onPressed: onSound,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 8, 8),
            decoration: BoxDecoration(color: KanzColors.cardBlue, borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isEmpty ? tr(context, 'guest') : name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${tr(context, 'today')}: ${fmtNum(context, today)}',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: KanzColors.trophyBox,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.emoji_events, color: KanzColors.gold, size: 30),
                      const SizedBox(width: 6),
                      Text(
                        fmtNum(context, total),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// سهم تبديل الذكر بجانب السبحة.
class _Arrow extends StatelessWidget {
  const _Arrow({required this.right, required this.onTap});
  final bool right;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      // الاتجاه ثابت مهما كانت لغة الواجهة.
      icon: Directionality(
        textDirection: TextDirection.ltr,
        child: Icon(right ? Icons.chevron_right : Icons.chevron_left, color: Colors.white, size: 32),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});
  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    if (count > 15) return const SizedBox(height: 8);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 18 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active ? Colors.white : KanzColors.dotCyan.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.tooltip, required this.onPressed});
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      tooltip: tooltip,
      onPressed: onPressed,
      iconSize: 24,
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.16),
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.white.withValues(alpha: 0.06),
        disabledForegroundColor: Colors.white38,
        minimumSize: const Size(44, 44),
      ),
      icon: Icon(icon),
    );
  }
}

class _CelebrationDialog extends StatelessWidget {
  const _CelebrationDialog({required this.total});
  final int total;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: KanzColors.backgroundGradient,
          border: Border.all(color: KanzColors.cyan.withValues(alpha: 0.6)),
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 24)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 700),
              curve: Curves.elasticOut,
              builder: (_, v, child) => Transform.scale(scale: v, child: child),
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: KanzColors.mint, width: 8),
                ),
                alignment: Alignment.center,
                child: Text(
                  fmtNum(context, 100),
                  style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              tr(context, 'congrats'),
              style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w700),
            ),
            Text(
              '${tr(context, 'youGot')} ${fmtNum(context, 100)} ${tr(context, 'points')}',
              style: const TextStyle(color: KanzColors.cyan, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              tr(context, 'congratsBody', args: {'n': fmtNum(context, total)}),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 16),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: KanzColors.bgTop,
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(tr(context, 'continue')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
