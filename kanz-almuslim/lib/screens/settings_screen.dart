import 'dart:io';

import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n.dart';
import '../services/cloud_service.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/kanz_ui.dart';
import 'about_screen.dart';
import 'account_screen.dart';
import 'friends_screen.dart';
import 'manage_dhikr_screen.dart';
import 'ranking_screen.dart';
import 'sign_in_sheet.dart';
import 'support_screen.dart';

/// رقم التطبيق في App Store (من App Store Connect → App Information → Apple ID).
const appStoreId = '';
const contactEmail = 'info@revvin.net';

/// الإعدادات بنفس صفوف النسخة الأصلية وترتيبها، وتحتها الصفوف الجديدة.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _push(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final cloud = context.watch<CloudService>();
    const iconColor = Colors.white;

    return KanzPage(
      title: tr(context, 'tabSettings'),
      onHeart: () => _push(context, const SupportScreen()),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ---- صفوف النسخة الأصلية
          KanzRow(
            icon: const Icon(Icons.language, color: iconColor, size: 40),
            title: tr(context, 'language'),
            onTap: () => _pickLanguage(context),
          ),
          KanzRow(
            icon: const Icon(Icons.favorite_border, color: iconColor, size: 40),
            title: tr(context, 'support'),
            onTap: () => _push(context, const SupportScreen()),
          ),
          KanzRow(
            icon: const CircledIcon(Icons.star),
            title: tr(context, 'rate'),
            onTap: _rate,
          ),
          KanzRow(
            icon: const Icon(Icons.alternate_email, color: iconColor, size: 40),
            title: tr(context, 'contact'),
            onTap: () => launchUrl(Uri.parse('mailto:$contactEmail?subject=Kanz%20Almuslim')),
          ),
          KanzRow(
            icon: const Icon(Icons.ios_share, color: iconColor, size: 38),
            title: tr(context, 'share'),
            onTap: () => SharePlus.instance.share(ShareParams(text: tr(context, 'shareText'))),
          ),
          KanzRow(
            icon: const KanzLogo(size: 38, hole: Color(0xFF09425F)),
            title: tr(context, 'about'),
            onTap: () => _push(context, const AboutScreen()),
          ),
          KanzRow(
            icon: const CircledIcon(Icons.nightlight_round),
            title: tr(context, 'dnd'),
            subtitle: s.dnd
                ? '${tr(context, 'dndFrom')} ${_hour(context, s.dndStartHour)} ${tr(context, 'to')} ${_hour(context, s.dndEndHour)}'
                : null,
            onTap: s.dnd ? () => _pickDnd(context) : null,
            indentSeparator: false,
            trailing: KanzSwitch(
              value: s.dnd,
              onChanged: (v) async {
                if (v) {
                  await _pickDnd(context);
                } else {
                  await s.updateReminders(dndOn: false);
                }
              },
            ),
          ),
          const SizedBox(height: 22),
          // ---- الإضافات الجديدة
          Container(height: 1, color: KanzColors.separator),
          if (cloud.available)
            KanzRow(
              icon: const Icon(Icons.person_outline, color: iconColor, size: 40),
              title: tr(context, 'account'),
              subtitle: cloud.signedIn ? cloud.displayName : tr(context, 'tapToSignIn'),
              onTap: () => cloud.signedIn ? _push(context, const AccountScreen()) : showSignInSheet(context),
            ),
          if (cloud.available)
            KanzRow(
              icon: const Icon(Icons.emoji_events_outlined, color: iconColor, size: 40),
              title: tr(context, 'ranking'),
              onTap: () => cloud.signedIn ? _push(context, const RankingScreen()) : showSignInSheet(context),
            ),
          if (cloud.available)
            KanzRow(
              icon: const Icon(Icons.people_outline, color: iconColor, size: 40),
              title: tr(context, 'friends'),
              onTap: () => cloud.signedIn ? _push(context, const FriendsScreen()) : showSignInSheet(context),
            ),
          KanzRow(
            icon: const BeadsIcon(color: iconColor, size: 36),
            title: tr(context, 'manageDhikr'),
            onTap: () => _push(context, const ManageDhikrScreen()),
          ),
          KanzRow(
            icon: const Icon(Icons.volume_up_outlined, color: iconColor, size: 38),
            title: tr(context, 'sound'),
            indentSeparator: false,
            trailing: KanzSwitch(value: s.soundOn, onChanged: s.setSound),
          ),
          KanzRow(
            icon: const Icon(Icons.vibration, color: iconColor, size: 38),
            title: tr(context, 'vibration'),
            indentSeparator: false,
            trailing: KanzSwitch(value: s.vibrationOn, onChanged: s.setVibration),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _hour(BuildContext context, int h) =>
      MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay(hour: h, minute: 0));

  Future<void> _rate() async {
    final review = InAppReview.instance;
    try {
      if (appStoreId.isNotEmpty || Platform.isAndroid) {
        await review.openStoreListing(appStoreId: appStoreId.isEmpty ? null : appStoreId);
      } else if (await review.isAvailable()) {
        await review.requestReview();
      }
    } catch (e) {
      debugPrint('Rate failed: $e');
    }
  }

  Future<void> _pickLanguage(BuildContext context) async {
    final s = context.read<AppState>();
    final lang = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            KanzRow(title: 'العربيه', chevron: false, onTap: () => Navigator.pop(ctx, 'ar'),
                trailing: s.language == 'ar' ? const Icon(Icons.check, color: KanzColors.cyan) : null),
            KanzRow(title: 'English', chevron: false, onTap: () => Navigator.pop(ctx, 'en'),
                trailing: s.language == 'en' ? const Icon(Icons.check, color: KanzColors.cyan) : null),
          ],
        ),
      ),
    );
    if (lang != null) s.setLanguage(lang);
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
