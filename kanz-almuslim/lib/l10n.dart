import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'state/app_state.dart';

/// نصوص الواجهة. النصوص العربية مطابقة للنسخة الأصلية قدر الإمكان.
const _strings = <String, Map<String, String>>{
  'appName': {'ar': 'كنز المسلم', 'en': 'Kanz Al Muslim'},
  'tabTasbeeh': {'ar': 'تسبيح', 'en': 'Tasbeeh'},
  'tabRecords': {'ar': 'السجل', 'en': 'Records'},
  'tabNotifications': {'ar': 'الاشعارات', 'en': 'Notifications'},
  'tabSettings': {'ar': 'الإعدادات', 'en': 'Settings'},
  'normalMember': {'ar': 'العضويه العاديه', 'en': 'Standard membership'},
  'premiumMember': {'ar': 'العضويه المميزه', 'en': 'Premium membership'},
  'guest': {'ar': 'زائر', 'en': 'Guest'},
  'tapToSignIn': {'ar': 'سجّل الدخول للمنافسة', 'en': 'Sign in to compete'},
  'swipeHint': {'ar': 'اسحب للأعلى للتسبيح', 'en': 'Swipe up to count'},
  'date': {'ar': 'التاريخ', 'en': 'Date'},
  'dhikr': {'ar': 'الذكر', 'en': 'Dhikr'},
  'count': {'ar': 'العدد', 'en': 'Count'},
  'noRecords': {'ar': 'لا يوجد تسبيح بعد', 'en': 'No tasbeeh yet'},
  // الإشعارات
  'autoReminder': {'ar': 'تذكير تلقائي', 'en': 'Auto reminder'},
  'notifyEvery': {'ar': 'تنبيه كل', 'en': 'Notify every'},
  'minute': {'ar': 'دقيقه', 'en': 'min'},
  'chooseType': {
    'ar': 'اختر نوع و وقت التذكير',
    'en': 'Choose reminder type and time',
  },
  'customReminder': {'ar': 'تذكير مخصص', 'en': 'Custom reminder'},
  'addAdhkar': {'ar': 'اضافه الاذكار', 'en': 'Add adhkar'},
  'editAdhkar': {'ar': 'تحرير الاذكار', 'en': 'Edit adhkar'},
  'done': {'ar': 'تم', 'en': 'Done'},
  'every': {'ar': 'كل', 'en': 'Every'},
  'notifWebOnly': {
    'ar': 'هذه معاينة: التنبيهات الفعلية تعمل على الجوال',
    'en': 'Preview only: real notifications work on the phone',
  },
  'notifPermissionDenied': {
    'ar': 'الاشعارات مقفله. فعّلها من اعدادات الجهاز',
    'en': 'Notifications are off. Enable them in device settings.',
  },
  'reminderSound': {
    'ar': 'صوت الذكر مع التنبيه',
    'en': 'Dhikr sound with reminders',
  },
  // الإعدادات
  'language': {'ar': 'اللغه', 'en': 'Language'},
  'support': {'ar': 'الاشتراك و دعم التطبيق', 'en': 'Subscribe & support'},
  'rate': {'ar': 'قيم التطبيق', 'en': 'Rate the app'},
  'contact': {'ar': 'تواصل معنا', 'en': 'Contact us'},
  'share': {'ar': 'شارك التطبيق', 'en': 'Share the app'},
  'about': {'ar': 'عن التطبيق', 'en': 'About'},
  'dnd': {'ar': 'عدم الازعاج', 'en': 'Do not disturb'},
  'dndFrom': {'ar': 'لا تنبيهات من', 'en': 'No reminders from'},
  'to': {'ar': 'الى', 'en': 'to'},
  'sound': {'ar': 'صوت التسبيح', 'en': 'Tasbeeh sound'},
  'vibration': {'ar': 'الاهتزاز عند 33', 'en': 'Vibrate at 33'},
  'manageDhikr': {'ar': 'التسابيح', 'en': 'Tasbeehs'},
  'ranking': {'ar': 'الترتيب', 'en': 'Ranking'},
  'friends': {'ar': 'الاصدقاء', 'en': 'Friends'},
  'account': {'ar': 'الحساب', 'en': 'Account'},
  'shareText': {
    'ar': 'جرّب تطبيق كنز المسلم للتسبيح والمنافسة في ذكر الله',
    'en': 'Try Kanz Al Muslim, a tasbeeh app to compete in remembering Allah',
  },
  'aboutBody': {
    'ar': 'بعون الله ورعايته نقدم لكم تطبيق كنز المسلم ونتمنى من الله أن ينال اعجابكم. التطبيق عبارة عن طريقة جديدة للتسبيح ومحفزة لروح المنافسة بين الاصدقاء والمسلمين، حيث يعرض ترتيبك بين اصدقائك والمسبحين حول العالم، ويحفظ التسبيحات لكل تسبيحة على حدة، مع الاهتزاز عند 33 والتهنئة عند المائة.',
    'en': 'Kanz Al Muslim is a new way to do tasbeeh that motivates friendly competition between friends and Muslims worldwide.',
  },
  // الدعم
  'supportBody': {
    'ar': 'يحتاج التطبيق الى متابعه و تحسين و تطوير من فريق عمل متكامل و هذا مكلف, كن على يقين ان دعمك لنا من خلال الشراء يساعدنا كثيرا في تطوير التطبيق و الاستمرار في تحسينه, كما انها فرصه لكل واحد منكم بأن يكون شريك في الأجر و الثواب في تطوير التطبيق و ليس فقط باستخدامه',
    'en': 'The app needs continuous care from a full team, which is costly. Your support helps us keep improving it, and is a chance to share in the reward.',
  },
  'getPremium': {'ar': 'احصل على عضويه مميزه', 'en': 'Get premium membership'},
  'restore': {'ar': 'استعادة المشتريات', 'en': 'Restore Purchase'},
  'back': {'ar': 'رجوع', 'en': 'Back'},
  'thanksPremium': {
    'ar': 'جزاك الله خيرا على دعمك',
    'en': 'Thank you for your support',
  },
  'storeUnavailable': {
    'ar': 'المتجر غير متاح حاليا',
    'en': 'Store not available right now',
  },
  // الحساب والترتيب
  'signIn': {'ar': 'تسجيل الدخول', 'en': 'Sign in'},
  'signInToCompete': {
    'ar': 'سجّل الدخول لتنافس الذاكرين حول العالم',
    'en': 'Sign in to compete worldwide',
  },
  'signInApple': {'ar': 'المتابعه مع Apple', 'en': 'Continue with Apple'},
  'signInGoogle': {'ar': 'المتابعه مع Google', 'en': 'Continue with Google'},
  'signOut': {'ar': 'تسجيل الخروج', 'en': 'Sign out'},
  'deleteAccount': {'ar': 'حذف الحساب', 'en': 'Delete account'},
  'deleteAccountConfirm': {
    'ar': 'سيتم حذف حسابك ونقاطك من الترتيب نهائيا. تسبيحك المحفوظ على الجهاز يبقى كما هو.',
    'en': 'Your account and ranking points will be permanently deleted. Tasbeeh saved on this device stays.',
  },
  'displayName': {'ar': 'الاسم الظاهر', 'en': 'Display name'},
  'cloudOff': {
    'ar': 'الترتيب غير متاح حاليا',
    'en': 'Ranking is not available right now',
  },
  'today': {'ar': 'اليوم', 'en': 'Today'},
  'thisWeek': {'ar': 'هذا الأسبوع', 'en': 'This week'},
  'thisMonth': {'ar': 'هذا الشهر', 'en': 'This month'},
  'allTime': {'ar': 'الكل', 'en': 'All'},
  'world': {'ar': 'العالم', 'en': 'World'},
  'you': {'ar': 'أنت', 'en': 'You'},
  'noOneYet': {
    'ar': 'لا يوجد أحد بعد، كن الأول!',
    'en': 'No one yet, be the first!',
  },
  'gameCenter': {'ar': 'Game Center', 'en': 'Game Center'},
  'playGames': {'ar': 'Play Games', 'en': 'Play Games'},
  // الأصدقاء
  'myCode': {'ar': 'رمزك للأصدقاء', 'en': 'Your friend code'},
  'addFriend': {'ar': 'اضافه صديق', 'en': 'Add friend'},
  'enterCode': {'ar': 'اكتب رمز صديقك', 'en': "Enter your friend's code"},
  'send': {'ar': 'ارسال', 'en': 'Send'},
  'requestSent': {'ar': 'تم ارسال الطلب', 'en': 'Request sent'},
  'codeNotFound': {'ar': 'الرمز غير صحيح', 'en': 'Code not found'},
  'requests': {'ar': 'طلبات الصداقه', 'en': 'Friend requests'},
  'noFriends': {
    'ar': 'أضف أصدقاءك وتنافسوا في الذكر',
    'en': 'Add friends and compete in dhikr',
  },
  'removeFriend': {'ar': 'ازاله الصديق', 'en': 'Remove friend'},
  'typeMessage': {'ar': 'اكتب رساله…', 'en': 'Type a message…'},
  // التسابيح
  'addDhikr': {'ar': 'اضافه تسبيحه', 'en': 'Add tasbeeh'},
  'editDhikr': {'ar': 'تعديل التسبيحه', 'en': 'Edit tasbeeh'},
  'dhikrText': {'ar': 'نص التسبيحه', 'en': 'Tasbeeh text'},
  'cycleOf': {'ar': 'عدد الحبات', 'en': 'Beads per cycle'},
  'deleteConfirm': {
    'ar': 'هل تريد حذف هذه التسبيحه؟',
    'en': 'Delete this tasbeeh?',
  },
  'cantDeleteLast': {
    'ar': 'يجب أن تبقى تسبيحه واحده على الأقل',
    'en': 'At least one tasbeeh must remain',
  },
  'congrats': {'ar': 'مبروك', 'en': 'Congratulations'},
  'youGot': {'ar': 'حصلت على', 'en': 'You got'},
  'points': {'ar': 'نقطة', 'en': 'points'},
  'congratsBody': {'ar': 'المجموع الكلي {n}', 'en': 'Total {n}'},
  'save': {'ar': 'حفظ', 'en': 'Save'},
  'cancel': {'ar': 'الغاء', 'en': 'Cancel'},
  'delete': {'ar': 'حذف', 'en': 'Delete'},
  'error': {
    'ar': 'حدث خطأ، حاول مره أخرى',
    'en': 'Something went wrong, try again',
  },
  'tabRanking': {'ar': 'الترتيب', 'en': 'Ranking'},
  'tabFriends': {'ar': 'الأصدقاء', 'en': 'Friends'},
  'total': {'ar': 'المجموع', 'en': 'Total'},
  'tapToCount': {'ar': 'المس الشاشة للتسبيح', 'en': 'Tap anywhere to count'},
  'swipeToChange': {'ar': 'اسحب يميناً أو يساراً لتغيير الذكر', 'en': 'Swipe to change dhikr'},
  'resetCycle': {'ar': 'تصفير العداد', 'en': 'Reset counter'},
  'vibrateEvery': {'ar': 'الاهتزاز كل', 'en': 'Vibrate every'},
  'continue': {'ar': 'متابعة', 'en': 'Continue'},
  'last30': {'ar': 'آخر 30 يوماً', 'en': 'Last 30 days'},
  'times': {'ar': 'مرة', 'en': 'times'},
  'accept': {'ar': 'قبول', 'en': 'Accept'},
  'decline': {'ar': 'رفض', 'en': 'Decline'},
  'chat': {'ar': 'محادثة', 'en': 'Chat'},
  'reminders': {'ar': 'التذكير', 'en': 'Reminders'},
  'minutes': {'ar': 'دقيقة', 'en': 'min'},
  'addReminder': {'ar': 'إضافة تذكير', 'en': 'Add reminder'},
  'customReminders': {'ar': 'تذكير مخصص', 'en': 'Custom reminders'},
  'reminderHint': {'ar': 'ذكر معيّن يتكرر كل عدد من الدقائق', 'en': 'A chosen dhikr repeating every few minutes'},
  'general': {'ar': 'عام', 'en': 'General'},
  'more': {'ar': 'المزيد', 'en': 'More'},
};

/// اللغة تُقرأ بدون اشتراك، والتطبيق كله يُعاد بناؤه عند تغيير اللغة
/// (انظر KeyedSubtree في app.dart) فيصلح استخدامها داخل الدوال أيضاً.
String tr(BuildContext context, String key, {Map<String, String>? args}) {
  final lang = Provider.of<AppState>(context, listen: false).language;
  return trLang(lang, key, args: args);
}

String trLang(String lang, String key, {Map<String, String>? args}) {
  var s = _strings[key]?[lang] ?? _strings[key]?['ar'] ?? key;
  args?.forEach((k, v) => s = s.replaceAll('{$k}', v));
  return s;
}

/// الأرقام دائماً لاتينية (0-9) في كل اللغات.
String fmtNum(BuildContext context, int n) => n.toString();

String fmtNumLang(String lang, int n) => n.toString();

/// يحوّل أي أرقام عربية-هندية (0-9) في نص إلى أرقام لاتينية.
String latinDigits(String s) =>
    s.replaceAllMapped(RegExp('[\u0660-\u0669]'), (m) => '${m[0]!.codeUnitAt(0) - 0x0660}');
