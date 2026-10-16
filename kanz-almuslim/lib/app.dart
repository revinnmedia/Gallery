import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'screens/home_shell.dart';
import 'services/cloud_service.dart';
import 'state/app_state.dart';
import 'theme.dart';

class KanzApp extends StatefulWidget {
  const KanzApp({super.key});

  @override
  State<KanzApp> createState() => _KanzAppState();
}

class _KanzAppState extends State<KanzApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.paused) {
      // نرسل النقاط المتبقية قبل أن يُغلق التطبيق.
      CloudService.instance.flush();
    } else if (s == AppLifecycleState.resumed) {
      final state = context.read<AppState>();
      if (state.anyReminderOn) state.applyReminders();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return MaterialApp(
      title: 'كنز المسلم',
      debugShowCheckedModeBanner: false,
      theme: KanzTheme.build(),
      locale: Locale(state.language),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // إعادة بناء كل الشاشات عند تغيير اللغة.
      home: KeyedSubtree(
        key: ValueKey(state.language),
        child: const HomeShell(),
      ),
    );
  }
}
