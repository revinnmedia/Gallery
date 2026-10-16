// يولّد صور للشاشات لمراجعة التصميم:
// flutter test test/screenshots --update-goldens
@Tags(['screenshots'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanz_almuslim/app.dart';
import 'package:kanz_almuslim/models.dart';
import 'package:kanz_almuslim/services/audio_service.dart';
import 'package:kanz_almuslim/services/cloud_service.dart';
import 'package:kanz_almuslim/state/app_state.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final p in paths) {
    loader.addFont(Future.value(ByteData.sublistView(File(p).readAsBytesSync())));
  }
  await loader.load();
}

Future<AppState> _state({String lang = 'ar'}) async {
  SharedPreferences.setMockInitialValues({
    'soundOn': false,
    'language': lang,
    'total': 3934,
    'cycles': '{"d1": 21}',
    'autoReminder': true,
    'autoInterval': 5,
    'customReminderOn': true,
    'customReminders':
        '[{"id":"c1","text":"أستغفر الله","interval":60,"enabled":true},{"id":"c2","text":"سبحان الله وبحمده","interval":120,"enabled":true}]',
  });
  final s = AppState(await SharedPreferences.getInstance());
  // سجل تجريبي لآخر ٣٠ يوماً.
  final now = DateTime.now();
  for (var i = 0; i < 30; i++) {
    final d = now.subtract(Duration(days: i));
    if (i % 7 == 5) continue;
    s.history[dayKey(d)] = {
      'd1': 33 + (i * 17) % 90,
      'd7': 100 - (i * 13) % 70,
      if (i % 2 == 0) 'd5': 33,
    };
  }
  return s;
}

/// مقاس صور App Store لشاشة 6.9 إنش (يمكن تغييره بـ --dart-define=STORE=true).
const _store = bool.fromEnvironment('STORE');

Future<void> _pump(WidgetTester t, AppState s) async {
  t.view.physicalSize = _store ? const Size(1290, 2796) : const Size(1179, 2556);
  t.view.devicePixelRatio = 3;
  await t.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: s),
      ChangeNotifierProvider.value(value: CloudService.instance),
    ],
    child: const KanzApp(),
  ));
  await t.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    AudioService.enabled = false;
    await _loadFont('Tajawal', [
      'assets/fonts/Tajawal-ExtraLight.ttf',
      'assets/fonts/Tajawal-Light.ttf',
      'assets/fonts/Tajawal-Regular.ttf',
      'assets/fonts/Tajawal-Medium.ttf',
      'assets/fonts/Tajawal-Bold.ttf',
    ]);
    final flutterRoot = Platform.environment['FLUTTER_ROOT'] ?? '/opt/flutter';
    await _loadFont('MaterialIcons', ['$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf']);
  });

  Future<void> shot(WidgetTester t, String name) =>
      expectLater(find.byType(MaterialApp), matchesGoldenFile(_store ? 'store/$name.png' : 'out/$name.png'));

  testWidgets('01 tasbeeh', (t) async {
    await _pump(t, await _state());
    await shot(t, '01_tasbeeh');
  });

  testWidgets('02 records', (t) async {
    await _pump(t, await _state());
    await t.tap(find.text('السجل'));
    await t.pumpAndSettle();
    await shot(t, '02_records');
  });

  testWidgets('03 ranking', (t) async {
    await _pump(t, await _state());
    await t.tap(find.text('الترتيب'));
    await t.pumpAndSettle();
    await shot(t, '03_ranking');
  });

  testWidgets('04 settings', (t) async {
    await _pump(t, await _state());
    await t.tap(find.text('الإعدادات'));
    await t.pumpAndSettle();
    await shot(t, '04_settings');
  });

  testWidgets('05 reminders', (t) async {
    await _pump(t, await _state());
    await t.tap(find.text('الإعدادات'));
    await t.pumpAndSettle();
    await t.tap(find.text('التذكير'));
    await t.pumpAndSettle();
    await shot(t, '05_reminders');
  });

  testWidgets('06 celebration', (t) async {
    final s = await _state();
    s.total = 3999;
    await _pump(t, s);
    await t.tapAt(const Offset(196, 450));
    await t.pumpAndSettle();
    await shot(t, '06_celebration');
  });

  testWidgets('07 manage', (t) async {
    await _pump(t, await _state());
    await t.tap(find.byIcon(Icons.format_list_bulleted).first);
    await t.pumpAndSettle();
    await shot(t, '07_manage');
  });

  // لقطات من حركة الإصبع (للمراجعة فقط، لا تُحفظ في git).
  testWidgets('08 motion frames', (t) async {
    if (_store) return;
    await _pump(t, await _state());
    await t.tapAt(const Offset(196, 450));
    var ms = 0;
    for (final at in [120, 260, 420, 650, 900, 1150, 1500]) {
      await t.pump(Duration(milliseconds: at - ms));
      ms = at;
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('motion/m_${at.toString().padLeft(4, '0')}.png'));
    }
    await t.pumpAndSettle();
  });
}
