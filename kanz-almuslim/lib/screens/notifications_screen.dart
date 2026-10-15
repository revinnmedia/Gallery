import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/defaults.dart';
import '../l10n.dart';
import '../models.dart';
import '../services/notification_service.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/kanz_ui.dart';
import 'support_screen.dart';

/// شاشة الإشعارات بنفس صفوف النسخة الأصلية:
/// تذكير تلقائي، تنبيه كل [ ] دقيقه، اختر نوع و وقت التذكير،
/// تذكير مخصص، اضافه الاذكار / تحرير الاذكار.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _editing = false;

  Future<bool> _ensurePermission() async {
    final lang = context.read<AppState>().language;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await NotificationService.instance.requestPermission();
    if (!ok) messenger.showSnackBar(SnackBar(content: Text(trLang(lang, 'notifPermissionDenied'))));
    return ok;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    const sep = KanzColors.separatorCyan;
    const text = TextStyle(fontSize: 21, fontWeight: FontWeight.w300, color: Colors.white);

    return KanzPage(
      title: tr(context, 'tabNotifications'),
      onHeart: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SupportScreen())),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _Line(),
          KanzRow(
            title: tr(context, 'autoReminder'),
            separatorColor: sep,
            indentSeparator: false,
            trailing: KanzSwitch(
              value: s.autoReminder,
              onChanged: (v) async {
                if (v && !await _ensurePermission()) return;
                await s.updateReminders(auto: v);
              },
            ),
          ),
          _Bordered(
            child: SizedBox(
              height: 64,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(start: 26, end: 40),
                child: Row(
                  children: [
                    const Icon(Icons.schedule, color: Colors.white, size: 40),
                    const SizedBox(width: 14),
                    Text(tr(context, 'notifyEvery'), style: text),
                    const SizedBox(width: 28),
                    GestureDetector(
                      onTap: () => _editInterval(context),
                      child: Container(
                        width: 80,
                        height: 34,
                        decoration: BoxDecoration(
                          color: KanzColors.inputBox,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        alignment: Alignment.center,
                        child: Text('${s.autoInterval}', style: const TextStyle(fontSize: 24, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 18),
                    Text(tr(context, 'minute'), style: text),
                  ],
                ),
              ),
            ),
          ),
          _Bordered(
            child: SizedBox(
              height: 64,
              child: Center(child: Text(tr(context, 'chooseType'), style: text)),
            ),
          ),
          KanzRow(
            title: tr(context, 'customReminder'),
            separatorColor: sep,
            indentSeparator: false,
            trailing: KanzSwitch(
              value: s.customReminderOn,
              onChanged: (v) async {
                if (v && !await _ensurePermission()) return;
                await s.updateReminders(custom: v);
              },
            ),
          ),
          _Bordered(
            child: SizedBox(
              height: 60,
              child: Row(
                children: [
                  Expanded(
                    child: _CircleAction(
                      icon: Icons.add,
                      label: tr(context, 'addAdhkar'),
                      onTap: () => _add(context),
                    ),
                  ),
                  Expanded(
                    child: _CircleAction(
                      icon: _editing ? Icons.check : Icons.remove,
                      label: _editing ? tr(context, 'done') : tr(context, 'editAdhkar'),
                      onTap: () => setState(() => _editing = !_editing),
                    ),
                  ),
                ],
              ),
            ),
          ),
          for (final r in s.customReminders)
            _Bordered(
              child: SizedBox(
                height: 58,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Row(
                    children: [
                      if (_editing)
                        IconButton(
                          onPressed: () => s.deleteCustomReminder(r),
                          icon: const Icon(Icons.remove_circle, color: Colors.redAccent),
                        ),
                      Expanded(child: Text(r.text, style: text, maxLines: 1, overflow: TextOverflow.ellipsis)),
                      Text('${tr(context, 'every')} ${r.intervalMinutes} ${tr(context, 'minute')}',
                          style: text.copyWith(fontSize: 17)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _editInterval(BuildContext context) async {
    final s = context.read<AppState>();
    final minutes = await _askMinutes(context, s.autoInterval);
    if (minutes != null) await s.updateReminders(interval: minutes);
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
                .map((p) => KanzRow(
                      title: p.text,
                      chevron: false,
                      height: 54,
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
    if (!await _ensurePermission()) return;
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
          decoration: InputDecoration(suffixText: tr(context, 'minute')),
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

class _Line extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(height: 1, color: KanzColors.separatorCyan);
}

class _Bordered extends StatelessWidget {
  const _Bordered({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
        children: [child, Container(height: 1, color: KanzColors.separatorCyan)],
      );
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.only(start: 18),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white70, width: 1.2),
                ),
                child: Icon(icon, color: Colors.white70, size: 30, weight: 200),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(label,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w300, color: Colors.white)),
              ),
            ],
          ),
        ),
      );
}
