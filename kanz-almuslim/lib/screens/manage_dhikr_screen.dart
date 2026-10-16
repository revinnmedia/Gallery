import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';

/// إضافة وتعديل وحذف وترتيب الأذكار.
class ManageDhikrScreen extends StatelessWidget {
  const ManageDhikrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: Text(tr(context, 'manageDhikr'))),
      // زر رجوع واضح أسفل الشاشة بجانب الإضافة (لا يعتمد على شريط العنوان فقط).
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: KanzColors.cardBlue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                  ),
                  onPressed: () => _edit(context, null),
                  icon: const Icon(Icons.add),
                  label: Text(tr(context, 'addDhikr')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: KanzColors.cyan),
                    minimumSize: const Size.fromHeight(52),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.check),
                  label: Text(tr(context, 'done')),
                ),
              ),
            ],
          ),
        ),
      ),
      body: ReorderableListView.builder(
        padding: const EdgeInsets.only(bottom: 16, top: 8),
        itemCount: state.dhikrs.length,
        onReorderItem: state.reorderDhikr,
        itemBuilder: (context, i) {
          final d = state.dhikrs[i];
          final selected = i == state.currentIndex;
          return Card(
            key: ValueKey(d.id),
            child: ListTile(
              contentPadding: const EdgeInsetsDirectional.only(start: 16, end: 8),
              leading: CircleAvatar(
                backgroundColor: selected ? KanzColors.cyan : KanzColors.cardBlue,
                foregroundColor: selected ? KanzColors.bgTop : Colors.white,
                child: Text(fmtNum(context, d.target), style: const TextStyle(fontSize: 13)),
              ),
              title: Text(
                d.text,
                style: const TextStyle(fontSize: 19, height: 1.6),
              ),
              onTap: () {
                state.selectDhikr(i);
                Navigator.of(context).pop();
              },
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: tr(context, 'editDhikr'),
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _edit(context, d),
                  ),
                  IconButton(
                    tooltip: tr(context, 'delete'),
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _delete(context, d),
                  ),
                  ReorderableDragStartListener(
                    index: i,
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.drag_handle),
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
    final state = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(d.text),
        content: Text(tr(context, 'deleteConfirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr(context, 'cancel'))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr(context, 'delete'))),
        ],
      ),
    );
    if (ok != true) return;
    if (!state.deleteDhikr(d)) {
      messenger.showSnackBar(SnackBar(content: Text(trLang(state.language, 'cantDeleteLast'))));
    }
  }

  Future<void> _edit(BuildContext context, Dhikr? d) async {
    final state = context.read<AppState>();
    final text = TextEditingController(text: d?.text ?? '');
    var target = d?.target ?? 33;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                tr(context, d == null ? 'addDhikr' : 'editDhikr'),
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: text,
                autofocus: true,
                maxLength: 80,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22),
                decoration: InputDecoration(
                  labelText: tr(context, 'dhikrText'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 8),
              Text(tr(context, 'vibrateEvery')),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [10, 33, 99, 100, 1000].map((n) {
                  return ChoiceChip(
                    label: Text(fmtNum(context, n)),
                    selected: target == n,
                    onSelected: (_) => setSheet(() => target = n),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  if (text.text.trim().isEmpty) return;
                  Navigator.pop(ctx, true);
                },
                child: Text(tr(context, 'save')),
              ),
            ],
          ),
        ),
      ),
    );
    if (saved == true) {
      if (d == null) {
        state.addDhikr(text.text, target);
      } else {
        state.updateDhikr(d, text.text, target);
      }
    }
    text.dispose();
  }
}
