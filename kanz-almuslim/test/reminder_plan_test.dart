import 'package:flutter_test/flutter_test.dart';
import 'package:kanz_almuslim/services/notification_service.dart';

void main() {
  final now = DateTime(2026, 10, 15, 7, 0);

  List<PlannedReminder> plan(List<ReminderStream> streams,
          {bool dnd = false, int from = 22, int to = 6, int max = 60}) =>
      NotificationService.buildPlan(
        now: now,
        streams: streams,
        dnd: dnd,
        dndStartHour: from,
        dndEndHour: to,
        max: max,
      );

  test('auto reminder: one per interval, never duplicated', () {
    final p = plan([const ReminderStream(intervalMinutes: 60)]);
    expect(p.length, 60);
    expect(p.map((e) => e.when).toSet().length, p.length, reason: 'no duplicates');
    for (var i = 1; i < p.length; i++) {
      expect(p[i].when.difference(p[i - 1].when).inMinutes, 60);
    }
    expect(p.first.when, DateTime(2026, 10, 15, 8, 0));
  });

  test('auto + custom reminders never fire in the same minute', () {
    // 30 و 60 يلتقيان كل ساعة: يجب أن يبقى تنبيه واحد فقط.
    final p = plan([
      const ReminderStream(intervalMinutes: 30),
      const ReminderStream(intervalMinutes: 60, text: 'سبحان الله'),
    ]);
    final minutes = p.map((e) => e.when.millisecondsSinceEpoch ~/ 60000).toList();
    expect(minutes.toSet().length, minutes.length);
    for (var i = 1; i < p.length; i++) {
      expect(p[i].when.isAfter(p[i - 1].when), isTrue, reason: 'sorted');
    }
  });

  test('do-not-disturb hours are respected (22 to 6)', () {
    final p = plan([const ReminderStream(intervalMinutes: 30)], dnd: true);
    expect(p, isNotEmpty);
    for (final e in p) {
      expect(e.when.hour >= 6 && e.when.hour < 22, isTrue, reason: '${e.when} in quiet hours');
    }
  });

  test('never exceeds the limit; too-short intervals are ignored', () {
    expect(plan([const ReminderStream(intervalMinutes: 5)]).length, 60);
    expect(plan([const ReminderStream(intervalMinutes: 5)], max: 200).length, 200);
    expect(plan([const ReminderStream(intervalMinutes: 0)]), isEmpty);
    expect(plan([const ReminderStream(intervalMinutes: 4)]), isEmpty);
  });

  test('every enabled custom reminder gets slots', () {
    final p = plan([
      const ReminderStream(intervalMinutes: 60, text: 'أ'),
      const ReminderStream(intervalMinutes: 90, text: 'ب'),
    ]);
    expect(p.any((e) => e.stream == 0), isTrue);
    expect(p.any((e) => e.stream == 1), isTrue);
  });
}
