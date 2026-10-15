import 'package:flutter_test/flutter_test.dart';
import 'package:kanz_almuslim/models.dart';
import 'package:kanz_almuslim/services/audio_service.dart';
import 'package:kanz_almuslim/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppState> freshState([Map<String, Object> values = const {}]) async {
  SharedPreferences.setMockInitialValues(values);
  return AppState(await SharedPreferences.getInstance());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  AudioService.enabled = false;

  test('starts with the 10 original adhkar', () async {
    final s = await freshState();
    expect(s.dhikrs.length, 10);
    expect(s.current.text, 'سبحان الله');
    expect(s.total, 0);
  });

  test('tap counts cycle, total and today history', () async {
    final s = await freshState({'soundOn': false});
    for (var i = 0; i < 5; i++) {
      s.tap();
    }
    expect(s.currentCycle, 5);
    expect(s.total, 5);
    expect(s.todayTotal, 5);
    expect(s.history[dayKey(DateTime.now())]![s.current.id], 5);
  });

  test('cycle completes every 33 and celebration every 100', () async {
    final s = await freshState({'soundOn': false, 'vibrationOn': false});
    final cycles = <int>[];
    final hundreds = <int>[];
    for (var i = 1; i <= 200; i++) {
      final r = s.tap();
      if (r.cycleDone) cycles.add(i);
      if (r.hundred) hundreds.add(i);
    }
    expect(cycles, [33, 66, 99, 132, 165, 198]);
    expect(hundreds, [100, 200]);
  });

  test('counts persist across restarts', () async {
    final s = await freshState({'soundOn': false});
    s.tap();
    s.tap();
    final prefs = await SharedPreferences.getInstance();
    final again = AppState(prefs);
    expect(again.total, 2);
    expect(again.currentCycle, 2);
  });

  test('add, edit, delete dhikr keeps selection valid', () async {
    final s = await freshState();
    s.addDhikr('  ذكر جديد ', 100);
    expect(s.dhikrs.last.text, 'ذكر جديد');
    expect(s.dhikrs.last.target, 100);

    s.selectDhikr(s.dhikrs.length - 1);
    expect(s.deleteDhikr(s.current), isTrue);
    expect(s.currentIndex, s.dhikrs.length - 1);

    while (s.dhikrs.length > 1) {
      s.deleteDhikr(s.dhikrs.first);
    }
    expect(s.deleteDhikr(s.dhikrs.first), isFalse, reason: 'last dhikr cannot be deleted');
  });

  test('reorder keeps the selected dhikr selected', () async {
    final s = await freshState();
    s.selectDhikr(2);
    final id = s.current.id;
    s.reorderDhikr(2, 0);
    expect(s.current.id, id);
    expect(s.currentIndex, 0);
  });

  test('display count goes 0..33 then back to 1 like the original', () async {
    final s = await freshState({'soundOn': false, 'vibrationOn': false});
    expect(s.displayCount, 0);
    for (var i = 0; i < 33; i++) {
      s.tap();
    }
    expect(s.displayCount, 33);
    s.tap();
    expect(s.displayCount, 1);
  });

  test('reminder settings: custom reminders only when enabled', () async {
    final s = await freshState();
    expect(s.anyReminderOn, isFalse);
    s.customReminders.add(CustomReminder(id: 'c', text: 'سبحان الله', sound: null, intervalMinutes: 60));
    expect(s.reminderSettings.streams, isEmpty, reason: 'custom switch is off');
    s.customReminderOn = true;
    expect(s.reminderSettings.streams.length, 1);
    s.autoReminder = true;
    expect(s.reminderSettings.streams.length, 2);
  });

  test('week starts on Saturday', () {
    // 2026-10-17 is a Saturday.
    expect(weekKey(DateTime(2026, 10, 17)), '2026-10-17');
    expect(weekKey(DateTime(2026, 10, 18)), '2026-10-17');
    expect(weekKey(DateTime(2026, 10, 23)), '2026-10-17');
    expect(weekKey(DateTime(2026, 10, 24)), '2026-10-24');
  });
}
