import '../models.dart';

/// التسابيح الافتراضية من النسخة الأصلية، بنفس ملفات الصوت.
/// أسماء الملفات مسبوقة بـ s_ لأن موارد أندرويد لازم تبدأ بحرف.
List<Dhikr> defaultDhikrList() => [
      Dhikr(id: 'd1', text: 'سبحان الله', sound: 's_dc8e65c1aa7adf4800850cc88d321d29', builtIn: true),
      Dhikr(id: 'd2', text: 'الحمد لله', sound: 's_a514f21cec73b0f59eeea4aa7eb8cc7b', builtIn: true),
      Dhikr(id: 'd3', text: 'لا إله إلا الله', sound: 's_fbe20b12befc750574107dbdf0b2a842', builtIn: true),
      Dhikr(id: 'd4', text: 'الله أكبر', sound: 's_bc37a089f2957a7263813763cd92ee97', builtIn: true),
      Dhikr(id: 'd5', text: 'سبحان الله وبحمده', sound: 's_10242503b5e69a8ee8722ae03302a8b6', builtIn: true),
      Dhikr(id: 'd6', text: 'سبحان الله العظيم', sound: 's_934de45b475ef3f6ddcef32824e7d9f3', builtIn: true),
      Dhikr(id: 'd7', text: 'أستغفر الله', sound: 's_9cd65c9aa34db7eaa79548b0b2ef7ad6', builtIn: true),
      Dhikr(id: 'd8', text: 'لا حول ولا قوة إلا بالله', sound: 's_5a955d02e06e8d77e8908b8796ba7249', builtIn: true),
      Dhikr(id: 'd9', text: 'حسبي الله ونعم الوكيل', sound: 's_72aff2d97a5a31efae217063f25c36f1', builtIn: true),
      Dhikr(id: 'd10', text: 'اللهم صلِّ على محمد', sound: 's_e9e3fbe06d073c68b1a30099572db0fb', builtIn: true),
    ];

/// عبارات التذكير العشوائي من النسخة الأصلية.
const reminderPhrases = <ReminderPhrase>[
  ReminderPhrase('أستغفر الله', 's_9cd65c9aa34db7eaa79548b0b2ef7ad6'),
  ReminderPhrase('اذكر الله', 's_fc0658b29c65a861c22d6f8a15e8bfc7'),
  ReminderPhrase('سبّح اسم ربك الأعلى', 's_c9463e91930b2d7da2dbafec5759a468'),
  ReminderPhrase('سبّح باسم ربك العظيم', 's_a706e883c0185476f183f84bef4fb34a'),
  ReminderPhrase('سبّح بحمد ربك واستغفره', 's_afd368b3c6986b6368648728718a1328'),
  ReminderPhrase('اذكر الله يذكرك', 's_63fc85ccc226e131ec5267d569f39d95'),
  ReminderPhrase('اشكر الله يشكرك', 's_dd5aaa60508850008934f03ee43d09c5'),
  ReminderPhrase('احمد الله', 's_33dd95e231cc408c8f3225fe205da8d7'),
  ReminderPhrase('اشكر الله', 's_bcabebc3c3ea6e0a788d69f58d4bcc31'),
  ReminderPhrase('سبّح الله', 's_1fb6d9da15d87d439cfbd732f359346f'),
  ReminderPhrase('لا تنسَ ذكر الله', 's_026599eb4b65b6369502b4771bb2fbd4'),
  ReminderPhrase('أستغفر الله وأتوب إليه', 's_5da6c1e00997aacce10b6269ea499a50'),
  ReminderPhrase('سبحان الله', 's_dc8e65c1aa7adf4800850cc88d321d29'),
  ReminderPhrase('الله أكبر', 's_cd50f7b4f17069965faaf1233c266695'),
  ReminderPhrase('لا إله إلا الله', 's_fbe20b12befc750574107dbdf0b2a842'),
];

/// صوت التهنئة عند كل ١٠٠ تسبيحة ("ممتاز" في النسخة الأصلية).
const celebrationSound = 's_06cbf01c51cc8a284ef9ec0348e26abe';
