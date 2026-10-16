import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n.dart';
import '../services/cloud_service.dart';
import '../state/app_state.dart';
import '../widgets/kanz_ui.dart';

/// الحساب: تعديل الاسم، تسجيل الخروج، حذف الحساب.
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cloud = context.watch<CloudService>();
    if (!cloud.signedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) Navigator.of(context).maybePop();
      });
    }
    return KanzPage(
      title: tr(context, 'account'),
      showBack: true,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          KanzRow(
            icon: const Icon(
              Icons.person_outline,
              color: Colors.white,
              size: 40,
            ),
            title: cloud.displayName,
            subtitle: tr(context, 'displayName'),
            trailing: const Icon(Icons.edit_outlined, color: Colors.white70),
            onTap: () => _editName(context, cloud),
          ),
          KanzRow(
            icon: const Icon(Icons.logout, color: Colors.white, size: 36),
            title: tr(context, 'signOut'),
            chevron: false,
            onTap: cloud.signOut,
          ),
          KanzRow(
            icon: const Icon(
              Icons.delete_forever_outlined,
              color: Colors.redAccent,
              size: 38,
            ),
            title: tr(context, 'deleteAccount'),
            chevron: false,
            onTap: () => _delete(context, cloud),
          ),
        ],
      ),
    );
  }

  Future<void> _editName(BuildContext context, CloudService cloud) async {
    final ctrl = TextEditingController(text: cloud.displayName);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr(context, 'displayName')),
        content: TextField(controller: ctrl, autofocus: true, maxLength: 30),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr(context, 'cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: Text(tr(context, 'save')),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (name != null) await cloud.updateName(name);
  }

  Future<void> _delete(BuildContext context, CloudService cloud) async {
    final lang = context.read<AppState>().language;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr(context, 'deleteAccount')),
        content: Text(tr(context, 'deleteAccountConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr(context, 'cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              tr(context, 'delete'),
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await cloud.deleteAccount();
    } catch (e) {
      debugPrint('Delete account failed: $e');
      messenger.showSnackBar(SnackBar(content: Text(trLang(lang, 'error'))));
    }
  }
}
