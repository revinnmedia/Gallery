import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanz_almuslim/widgets/fingers_row.dart';

void main() {
  int hidden(WidgetTester t) =>
      t.widgetList<Opacity>(find.byType(Opacity)).where((o) => o.opacity == 0).length;

  testWidgets('fingers vanish one by one and return only after the last', (t) async {
    final c = FingersController();
    await t.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(height: 150, child: FingersRow(controller: c, onCount: () {})),
      ),
    ));
    for (var n = 1; n <= 4; n++) {
      c.launch();
      await t.pumpAndSettle();
      expect(hidden(t), n, reason: 'after $n taps');
    }
    c.launch();
    await t.pump(const Duration(milliseconds: 300));
    expect(hidden(t), 4, reason: 'last finger still flying');
    await t.pump(const Duration(milliseconds: 400));
    for (var k = 0; k < 20; k++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    await t.pumpAndSettle();
    expect(hidden(t), 0, reason: 'all fingers back');
  });
}
