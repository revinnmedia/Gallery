import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'services/cloud_service.dart';
import 'services/games_service.dart';
import 'services/notification_service.dart';
import 'services/purchase_service.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final prefs = await SharedPreferences.getInstance();
  final state = AppState(prefs);

  try {
    await NotificationService.instance.init();
  } catch (e) {
    debugPrint('Notifications unavailable: $e');
  }
  await CloudService.instance.init();

  // نعيد بناء جدول التنبيهات عند كل فتح، بعد إلغاء القديم بالكامل.
  // هذا يجدّد التذكير العشوائي ولا يكرره أبداً.
  if (!kIsWeb) {
    if (state.anyReminderOn) {
      state.applyReminders();
    } else {
      NotificationService.instance.cancelAll();
    }
  }

  GamesService.instance.signIn();

  // الشراء أو الاستعادة من شاشة الدعم يفعّل العضوية المميزة.
  PurchaseService.instance.onPremium = () => state.setPremium(true);
  PurchaseService.instance.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: state),
        ChangeNotifierProvider.value(value: CloudService.instance),
      ],
      child: const KanzApp(),
    ),
  );
}
