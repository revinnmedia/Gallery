import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';

/// سجل التسبيح لآخر ٣٠ يوماً، مع تفصيل كل يوم.
class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selected = DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = List.generate(30, (i) => today.subtract(Duration(days: 29 - i)));
    final totals = days.map((d) => state.dayTotal(dayKey(d))).toList();
    final maxTotal = totals.fold<int>(1, (a, b) => b > a ? b : a);

    final week = days.where((d) => weekKey(d) == weekKey(now)).fold<int>(0, (a, d) => a + state.dayTotal(dayKey(d)));
    final month = state.history.entries
        .where((e) => e.key.startsWith(monthKey(now)))
        .fold<int>(0, (a, e) => a + e.value.values.fold<int>(0, (x, y) => x + y));

    final selectedKey = dayKey(_selected);
    final breakdown = (state.history[selectedKey] ?? {}).entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final locale = state.language == 'ar' ? 'ar' : 'en';

    return Scaffold(
      appBar: AppBar(title: Text(tr(context, 'tabRecords'))),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _SummaryTile(label: tr(context, 'today'), value: fmtNum(context, state.todayTotal)),
                const SizedBox(width: 8),
                _SummaryTile(label: tr(context, 'thisWeek'), value: fmtNum(context, week)),
                const SizedBox(width: 8),
                _SummaryTile(label: tr(context, 'thisMonth'), value: fmtNum(context, month)),
              ],
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(tr(context, 'last30'), style: Theme.of(context).textTheme.titleMedium),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 140,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(days.length, (i) {
                        final isSel = days[i] == _selected;
                        final h = totals[i] == 0 ? 3.0 : 8 + 120 * totals[i] / maxTotal;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selected = days[i]),
                            behavior: HitTestBehavior.opaque,
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                height: h,
                                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                                decoration: BoxDecoration(
                                  color: isSel
                                      ? KanzColors.mint
                                      : KanzColors.cyan.withValues(alpha: totals[i] == 0 ? 0.15 : 0.5),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Row(
              children: [
                Text(
                  DateFormat.yMMMMEEEEd(locale).format(_selected),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Text(
                  fmtNum(context, state.dayTotal(selectedKey)),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: KanzColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          if (breakdown.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(child: Text(tr(context, 'noRecords'))),
            )
          else
            ...breakdown.map(
              (e) => Card(
                child: ListTile(
                  title: Text(
                    state.dhikrText(e.key),
                    style: const TextStyle(fontSize: 18, height: 1.6),
                  ),
                  trailing: Text(
                    '${fmtNum(context, e.value)} ${tr(context, 'times')}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: KanzColors.cardStrong,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: KanzColors.cyan.withValues(alpha: 0.35)),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
            const SizedBox(height: 4),
            FittedBox(
              child: Text(value,
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
