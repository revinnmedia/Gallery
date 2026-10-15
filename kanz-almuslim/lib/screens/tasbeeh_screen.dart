import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n.dart';
import '../services/cloud_service.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/bead_ring.dart';
import '../widgets/kanz_ui.dart';
import '../widgets/swipe_pillars.dart';
import 'ranking_screen.dart';
import 'sign_in_sheet.dart';
import 'support_screen.dart';

/// شاشة السبحة الرئيسية بنفس تصميم النسخة الأصلية.
class TasbeehScreen extends StatefulWidget {
  const TasbeehScreen({super.key});

  @override
  State<TasbeehScreen> createState() => _TasbeehScreenState();
}

class _TasbeehScreenState extends State<TasbeehScreen> {
  bool _celebrating = false;

  void _count() {
    final result = context.read<AppState>().tap();
    if (result.hundred && !_celebrating) _celebrate();
  }

  Future<void> _celebrate() async {
    _celebrating = true;
    final total = context.read<AppState>().total;
    await showDialog<void>(context: context, builder: (_) => _HundredDialog(total: total));
    _celebrating = false;
  }

  void _step(int delta) {
    final s = context.read<AppState>();
    final n = s.dhikrs.length;
    s.selectDhikr((s.currentIndex + delta + n) % n);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final d = s.current;
    final lit = d.target == 33 || d.target <= 0
        ? s.displayCount
        : (s.displayCount * 33 / d.target).round();

    return KanzPage(
      title: tr(context, 'appName'),
      onHeart: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SupportScreen())),
      body: Column(
        children: [
          const _UserCard(),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _count,
              onHorizontalDragEnd: (e) {
                final v = e.primaryVelocity ?? 0;
                if (v.abs() > 200) _step(v < 0 ? 1 : -1);
              },
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  children: [
                    _Arrow(icon: Icons.arrow_back_ios_new, onTap: () => _step(-1)),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: BeadRing(
                          lit: lit,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${s.displayCount}',
                                style: const TextStyle(
                                  fontSize: 64,
                                  fontWeight: FontWeight.w200,
                                  color: Colors.white,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 40),
                                child: Text(
                                  d.text,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w300,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    _Arrow(icon: Icons.arrow_forward_ios, onTap: () => _step(1)),
                  ],
                ),
              ),
            ),
          ),
          _Dots(count: s.dhikrs.length, index: s.currentIndex),
          const SizedBox(height: 18),
          SizedBox(height: 180, child: SwipePillars(onCount: _count)),
        ],
      ),
    );
  }
}

/// بطاقة المستخدم: الاسم والعضوية على اليمين، والكأس مع النقاط على اليسار.
class _UserCard extends StatelessWidget {
  const _UserCard();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final cloud = context.watch<CloudService>();
    final name = cloud.signedIn ? cloud.displayName : tr(context, 'guest');
    final sub = s.premium ? tr(context, 'premiumMember') : tr(context, 'normalMember');
    return GestureDetector(
      onTap: () {
        if (!cloud.available) return;
        if (cloud.signedIn) {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RankingScreen()));
        } else {
          showSignInSheet(context);
        }
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
        height: 56,
        decoration: BoxDecoration(color: KanzColors.cardBlue, borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 70),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w300, color: Colors.white)),
                    Text(sub, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w300, color: Colors.white)),
                  ],
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.all(4),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              height: 36,
              color: KanzColors.trophyBox,
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.emoji_events, color: KanzColors.gold, size: 30),
                    Text('${s.total}',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w300, color: Colors.white)),
                    const SizedBox(width: 6),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => IconButton(
        onPressed: onTap,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 60),
        icon: Icon(icon, color: Colors.white, size: 30),
      );
}

/// نقاط الصفحات: الحالية بيضاء والباقي فيروزي.
class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});
  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Wrap(
        alignment: WrapAlignment.center,
        children: List.generate(count, (i) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4.5),
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i == index ? Colors.white : KanzColors.dotCyan,
            ),
          );
        }),
      ),
    );
  }
}

class _HundredDialog extends StatelessWidget {
  const _HundredDialog({required this.total});
  final int total;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: KanzColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: KanzColors.cyan),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOut,
              builder: (_, v, _) => SizedBox.square(
                dimension: 130,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: v,
                        strokeWidth: 8,
                        color: const Color(0xFF00D79C),
                        backgroundColor: Colors.white12,
                      ),
                    ),
                    const Text('100', style: TextStyle(fontSize: 44, fontWeight: FontWeight.w200, color: Colors.white)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(tr(context, 'congrats'), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w300, color: Colors.white)),
            const SizedBox(height: 6),
            Text(tr(context, 'congratsBody', args: {'n': '$total'}),
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w300, color: Colors.white)),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Icon(Icons.close, color: Colors.white, size: 32),
            ),
          ],
        ),
      ),
    );
  }
}
