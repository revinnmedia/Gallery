/// تسبيحة يعدّها المستخدم.
class Dhikr {
  Dhikr({
    required this.id,
    required this.text,
    this.sound,
    this.target = 33,
    this.builtIn = false,
  });

  final String id;
  String text;

  /// اسم ملف الصوت بدون الامتداد (داخل assets/sounds)، أو null بدون صوت.
  String? sound;

  /// عدد حبات الدورة (الافتراضي ٣٣ مثل السبحة).
  int target;
  final bool builtIn;

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'sound': sound,
        'target': target,
        'builtIn': builtIn,
      };

  factory Dhikr.fromJson(Map<String, dynamic> j) => Dhikr(
        id: j['id'] as String,
        text: j['text'] as String,
        sound: j['sound'] as String?,
        target: (j['target'] as num?)?.toInt() ?? 33,
        builtIn: j['builtIn'] as bool? ?? false,
      );
}

/// عبارة تذكير تظهر في التنبيهات.
class ReminderPhrase {
  const ReminderPhrase(this.text, this.sound);
  final String text;
  final String? sound;
}

/// تذكير مخصص: ذكر معيّن يتكرر كل عدد من الدقائق (كما في النسخة الأصلية).
class CustomReminder {
  CustomReminder({
    required this.id,
    required this.text,
    required this.sound,
    required this.intervalMinutes,
    this.enabled = true,
  });

  final String id;
  String text;
  String? sound;
  int intervalMinutes;
  bool enabled;

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'sound': sound,
        'interval': intervalMinutes,
        'enabled': enabled,
      };

  factory CustomReminder.fromJson(Map<String, dynamic> j) => CustomReminder(
        id: j['id'] as String,
        text: j['text'] as String,
        sound: j['sound'] as String?,
        intervalMinutes: (j['interval'] as num).toInt(),
        enabled: j['enabled'] as bool? ?? true,
      );
}

/// مستخدم في لوحة الترتيب.
class RankEntry {
  const RankEntry({
    required this.uid,
    required this.name,
    required this.score,
    this.photoUrl,
  });

  final String uid;
  final String name;
  final int score;
  final String? photoUrl;
}

/// مفتاح اليوم بصيغة yyyy-MM-dd بالتوقيت المحلي.
String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// مفتاح الأسبوع: تاريخ يوم السبت الذي يبدأ فيه الأسبوع.
String weekKey(DateTime d) {
  final day = DateTime(d.year, d.month, d.day);
  // DateTime.saturday = 6. نرجع للخلف حتى نصل ليوم السبت.
  final back = (day.weekday - DateTime.saturday) % 7;
  return dayKey(day.subtract(Duration(days: back)));
}

String monthKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';
