import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/defaults.dart';
import '../l10n.dart';
import '../models.dart';
import '../services/notification_service.dart';
import '../state/app_state.dart';
import '../theme.dart';

/// التذكير: تذكير تلقائي كل عدد من الدقائق، وتذكير مخصص لأذكار محددة.
class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  /// يطلب الإذن قبل تفعيل أي تذكير. يرجع false إذا رفض المستخدم.
  static Future<bool> _ensurePermission(BuildContext context) async {
    final lang = context.read<AppState>().language;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await NotificationService.instance.requestPermission();
    if (!ok) {
      messenger.showSnackBar(SnackBar(content: Text(trLang(lang, 'notifPermissionDenied'))));
    }
    return ok;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: Text(tr(context, 'reminders'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context),
        icon: const Icon(Icons.alarm_add),
        label: Text(tr(context, 'addReminder')),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.autorenew, color: KanzColors.primary),
                  title: Text(tr(context, 'autoReminder')),
                  value: s.autoReminder,
                  onChanged: (v) async {
                    if (v && !await _ensurePermission(context)) return;
                    await s.updateReminders(auto: v);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.schedule),
                  title: Text(tr(context, 'notifyEvery')),
                  trailing: _MinutesChip(
                    minutes: s.autoInterval,
                    onTap: () async {
                      final m = await _askMinutes(context, s.autoInterval);
                      if (m != null) await s.updateReminders(interval: m);
                    },
                  ),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.volume_up_outlined, color: KanzColors.primary),
                  title: Text(tr(context, 'reminderSound')),
                  value: s.reminderSound,
                  onChanged: (v) => s.updateReminders(sound: v),
                ),
              ],
            ),
          ),
          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.tune, color: KanzColors.primary),
              title: Text(tr(context, 'customReminders')),
              subtitle: Text(tr(context, 'reminderHint'), style: const TextStyle(color: Colors.white70)),
              value: s.customReminderOn,
              onChanged: (v) async {
                if (v && !await _ensurePermission(context)) return;
                await s.updateReminders(custom: v);
              },
            ),
          ),
          ...s.customReminders.map(
            (r) => Card(
              child: ListTile(
                leading: const Icon(Icons.alarm),
                title: Text(r.text, style: const TextStyle(fontSize: 18)),
                subtitle: Text(
                  '${tr(context, 'every')} ${fmtNum(context, r.intervalMinutes)} ${tr(context, 'minutes')}',
                  style: const TextStyle(color: Colors.white70),
                ),
                trailing: IconButton(
                  tooltip: tr(context, 'delete'),
                  icon: const Icon(Icons.delete_outline, color: Colors.white70),
                  onPressed: () => s.deleteCustomReminder(r),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _add(BuildContext context) async {
    final s = context.read<AppState>();
    final options = <ReminderPhrase>[
      ...s.dhikrs.map((d) => ReminderPhrase(d.text, d.sound)),
      ...reminderPhrases.where((p) => !s.dhikrs.any((d) => d.text == p.text)),
    ];
    final picked = await showModalBottomSheet<ReminderPhrase>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
          child: ListView(
            shrinkWrap: true,
            children: options
                .map((p) => ListTile(
                      title: Text(p.text, style: const TextStyle(fontSize: 18)),
                      onTap: () => Navigator.pop(ctx, p),
                    ))
                .toList(),
          ),
        ),
      ),
    );
    if (picked == null || !context.mounted) return;
    final minutes = await _askMinutes(context, 60);
    if (minutes == null || !context.mounted) return;
    if (!await _ensurePermission(context)) return;
    await s.addCustomReminder(picked.text, picked.sound, minutes);
  }

  Future<int?> _askMinutes(BuildContext context, int initial) async {
    final ctrl = TextEditingController(text: '$initial');
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr(context, 'notifyEvery')),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 28),
          decoration: InputDecoration(suffixText: tr(context, 'minutes')),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr(context, 'cancel'))),
          TextButton(
            onPressed: () {
              final v = int.tryParse(ctrl.text);
              if (v == null) return;
              Navigator.pop(ctx, v.clamp(NotificationService.minInterval, 24 * 60));
            },
            child: Text(tr(context, 'save')),
          ),
        ],
      ),
    );
    ctrl.dispose();
    return result;
  }
}

class _MinutesChip extends StatelessWidget {
  const _MinutesChip({required this.minutes, required this.onTap});
  final int minutes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: KanzColors.inputBox,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '${fmtNum(context, minutes)} ${tr(context, 'minutes')}',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
          ),
        ),
      );
}
