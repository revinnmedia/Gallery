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

    // السحب للأسفل لا يُحسب.
    await t.dragFrom(const Offset(196, 400), const Offset(0, 120));
    await t.pumpAndSettle();
    expect(s.total, 2, reason: 'swipe down ignored');
  });
}
