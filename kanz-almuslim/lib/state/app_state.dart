import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/defaults.dart';
import '../models.dart';
import '../services/audio_service.dart';
import '../services/cloud_service.dart';
import '../services/games_service.dart';
import '../services/notification_service.dart';

/// نتيجة كل تسبيحة، لتعرف الواجهة إن كان يجب عرض التهنئة.
class TapResult {
  const TapResult({required this.cycleDone, required this.hundred});
  final bool cycleDone;
  final bool hundred;
}

/// حالة التطبيق المحلية: الأذكار، العدّادات، السجل، الإعدادات.
class AppState extends ChangeNotifier {
  AppState(this._prefs) {
    _load();
  }

  final SharedPreferences _prefs;

  late List<Dhikr> dhikrs;
  int currentIndex = 0;

  /// العدّاد الحالي داخل الدورة (يرجع للصفر بالتصفير).
  final Map<String, int> cycleCounts = {};

  /// مجموع كل التسبيحات منذ تثبيت التطبيق.
  int total = 0;

  /// السجل: يوم -> (ذكر -> عدد).
  final Map<String, Map<String, int>> history = {};

  // الإعدادات
  bool soundOn = true;
  bool vibrationOn = true;
  String language = 'ar';

  // التذكير (نفس خيارات النسخة الأصلية)
  bool autoReminder = false;
  int autoInterval = 30;
  bool customReminderOn = false;
  List<CustomReminder> customReminders = [];
  bool dnd = false;
  int dndStartHour = 22;
  int dndEndHour = 6;
  bool reminderSound = true;

  /// العضوية المميزة (بعد الشراء من شاشة الدعم).
  bool premium = false;

  Dhikr get current => dhikrs[currentIndex.clamp(0, dhikrs.length - 1)];
  int get currentCycle => cycleCounts[current.id] ?? 0;

  /// الرقم الظاهر على السبحة: يبدأ من ٠، ويعدّ حتى [Dhikr.target]
  /// ثم يرجع إلى ١ في التسبيحة التالية (مثل النسخة الأصلية).
  int get displayCount {
    final c = currentCycle;
    final t = current.target;
    if (c == 0 || t <= 0) return c;
    return ((c - 1) % t) + 1;
  }
  int get todayTotal => dayTotal(dayKey(DateTime.now()));

  int dayTotal(String key) => history[key]?.values.fold<int>(0, (a, b) => a + b) ?? 0;

  // -------------------------------------------------------------- التحميل

  void _load() {
    final rawDhikrs = _prefs.getString('dhikrs');
    dhikrs = rawDhikrs == null
        ? defaultDhikrList()
        : (jsonDecode(rawDhikrs) as List).map((e) => Dhikr.fromJson(e as Map<String, dynamic>)).toList();
    if (dhikrs.isEmpty) dhikrs = defaultDhikrList();

    currentIndex = _prefs.getInt('currentIndex') ?? 0;
    if (currentIndex >= dhikrs.length) currentIndex = 0;
    total = _prefs.getInt('total') ?? 0;

    final rawCycles = _prefs.getString('cycles');
    if (rawCycles != null) {
      (jsonDecode(rawCycles) as Map<String, dynamic>)
          .forEach((k, v) => cycleCounts[k] = (v as num).toInt());
    }
    final rawHistory = _prefs.getString('history');
    if (rawHistory != null) {
      (jsonDecode(rawHistory) as Map<String, dynamic>).forEach((day, v) {
        history[day] = (v as Map<String, dynamic>).map((k, c) => MapEntry(k, (c as num).toInt()));
      });
    }

    soundOn = _prefs.getBool('soundOn') ?? true;
    vibrationOn = _prefs.getBool('vibrationOn') ?? true;
    language = _prefs.getString('language') ?? 'ar';

    autoReminder = _prefs.getBool('autoReminder') ?? false;
    autoInterval = _prefs.getInt('autoInterval') ?? 30;
    customReminderOn = _prefs.getBool('customReminderOn') ?? false;
    dnd = _prefs.getBool('dnd') ?? false;
    dndStartHour = _prefs.getInt('dndStartHour') ?? 22;
    dndEndHour = _prefs.getInt('dndEndHour') ?? 6;
    reminderSound = _prefs.getBool('reminderSound') ?? true;
    premium = _prefs.getBool('premium') ?? false;
    final rawCustom = _prefs.getString('customReminders');
    customReminders = rawCustom == null
        ? []
        : (jsonDecode(rawCustom) as List)
            .map((e) => CustomReminder.fromJson(e as Map<String, dynamic>))
            .toList();
  }

