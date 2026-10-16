import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanz_almuslim/app.dart';
import 'package:kanz_almuslim/services/audio_service.dart';
import 'package:kanz_almuslim/services/cloud_service.dart';
import 'package:kanz_almuslim/state/app_state.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('tap anywhere and swipe up anywhere both count', (t) async {
    AudioService.enabled = false;
    SharedPreferences.setMockInitialValues({'soundOn': false, 'vibrationOn': false});
    final s = AppState(await SharedPreferences.getInstance());
    t.view.physicalSize = const Size(1179, 2556);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: s),
        ChangeNotifierProvider.value(value: CloudService.instance),
      ],
      child: const KanzApp(),
    ));
    await t.pumpAndSettle();

    await t.tapAt(const Offset(196, 450));
    await t.pumpAndSettle();
    expect(s.total, 1, reason: 'tap');

    // سحب للأعلى على السبحة.
    await t.dragFrom(const Offset(196, 520), const Offset(0, -120));
    await t.pumpAndSettle();
    expect(s.total, 2, reason: 'swipe up');

    // سحب بطيء: الإصبع يتبع اللمس، ثم ينطلق عند الإفلات بعد مسافة كافية.
    double fingerTop() => find
        .byIcon(Icons.keyboard_arrow_up)
        .evaluate()
        .map((e) => t.getCenter(find.byWidget(e.widget)).dy)
        .reduce((a, b) => a < b ? a : b);
    final before = fingerTop();
    final g = await t.startGesture(const Offset(300, 500));
    for (var k = 0; k < 10; k++) {
      await g.moveBy(const Offset(0, -8));
      await t.pump(const Duration(milliseconds: 40));
    }
    expect(fingerTop(), lessThan(before - 40), reason: 'finger follows the touch');
    await t.pump(const Duration(milliseconds: 300));
    await g.up();
    await t.pumpAndSettle();
    expect(s.total, 3, reason: 'released after enough distance');

    // سحب قصير وبطيء: لا يُحسب والإصبع يعود.
    final g2 = await t.startGesture(const Offset(300, 500));
    for (var k = 0; k < 3; k++) {
      await g2.moveBy(const Offset(0, -10));
      await t.pump(const Duration(milliseconds: 60));
    }
    await t.pump(const Duration(milliseconds: 300));
    await g2.up();
    await t.pumpAndSettle();
    expect(s.total, 3, reason: 'short drag snaps back');

    // السحب للأسفل لا يُحسب.
    await t.dragFrom(const Offset(196, 400), const Offset(0, 120));
    await t.pumpAndSettle();
    expect(s.total, 3, reason: 'swipe down ignored');
  });
}
