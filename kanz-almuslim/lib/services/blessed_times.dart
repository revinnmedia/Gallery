import 'package:adhan/adhan.dart';

/// أوقات التسبيح المباركة كما في قوله تعالى:
/// ﴿وَسَبِّحْ بِحَمْدِ رَبِّكَ قَبْلَ طُلُوعِ الشَّمْسِ وَقَبْلَ غُرُوبِهَا﴾ [طه: ١٣٠]
///
/// - قبل طلوع الشمس: بين الفجر والشروق.
/// - قبل الغروب: بين العصر والمغرب.
///
/// تُحسب أوقات الصلاة على الجهاز نفسه (بدون إنترنت) من إحداثيات المستخدم.
class BlessedTime {
  const BlessedTime(this.when, {required this.morning});
  final DateTime when;

  /// true = قبل الشروق، false = قبل الغروب.
  final bool morning;
}

class DayTimes {
  const DayTimes({required this.fajr, required this.sunrise, required this.asr, required this.maghrib});
  final DateTime fajr;
  final DateTime sunrise;
  final DateTime asr;
  final DateTime maghrib;
}

class BlessedTimes {
  /// التذكير الصباحي: قبل الشروق بـ٤٠ دقيقة (ولا يسبق الفجر بأقل من ١٠ دقائق بعده).
  static const morningBeforeSunrise = Duration(minutes: 40);

  /// التذكير المسائي: قبل المغرب بـ٤٥ دقيقة (وبعد العصر بـ١٠ دقائق على الأقل).
  static const eveningBeforeSunset = Duration(minutes: 45);
  static const _afterPrayer = Duration(minutes: 10);

  static DayTimes dayTimes(double lat, double lng, DateTime date) {
    final params = CalculationMethod.muslim_world_league.getParameters()..madhab = Madhab.shafi;
    final t = PrayerTimes(Coordinates(lat, lng), DateComponents.from(date), params);
    return DayTimes(fajr: t.fajr, sunrise: t.sunrise, asr: t.asr, maghrib: t.maghrib);
  }

  static DateTime _later(DateTime a, DateTime b) => a.isAfter(b) ? a : b;

  static (DateTime morning, DateTime evening) remindersFor(DayTimes d) => (
    _later(d.sunrise.subtract(morningBeforeSunrise), d.fajr.add(_afterPrayer)),
    _later(d.maghrib.subtract(eveningBeforeSunset), d.asr.add(_afterPrayer)),
  );

  /// المواعيد القادمة بعد [now] لعدد [days] يوماً، مرتبة تصاعدياً.
  static List<BlessedTime> upcoming({
    required DateTime now,
    required double lat,
    required double lng,
    int days = 10,
  }) {
    final out = <BlessedTime>[];
    final start = DateTime(now.year, now.month, now.day);
    for (var i = 0; i <= days; i++) {
      final date = start.add(Duration(days: i));
      final (m, e) = remindersFor(dayTimes(lat, lng, date));
      if (m.isAfter(now)) out.add(BlessedTime(m, morning: true));
      if (e.isAfter(now)) out.add(BlessedTime(e, morning: false));
    }
    out.sort((a, b) => a.when.compareTo(b.when));
    return out;
  }

  /// موقع تقريبي من فرق التوقيت فقط (إذا لم يسمح المستخدم بالموقع):
  /// خط الطول ≈ ١٥° لكل ساعة، وخط العرض ٢٥° (وسط المنطقة العربية تقريباً).
  static (double lat, double lng) approximate(Duration utcOffset) => (25.0, utcOffset.inMinutes / 60 * 15);
}
