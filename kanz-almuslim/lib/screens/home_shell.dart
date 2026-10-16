import 'package:flutter/material.dart';

import '../l10n.dart';
import '../widgets/kanz_ui.dart';
import 'friends_screen.dart';
import 'ranking_screen.dart';
import 'records_screen.dart';
import 'settings_screen.dart';
import 'tasbeeh_screen.dart';

/// الهيكل الرئيسي: تسبيح، السجل، الترتيب، الأصدقاء، الإعدادات.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  static const _pages = <Widget>[
    TasbeehScreen(),
    RecordsScreen(),
    RankingScreen(),
    FriendsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _tab, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          NavigationDestination(
            icon: const BeadsIcon(color: Colors.white, size: 28),
            selectedIcon: const BeadsIcon(color: Color(0xFF38F4F3), size: 28),
            label: tr(context, 'tabTasbeeh'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_month_outlined),
            selectedIcon: const Icon(Icons.calendar_month),
            label: tr(context, 'tabRecords'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.emoji_events_outlined),
            selectedIcon: const Icon(Icons.emoji_events),
            label: tr(context, 'tabRanking'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.people_outline),
            selectedIcon: const Icon(Icons.people),
            label: tr(context, 'tabFriends'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: tr(context, 'tabSettings'),
          ),
        ],
      ),
    );
  }
}