  // --------------------------------------------------------------- الحفظ

  void _saveCounts() {
    _prefs.setInt('total', total);
    _prefs.setString('cycles', jsonEncode(cycleCounts));
    _prefs.setString('history', jsonEncode(history));
  }

  void _saveDhikrs() {
    _prefs.setString('dhikrs', jsonEncode(dhikrs.map((d) => d.toJson()).toList()));
    _prefs.setInt('currentIndex', currentIndex);
  }

  void _saveReminders() {
    _prefs.setBool('autoReminder', autoReminder);
    _prefs.setInt('autoInterval', autoInterval);
    _prefs.setBool('customReminderOn', customReminderOn);
    _prefs.setBool('dnd', dnd);
    _prefs.setInt('dndStartHour', dndStartHour);
    _prefs.setInt('dndEndHour', dndEndHour);
    _prefs.setBool('reminderSound', reminderSound);
    _prefs.setString('customReminders', jsonEncode(customReminders.map((r) => r.toJson()).toList()));
  }

  // -------------------------------------------------------------- التسبيح

  TapResult tap() {
    final d = current;
    final cycle = (cycleCounts[d.id] ?? 0) + 1;
    cycleCounts[d.id] = cycle;
    total++;
    final today = dayKey(DateTime.now());
    final day = history.putIfAbsent(today, () {
      _trimHistory();
      return {};
    });
    day[d.id] = (day[d.id] ?? 0) + 1;

    final cycleDone = d.target > 0 && cycle % d.target == 0;
    final hundred = total % 100 == 0;

    if (cycleDone && vibrationOn) HapticFeedback.heavyImpact();
    if (hundred) {
      AudioService.instance.play(celebrationSound);
      GamesService.instance.submitTotal(total);
    } else if (soundOn) {
      AudioService.instance.play(d.sound);
    }

    CloudService.instance.addPoints(1);
    _saveCounts();
    notifyListeners();
    return TapResult(cycleDone: cycleDone, hundred: hundred);
  }

  /// نحتفظ بسجل آخر ٤٠٠ يوم فقط حتى لا يكبر التخزين بلا حد.
  void _trimHistory() {
    if (history.length < 400) return;
    final keys = history.keys.toList()..sort();
    for (final k in keys.take(history.length - 399)) {
      history.remove(k);
    }
  }

  void resetCycle() {
    cycleCounts[current.id] = 0;
    _saveCounts();
    notifyListeners();
  }

  void selectDhikr(int index) {
    if (index < 0 || index >= dhikrs.length || index == currentIndex) return;
    currentIndex = index;
    AudioService.instance.stop();
    _prefs.setInt('currentIndex', currentIndex);
    notifyListeners();
  }

  // ------------------------------------------------------- إدارة الأذكار

  void addDhikr(String text, int target) {
    dhikrs.add(Dhikr(
      id: 'u${DateTime.now().microsecondsSinceEpoch}',
      text: text.trim(),
      target: target,
    ));
    _saveDhikrs();
    notifyListeners();
  }

  void updateDhikr(Dhikr d, String text, int target) {
    d.text = text.trim();
    d.target = target;
    _saveDhikrs();
    notifyListeners();
  }

