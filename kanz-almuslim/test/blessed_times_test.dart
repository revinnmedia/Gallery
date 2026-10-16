import 'package:flutter_test/flutter_test.dart';
import 'package:kanz_almuslim/services/blessed_times.dart';

void main() {
  // عمّان تقريباً.
  const lat = 31.95, lng = 35.93;

  test('morning reminder is between fajr and sunrise, evening between asr and maghrib', () {
    for (final date in [DateTime(2026, 1, 15), DateTime(2026, 6, 21), DateTime(2026, 10, 16)]) {
      final d = BlessedTimes.dayTimes(lat, lng, date);
      final (m, e) = BlessedTimes.remindersFor(d);
      expect(m.isAfter(d.fajr), isTrue, reason: '$date morning after fajr');
      expect(m.isBefore(d.sunrise), isTrue, reason: '$date morning before sunrise');
      expect(e.isAfter(d.asr), isTrue, reason: '$date evening after asr');
      expect(e.isBefore(d.maghrib), isTrue, reason: '$date evening before maghrib');
    }
  });

  test('upcoming gives two reminders a day, in order, all in the future', () {
    final now = DateTime(2026, 10, 16, 12);
    final list = BlessedTimes.upcoming(now: now, lat: lat, lng: lng, days: 3);
    // اليوم: المساء فقط (الصباح فات)، ثم ثلاثة أيام كاملة.
    expect(list.length, 1 + 3 * 2);
    expect(list.first.morning, isFalse);
    for (var i = 1; i < list.length; i++) {
      expect(list[i].when.isAfter(list[i - 1].when), isTrue);
      expect(list[i].morning, isNot(list[i - 1].morning));
    }
    expect(list.every((b) => b.when.isAfter(now)), isTrue);
  });

  test('approximate location from UTC offset', () {
    final (la, lo) = BlessedTimes.approximate(const Duration(hours: 3));
    expect(la, 25);
    expect(lo, 45);
  });
}
