import '../models.dart';

/// التسابيح الافتراضية من النسخة الأصلية، بنفس ملفات الصوت.
/// أسماء الأصوات ومصادرها الأصلية في tool/sounds.json.
List<Dhikr> defaultDhikrList() => [
  Dhikr(id: 'd1', text: 'سبحان الله', sound: 'subhanallah', builtIn: true),
  Dhikr(id: 'd2', text: 'الحمد لله', sound: 'alhamdulillah', builtIn: true),
  Dhikr(
    id: 'd3',
    text: 'لا إله إلا الله',
    sound: 'la_ilaha_illallah',
    builtIn: true,
  ),
  Dhikr(id: 'd4', text: 'الله أكبر', sound: 'allahu_akbar', builtIn: true),
  Dhikr(
    id: 'd5',
    text: 'سبحان الله وبحمده',
    sound: 'subhanallah_wabihamdihi',
    builtIn: true,
  ),
  Dhikr(
    id: 'd6',
    text: 'سبحان الله العظيم',
    sound: 'subhanallah_alazim',
    builtIn: true,
  ),
  Dhikr(id: 'd7', text: 'أستغفر الله', sound: 'astaghfirullah', builtIn: true),
  Dhikr(
    id: 'd8',
    text: 'لا حول ولا قوة إلا بالله',
    sound: 'la_hawla',
    builtIn: true,
  ),
  Dhikr(
    id: 'd9',
    text: 'حسبي الله ونعم الوكيل',
    sound: 'hasbiyallah',
    builtIn: true,
  ),
  Dhikr(
    id: 'd10',
    text: 'عليه الصلاة والسلام',
    sound: 'alayhi_assalat',
    builtIn: true,
  ),
];

/// عبارات التذكير العشوائي من النسخة الأصلية.
const reminderPhrases = <ReminderPhrase>[
  ReminderPhrase('أستغفر الله', 'astaghfirullah'),
  ReminderPhrase('اذكر الله', 'udhkurillah'),
  ReminderPhrase('سبّح اسم ربك الأعلى', 'sabbih_isma_rabbik'),
  ReminderPhrase('سبّح باسم ربك العظيم', 'sabbih_bismi_rabbik'),
  ReminderPhrase('سبّح بحمد ربك واستغفره', 'sabbih_bihamdi_rabbik'),
  ReminderPhrase('اذكر الله يذكرك', 'udhkurillah_yadhkurk'),
  ReminderPhrase('اشكر الله يشكرك', 'ushkurillah_yashkurk'),
  ReminderPhrase('احمد الله', 'ihmadillah'),
  ReminderPhrase('اشكر الله', 'ushkurillah'),
  ReminderPhrase('سبّح الله', 'sabbihillah'),
  ReminderPhrase('لا تنسَ ذكر الله', 'la_tansa'),
  ReminderPhrase('إستغفر الله', 'astaghfirullah_2'),
  ReminderPhrase('سبحان الله', 'subhanallah'),
  ReminderPhrase('الله أكبر', 'allahu_akbar'),
  ReminderPhrase('لا إله إلا الله', 'la_ilaha_illallah'),
  // عبارات التذكير الصوتي من ملف التصميم الأصلي
  ReminderPhrase('تكبير', 'takbir'),
  ReminderPhrase('تسبيح', 'tasbih'),
  ReminderPhrase('استغفار', 'istighfar'),
  ReminderPhrase('توحيد', 'tawhid'),
  ReminderPhrase('صلِّ على محمد', 'salli_ala_muhammad'),
];

/// صوت التهنئة عند كل ١٠٠ تسبيحة ("ممتاز" في النسخة الأصلية).
const celebrationSound = 'mumtaz';

/// نصوص تنبيهات أوقات التسبيح المباركة (طه: ١٣٠).
const blessedMorningText = {
  'ar': '﴿وَسَبِّحْ بِحَمْدِ رَبِّكَ قَبْلَ طُلُوعِ الشَّمْسِ﴾\nحان وقت التسبيح قبل الشروق',
  'en': '"And glorify the praise of your Lord before the rising of the sun"\nTime to glorify Allah before sunrise',
};
const blessedEveningText = {
  'ar': '﴿وَسَبِّحْ بِحَمْدِ رَبِّكَ ... وَقَبْلَ غُرُوبِهَا﴾\nحان وقت التسبيح قبل الغروب',
  'en': '"...and before its setting"\nTime to glorify Allah before sunset',
};