  /// يرجع false إذا كان آخر ذكر (لا يُحذف).
  bool deleteDhikr(Dhikr d) {
    if (dhikrs.length <= 1) return false;
    final idx = dhikrs.indexOf(d);
    dhikrs.remove(d);
    if (currentIndex >= dhikrs.length || idx < currentIndex) {
      currentIndex = (currentIndex - 1).clamp(0, dhikrs.length - 1);
    }
    cycleCounts.remove(d.id);
    _saveDhikrs();
    _saveCounts();
    notifyListeners();
    return true;
  }

  /// newIndex مصحّح مسبقاً من ReorderableListView.onReorderItem.
  void reorderDhikr(int oldIndex, int newIndex) {
    final currentId = current.id;
    final d = dhikrs.removeAt(oldIndex);
    dhikrs.insert(newIndex, d);
    currentIndex = dhikrs.indexWhere((x) => x.id == currentId);
    _saveDhikrs();
    notifyListeners();
  }

  String dhikrText(String id) {
    for (final d in dhikrs) {
      if (d.id == id) return d.text;
    }
    for (final d in defaultDhikrList()) {
      if (d.id == id) return d.text;
    }
    return '—';
  }

  // ------------------------------------------------------------ الإعدادات

  void setSound(bool v) {
    soundOn = v;
    if (!v) AudioService.instance.stop();
    _prefs.setBool('soundOn', v);
    notifyListeners();
  }

  void setVibration(bool v) {
    vibrationOn = v;
    _prefs.setBool('vibrationOn', v);
    notifyListeners();
  }

  void setLanguage(String v) {
    language = v;
    _prefs.setString('language', v);
    notifyListeners();
  }

  void setPremium(bool v) {
    premium = v;
    _prefs.setBool('premium', v);
    notifyListeners();
  }

  // -------------------------------------------------------------- التذكير

  ReminderSettings get reminderSettings => ReminderSettings(
        streams: [
          if (autoReminder) ReminderStream(intervalMinutes: autoInterval),
          if (customReminderOn)
            for (final r in customReminders.where((r) => r.enabled))
              ReminderStream(intervalMinutes: r.intervalMinutes, text: r.text, sound: r.sound),
        ],
        dnd: dnd,
        dndStartHour: dndStartHour,
        dndEndHour: dndEndHour,
        withDhikrSound: reminderSound,
      );

  bool get anyReminderOn =>
      autoReminder || (customReminderOn && customReminders.any((r) => r.enabled));

  /// يعيد بناء جدول التنبيهات كاملاً (يلغي القديم أولاً).
  Future<void> applyReminders() => NotificationService.instance.rescheduleAll(reminderSettings);

  Future<void> updateReminders({
    bool? auto,
    int? interval,
    bool? custom,
    bool? dndOn,
    int? dndStart,
    int? dndEnd,
    bool? sound,
  }) async {
    autoReminder = auto ?? autoReminder;
    if (interval != null) {
      autoInterval = interval.clamp(NotificationService.minInterval, 24 * 60);
    }
    customReminderOn = custom ?? customReminderOn;
    dnd = dndOn ?? dnd;
    dndStartHour = dndStart ?? dndStartHour;
    dndEndHour = dndEnd ?? dndEndHour;
    reminderSound = sound ?? reminderSound;
    _saveReminders();
    notifyListeners();
    await applyReminders();
  }

  Future<void> addCustomReminder(String text, String? sound, int intervalMinutes) async {
    customReminders.add(CustomReminder(
      id: 'c${DateTime.now().microsecondsSinceEpoch}',
      text: text,
      sound: sound,
      intervalMinutes: intervalMinutes.clamp(NotificationService.minInterval, 24 * 60),
    ));
    customReminderOn = true;
    _saveReminders();
    notifyListeners();
    await applyReminders();
  }

  Future<void> deleteCustomReminder(CustomReminder r) async {
    customReminders.remove(r);
    _saveReminders();
    notifyListeners();
    await applyReminders();
  }
}
