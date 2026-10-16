import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n.dart';
import '../platform.dart';
import '../services/cloud_service.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/avatar.dart';
import '../widgets/kanz_ui.dart';
import 'about_screen.dart';
import 'account_screen.dart';
import 'manage_dhikr_screen.dart';
import 'reminders_screen.dart';
import 'sign_in_sheet.dart';
import 'support_screen.dart';

/// رقم التطبيق في App Store (من App Store Connect → App Information → Apple ID).
const appStoreId = '';
const contactEmail = 'info@revvin.net';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _push(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final cloud = context.watch<CloudService>();

    Widget nav(IconData icon, String key, VoidCallback onTap) => ListTile(
          leading: Icon(icon),
          title: Text(tr(context, key)),
          trailing: const Icon(Icons.chevron_right, color: Colors.white54),
          onTap: onTap,
        );

    return Scaffold(
      appBar: AppBar(title: Text(tr(context, 'tabSettings'))),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          if (cloud.available) _AccountCard(cloud: cloud, onOpen: () => _push(context, const AccountScreen())),
          Card(
            child: Column(
              children: [
                nav(Icons.format_list_bulleted, 'manageDhikr', () => _push(context, const ManageDhikrScreen())),
                nav(Icons.notifications_active_outlined, 'reminders', () => _push(context, const RemindersScreen())),
              ],
            ),
          ),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.volume_up_outlined, color: KanzColors.primary),
                  title: Text(tr(context, 'sound')),
                  value: s.soundOn,
                  onChanged: s.setSound,
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.vibration, color: KanzColors.primary),
                  title: Text(tr(context, 'vibration')),
                  value: s.vibrationOn,
                  onChanged: s.setVibration,
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.nightlight_round, color: KanzColors.primary),
                  title: Text(tr(context, 'dnd')),
                  subtitle: s.dnd
                      ? Text(
                          '${tr(context, 'dndFrom')} ${_hour(context, s.dndStartHour)} ${tr(context, 'to')} ${_hour(context, s.dndEndHour)}',
                          style: const TextStyle(color: Colors.white70),
                        )
                      : null,
                  value: s.dnd,
                  onChanged: (v) => v ? _pickDnd(context) : s.updateReminders(dndOn: false),
                ),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(tr(context, 'language')),
                  trailing: SegmentedButton<String>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: 'ar', label: Text('عربي')),
                      ButtonSegment(value: 'en', label: Text('EN')),
                    ],
                    selected: {s.language},
                    onSelectionChanged: (v) => s.setLanguage(v.first),
                  ),
                ),
              ],
            ),
          ),
          Card(
            child: Column(
              children: [
                nav(Icons.favorite_border, 'support', () => _push(context, const SupportScreen())),
                nav(Icons.star_border, 'rate', _rate),
                nav(Icons.alternate_email, 'contact',
                    () => launchUrl(Uri.parse('mailto:$contactEmail?subject=Kanz%20Almuslim'))),
                nav(Icons.ios_share, 'share',
                    () => SharePlus.instance.share(ShareParams(text: tr(context, 'shareText')))),
                ListTile(
                  leading: const KanzLogo(size: 26),
                  title: Text(tr(context, 'about')),
                  trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                  onTap: () => _push(context, const AboutScreen()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _hour(BuildContext context, int h) =>
      MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay(hour: h, minute: 0));

  Future<void> _rate() async {
    final review = InAppReview.instance;
    try {
      if (appStoreId.isNotEmpty || isAndroid) {
        await review.openStoreListing(appStoreId: appStoreId.isEmpty ? null : appStoreId);
      } else if (await review.isAvailable()) {
        await review.requestReview();
      }
    } catch (e) {
      debugPrint('Rate failed: $e');
    }
  }

  Future<void> _pickDnd(BuildContext context) async {
    final s = context.read<AppState>();
    final from = await showTimePicker(
      context: context,
      helpText: tr(context, 'dndFrom'),
      initialTime: TimeOfDay(hour: s.dndStartHour, minute: 0),
    );
    if (from == null || !context.mounted) return;
    final to = await showTimePicker(
      context: context,
      helpText: tr(context, 'to'),
      initialTime: TimeOfDay(hour: s.dndEndHour, minute: 0),
    );
    if (to == null) return;
    await s.updateReminders(dndOn: true, dndStart: from.hour, dndEnd: to.hour);
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.cloud, required this.onOpen});
  final CloudService cloud;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    if (!cloud.signedIn) {
      return Card(
        child: ListTile(
          leading: const Avatar(name: ''),
          title: Text(tr(context, 'guest')),
          subtitle: Text(tr(context, 'signInToCompete'), style: const TextStyle(color: Colors.white70)),
          trailing: FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(48, 40)),
            onPressed: () => showSignInSheet(context),
            child: Text(tr(context, 'signIn')),
          ),
        ),
      );
    }
    return Card(
      child: ListTile(
        leading: Avatar(name: cloud.displayName, url: cloud.user?.photoURL),
        title: Text(cloud.displayName),
        subtitle: Text(tr(context, 'account'), style: const TextStyle(color: Colors.white70)),
        trailing: const Icon(Icons.chevron_right, color: Colors.white54),
        onTap: onOpen,
      ),
    );
  }
}
