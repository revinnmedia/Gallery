import 'dart:math';

import '../platform.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../data/defaults.dart';

/// مصدر تنبيهات متكرر: إما التذكير التلقائي (عبارة عشوائية) أو تذكير مخصص.
class ReminderStream {
  const ReminderStream({required this.intervalMinutes, this.text, this.sound});

  final int intervalMinutes;

  /// null = عبارة عشوائية في كل مرة (التذكير التلقائي).
  final String? text;
  final String? sound;
}

/// إعدادات التذكير التي يحتاجها جدول التنبيهات.
class ReminderSettings {
  const ReminderSettings({
    required this.streams,
    required this.dnd,
    required this.dndStartHour,
    required this.dndEndHour,
    required this.withDhikrSound,
  });

  final List<ReminderStream> streams;
  final bool dnd;
  final int dndStartHour;
  final int dndEndHour;
  final bool withDhikrSound;
}

/// موعد تنبيه واحد في الجدول.
class PlannedReminder {
  const PlannedReminder(this.when, this.stream);
  final DateTime when;
  final int stream;
}

/// جدولة التنبيهات.
///
/// المبدأ الأساسي لإصلاح مشكلة النسخة القديمة (تنبيهات مكررة ومتراكمة):
/// كل مرة نلغي **كل** التنبيهات المجدولة ثم نعيد بناء الجدول كاملاً من
/// الإعدادات. لا يوجد أي مسار يضيف تنبيهات فوق الموجودة، ولا يوجد تنبيهان
/// في نفس الدقيقة.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  /// حد iOS هو ٦٤ تنبيهاً مجدولاً، نترك هامشاً. أندرويد يسمح بأكثر.
  static int get maxPending => isIOS ? 60 : 200;
  static const _idBase = 100;

  /// أقل مدة بين تنبيهين لنفس المصدر.
  static const minInterval = 5;

  /// عند وضع ملفات الأصوات في المشروع (انظر docs/SOUNDS.md) غيّرها إلى true.
  static const soundsBundled = false;

  Future<void> init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (e) {
      debugPrint('Timezone fallback to UTC: $e');
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _ready = true;
  }

  /// يطلب إذن التنبيهات. يرجع true إذا وافق المستخدم.
  Future<bool> requestPermission() async {
    // في معاينة المتصفح لا توجد تنبيهات للجهاز: نسمح بتجربة الإعدادات فقط.
    if (kIsWeb) return true;
    await init();
    if (isIOS) {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      return await ios?.requestPermissions(
            alert: true,
            sound: true,
            badge: false,
          ) ??
          false;
    }
    if (isAndroid) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await android?.requestNotificationsPermission() ?? false;
    }
    return false;
  }

  /// يلغي كل شيء ويعيد الجدولة من الصفر.
  Future<void> rescheduleAll(ReminderSettings s) async {
    if (kIsWeb) return;
    await init();
    await _plugin.cancelAll();
    if (s.streams.isEmpty) return;

    final now = tz.TZDateTime.now(tz.local);
    final plan = buildPlan(
      now: now,
      streams: s.streams,
      dnd: s.dnd,
      dndStartHour: s.dndStartHour,
      dndEndHour: s.dndEndHour,
      max: maxPending,
    );

    final rnd = Random();
    var lastPhrase = -1;
    for (var i = 0; i < plan.length; i++) {
      final stream = s.streams[plan[i].stream];
      String body;
      String? sound;
      if (stream.text != null) {
        body = stream.text!;
        sound = stream.sound;
      } else {
        var idx = rnd.nextInt(reminderPhrases.length);
        if (idx == lastPhrase) idx = (idx + 1) % reminderPhrases.length;
        lastPhrase = idx;
        body = reminderPhrases[idx].text;
        sound = reminderPhrases[idx].sound;
      }
      await _schedule(
        id: _idBase + i,
        when: tz.TZDateTime.from(plan[i].when, tz.local),
        body: body,
        sound: s.withDhikrSound ? sound : null,
      );
    }
    debugPrint('Scheduled ${plan.length} notifications');
  }

  /// يبني جدول التنبيهات القادمة من كل المصادر:
  /// - كل مصدر يتكرر كل [ReminderStream.intervalMinutes] بعد [now].
  /// - لا تنبيهات داخل فترة عدم الإزعاج.
  /// - لا تنبيهان في نفس الدقيقة (الأول يفوز).
  /// - الجدول تصاعدي ولا يتجاوز [max].
  @visibleForTesting
  static List<PlannedReminder> buildPlan({
    required DateTime now,
    required List<ReminderStream> streams,
    required bool dnd,
    required int dndStartHour,
    required int dndEndHour,
    required int max,
  }) {
    final candidates = <PlannedReminder>[];
    // نحدّ البحث بعشرة أيام حتى لا تدور الحلقة بلا نهاية.
    final limit = now.add(const Duration(days: 10));
    for (var i = 0; i < streams.length; i++) {
      final every = streams[i].intervalMinutes;
      if (every < minInterval) continue;
      var t = now.add(Duration(minutes: every));
      var added = 0;
      while (t.isBefore(limit) && added < max) {
        if (!dnd || !_inQuietHours(t.hour, dndStartHour, dndEndHour)) {
          candidates.add(PlannedReminder(t, i));
          added++;
        }
        t = t.add(Duration(minutes: every));
      }
    }
    candidates.sort((a, b) {
      final c = a.when.compareTo(b.when);
      return c != 0 ? c : a.stream.compareTo(b.stream);
    });

    final out = <PlannedReminder>[];
    final usedMinutes = <int>{};
    for (final c in candidates) {
      if (out.length >= max) break;
      final minuteId = c.when.millisecondsSinceEpoch ~/ 60000;
      if (!usedMinutes.add(minuteId)) continue;
      out.add(c);
    }
    return out;
  }

  static bool _inQuietHours(int hour, int start, int end) {
    if (start == end) return false;
    if (start < end) return hour >= start && hour < end;
    // فترة تمر بمنتصف الليل، مثلاً من ٢٢ إلى ٦.
    return hour >= start || hour < end;
  }

  Future<void> _schedule({
    required int id,
    required tz.TZDateTime when,
    required String body,
    required String? sound,
  }) async {
    final useSound = soundsBundled && sound != null;
    // في أندرويد صوت التنبيه مرتبط بالقناة، لذلك لكل صوت قناة خاصة.
    final channelId = useSound ? 'dhikr_$sound' : 'dhikr_default';
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        'تذكير بالذكر',
        channelDescription: 'تنبيهات التذكير بذكر الله',
        importance: Importance.high,
        priority: Priority.high,
        sound: useSound ? RawResourceAndroidNotificationSound(sound) : null,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        sound: useSound ? '$sound.caf' : null,
        threadIdentifier: 'kanz_reminders',
      ),
    );
    await _plugin.zonedSchedule(
      id: id,
      scheduledDate: when,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      title: 'كنز المسلم',
      body: body,
    );
  }

  Future<void> cancelAll() async {
    if (kIsWeb) return;
    await init();
    await _plugin.cancelAll();
  }
}
