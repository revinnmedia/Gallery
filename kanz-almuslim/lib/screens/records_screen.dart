import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n.dart';
import '../state/app_state.dart';
import '../widgets/kanz_ui.dart';
import 'support_screen.dart';

/// السجل: جدول التاريخ / الذكر / العدد كما في النسخة الأصلية،
/// مرتب من الأحدث للأقدم.
class RecordsScreen extends StatelessWidget {
  const RecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final rows = <(String, String, int)>[];
    final days = s.history.keys.toList()..sort((a, b) => b.compareTo(a));
    for (final day in days) {
      final entries = s.history[day]!.entries.where((e) => e.value > 0).toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      for (final e in entries) {
        rows.add((day, s.dhikrText(e.key), e.value));
      }
    }

    const style = TextStyle(
      fontSize: 19,
      fontWeight: FontWeight.w300,
      color: Colors.white,
    );
    return KanzPage(
      title: tr(context, 'tabRecords'),
      onHeart: () =>
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const SupportScreen())),
      body: Column(
        children: [
          KanzTableHeader(
            cells: [
              tr(context, 'date'),
              tr(context, 'dhikr'),
              tr(context, 'count'),
            ],
          ),
          Expanded(
            child: rows.isEmpty
                ? Center(child: Text(tr(context, 'noRecords'), style: style))
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 16),
                    itemCount: rows.length,
                    itemBuilder: (_, i) {
                      final (day, text, count) = rows[i];
                      return SizedBox(
                        height: 46,
                        child: Row(
                          children: [
                            Expanded(
                              child: Center(child: Text(day, style: style)),
                            ),
                            Expanded(
                              child: Center(
                                child: Text(
                                  text,
                                  style: style,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Center(
                                child: Text('$count', style: style),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
