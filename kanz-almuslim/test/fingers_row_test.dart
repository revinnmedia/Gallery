import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanz_almuslim/widgets/fingers_row.dart';

void main() {
  int visible(WidgetTester t) => find.byIcon(Icons.keyboard_arrow_up).evaluate().length;
  double rightmost(WidgetTester t) => find
      .byIcon(Icons.keyboard_arrow_up)
      .evaluate()
      .map((e) => t.getCenter(find.byWidget(e.widget)).dx)
      .reduce((a, b) => a > b ? a : b);

  testWidgets('fingers turn into dots one by one and return only after the last', (t) async {
    final c = FingersController();
    final morphed = <int>[];
    final sizes = <double>[];
    await t.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            height: 150,
            child: FingersRow(
              controller: c,
              onSwipe: () => 99,
              onMorphed: (center, size, payload) {
                sizes.add(size);
                morphed.add(payload);
              },
            ),
          ),
        ),
      ),
    ));
    expect(visible(t), 5);
    final right = rightmost(t);
    for (var n = 1; n <= 4; n++) {
      expect(c.launch(n), isTrue);
      await t.pumpAndSettle();
      expect(visible(t), 5 - n, reason: 'after $n taps');
      // الأصابع الباقية تزحلقت لليمين: دائماً يوجد إصبع في أقصى اليمين.
      expect(rightmost(t), closeTo(right, 0.5), reason: 'slide after $n taps');
    }
    expect(morphed, [1, 2, 3, 4]);
    c.launch(5);
    await t.pump(const Duration(milliseconds: 200));
    expect(c.canLaunch, isFalse);
    for (var k = 0; k < 20; k++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    await t.pumpAndSettle();
    expect(morphed, [1, 2, 3, 4, 5]);
    expect(visible(t), 5, reason: 'all fingers back');
    expect(c.canLaunch, isTrue);
    expect(sizes.every((s) => s > 0), isTrue);
  });
}
