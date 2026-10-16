import 'package:flutter/material.dart';

import '../l10n.dart';
import '../theme.dart';
import '../widgets/kanz_ui.dart';
import 'notifications_screen.dart';
import 'records_screen.dart';
import 'settings_screen.dart';
import 'tasbeeh_screen.dart';

/// الهيكل الرئيسي بالشريط السفلي الأصلي: سبحه، السجل، الاشعارات، الاعدادات.
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
    NotificationsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KanzColors.bgTop,
      body: IndexedStack(index: _tab, children: _pages),
      bottomNavigationBar: _Footer(
        index: _tab,
        onTap: (i) => setState(() => _tab = i),
        labels: [
          tr(context, 'tabTasbeeh'),
          tr(context, 'tabRecords'),
          tr(context, 'tabNotifications'),
          tr(context, 'tabSettings'),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.index,
    required this.onTap,
    required this.labels,
  });
  final int index;
  final ValueChanged<int> onTap;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    Widget icon(int i, Color c) => switch (i) {
      0 => BeadsIcon(color: c, size: 38),
      1 => Icon(Icons.view_list_sharp, color: c, size: 40),
      2 => Icon(Icons.notifications_none, color: c, size: 40),
      _ => Icon(Icons.settings, color: c, size: 40),
    };
    return Container(
      decoration: const BoxDecoration(
        color: KanzColors.tabBar,
        border: Border(top: BorderSide(color: KanzColors.cyan, width: 1)),
      ),
      padding: EdgeInsets.only(bottom: bottom > 0 ? bottom : 6, top: 4),
      child: Row(
        children: List.generate(4, (i) {
          final active = i == index;
          final c = active ? KanzColors.cyan : Colors.white;
          return Expanded(
            child: InkResponse(
              onTap: () => onTap(i),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 42, child: Center(child: icon(i, c))),
                    Text(
                      labels[i],
                      style: TextStyle(
                        color: c,
                        fontSize: 14,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
