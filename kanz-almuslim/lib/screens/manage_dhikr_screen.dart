import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/kanz_ui.dart';

/// إضافة وتعديل وحذف وترتيب التسابيح.
class ManageDhikrScreen extends StatelessWidget {
  const ManageDhikrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return KanzPage(
      title: tr(context, 'manageDhikr'),
      showBack: true,
      action: IconButton(
        tooltip: tr(context, 'addDhikr'),
        onPressed: () => _edit(context, null),
        icon: const Icon(
          Icons.add_circle_outline,
          color: Colors.white,
          size: 32,
        ),
      ),
      body: ReorderableListView.builder(
        padding: EdgeInsets.zero,
        buildDefaultDragHandles: false,
        itemCount: s.dhikrs.length,
        onReorderItem: s.reorderDhikr,
        itemBuilder: (context, i) {
          final d = s.dhikrs[i];
          return Container(
            key: ValueKey(d.id),
            color: i == s.currentIndex
                ? KanzColors.cardBlue.withValues(alpha: 0.5)
                : Colors.transparent,
            child: KanzRow(
              title: d.text,
              subtitle: '${d.target}',
              chevron: false,
              indentSeparator: false,
              onTap: () {
                s.selectDhikr(i);
                Navigator.of(context).pop();
              },
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => _edit(context, d),
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: Colors.white70,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _delete(context, d),
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      color: Colors.white70,
                    ),
                  ),
                  ReorderableDragStartListener(
                    index: i,
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.drag_handle, color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _delete(BuildContext context, Dhikr d) async {
    final s = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(d.text),
        content: Text(tr(context, 'deleteConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr(context, 'cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr(context, 'delete')),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (!s.deleteDhikr(d)) {
      messenger.showSnackBar(
        SnackBar(content: Text(trLang(s.language, 'cantDeleteLast'))),
      );
    }
  }

  Future<void> _edit(BuildContext context, Dhikr? d) async {
    final s = context.read<AppState>();
    final text = TextEditingController(text: d?.text ?? '');
    var target = d?.target ?? 33;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            0,
            24,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                tr(context, d == null ? 'addDhikr' : 'editDhikr'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, color: Colors.white),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: text,
                autofocus: true,
                maxLength: 80,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, color: Colors.white),
                decoration: InputDecoration(hintText: tr(context, 'dhikrText')),
              ),
              const SizedBox(height: 8),
              Text(
                tr(context, 'cycleOf'),
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                alignment: WrapAlignment.center,
                children: [33, 99, 100, 1000].map((n) {
                  final sel = target == n;
                  return ChoiceChip(
                    label: Text('$n'),
                    selected: sel,
                    selectedColor: KanzColors.inputBox,
                    backgroundColor: KanzColors.cardBlue,
                    labelStyle: const TextStyle(color: Colors.white),
                    onSelected: (_) => setSheet(() => target = n),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: KanzColors.restoreButton,
                  minimumSize: const Size(48, 50),
                  shape: const RoundedRectangleBorder(),
                ),
                onPressed: () {
                  if (text.text.trim().isEmpty) return;
                  Navigator.pop(ctx, true);
                },
                child: Text(
                  tr(context, 'save'),
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (saved == true) {
      if (d == null) {
        s.addDhikr(text.text, target);
      } else {
        s.updateDhikr(d, text.text, target);
      }
    }
    text.dispose();
  }
}
