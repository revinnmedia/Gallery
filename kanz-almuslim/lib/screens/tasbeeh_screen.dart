import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/counter_ring.dart';
import '../widgets/pattern_background.dart';
import 'manage_dhikr_screen.dart';

class TasbeehScreen extends StatefulWidget {
  const TasbeehScreen({super.key});

  @override
  State<TasbeehScreen> createState() => _TasbeehScreenState();
}

class _TasbeehScreenState extends State<TasbeehScreen> with SingleTickerProviderStateMixin {
  late final PageController _pages;
  late final AnimationController _pulse;
  bool _celebrating = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    _pages = PageController(initialPage: state.currentIndex);
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 140));
  }

  @override
  void dispose() {
    _pages.dispose();
    _pulse.dispose();
    super.dispose();
  }

  void _onTap() {
    if (_celebrating) return;
    final result = context.read<AppState>().tap();
    _pulse.forward(from: 0);
    if (result.hundred) _celebrate();
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
    final cycle = state.displayCount;
    final progress = d.target > 0 ? cycle / d.target : 0.0;

    // نحافظ على تزامن الصفحة إذا تغيّر الذكر من شاشة الإدارة.
    if (_pages.hasClients && _pages.page?.round() != state.currentIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pages.hasClients) _pages.jumpToPage(state.currentIndex);
      });
    }

    return PatternBackground(
      child: SafeArea(
        child: Column(
          children: [
            _TopBar(
              today: state.todayTotal,
              total: state.total,
              onManage: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ManageDhikrScreen()),
              ),
            ),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _onTap,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 110,
                      child: PageView.builder(
                        controller: _pages,
                        itemCount: state.dhikrs.length,
                        onPageChanged: state.selectDhikr,
                        itemBuilder: (_, i) => Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                state.dhikrs[i].text,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 40,
                                  height: 1.6,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    _Dots(count: state.dhikrs.length, index: state.currentIndex),
                    const SizedBox(height: 28),
                    ScaleTransition(
                      scale: Tween(begin: 1.0, end: 0.96).animate(
                        CurvedAnimation(parent: _pulse, curve: Curves.easeOut, reverseCurve: Curves.easeIn),
                      ),
                      child: CounterRing(
                        progress: progress,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              fmtNum(context, cycle),
                              style: const TextStyle(
                                fontSize: 76,
                                fontWeight: FontWeight.w300,
                                color: Colors.white,
                                height: 1.1,
                              ),
                            ),
                            Text(
                              '/ ${fmtNum(context, d.target)}',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white.withValues(alpha: 0.75),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      tr(context, 'tapToCount'),
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tr(context, 'swipeToChange'),
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            _BottomControls(
              soundOn: state.soundOn,
              onSound: () => state.setSound(!state.soundOn),
              onReset: state.currentCycle == 0 ? null : state.resetCycle,
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.today, required this.total, required this.onManage});
  final int today;
  final int total;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
      child: Row(
        children: [
          _Stat(label: tr(context, 'today'), value: fmtNum(context, today)),
          const SizedBox(width: 12),
          _Stat(label: tr(context, 'total'), value: fmtNum(context, total)),
          const Spacer(),
          IconButton(
            tooltip: tr(context, 'manageDhikr'),
            onPressed: onManage,
            icon: const Icon(Icons.format_list_bulleted, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
          Text(value,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
        ],
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

class _BottomControls extends StatelessWidget {
  const _BottomControls({required this.soundOn, required this.onSound, required this.onReset});
  final bool soundOn;
  final VoidCallback onSound;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _RoundButton(
            icon: soundOn ? Icons.volume_up : Icons.volume_off,
            tooltip: tr(context, 'sound'),
            onPressed: onSound,
          ),
          _RoundButton(
            icon: Icons.refresh,
            tooltip: tr(context, 'resetCycle'),
            onPressed: onReset,
          ),
        ],
      ),
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
        minimumSize: const Size(52, 52),
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
