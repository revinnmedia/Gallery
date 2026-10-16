import 'package:flutter/material.dart';

import '../platform.dart';

import 'package:provider/provider.dart';

import '../l10n.dart';
import '../services/cloud_service.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/kanz_ui.dart';

/// نافذة تسجيل الدخول بـ Apple أو Google.
Future<void> showSignInSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => const _SignInSheet(),
  );
}

class _SignInSheet extends StatefulWidget {
  const _SignInSheet();

  @override
  State<_SignInSheet> createState() => _SignInSheetState();
}

class _SignInSheetState extends State<_SignInSheet> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final lang = context.read<AppState>().language;
    try {
      await action();
      nav.pop();
    } catch (e) {
      debugPrint('Sign-in failed: $e');
      if (mounted) setState(() => _busy = false);
      // إلغاء المستخدم للعملية ليس خطأ يستحق رسالة.
      if (!e.toString().toLowerCase().contains('cancel')) {
        messenger.showSnackBar(SnackBar(content: Text(trLang(lang, 'error'))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cloud = CloudService.instance;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    );
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: KanzLogo(size: 64)),
            const SizedBox(height: 14),
            Text(
              tr(context, 'signInToCompete'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w300,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 22),
            if (_busy)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(color: KanzColors.cyan),
                ),
              )
            else ...[
              if (isIOS) ...[
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(48, 52),
                    shape: shape,
                  ),
                  onPressed: () => _run(cloud.signInWithApple),
                  icon: const Icon(Icons.apple, size: 26),
                  label: Text(
                    tr(context, 'signInApple'),
                    style: const TextStyle(fontSize: 17),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: KanzColors.cardBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(48, 52),
                  shape: shape,
                ),
                onPressed: () => _run(cloud.signInWithGoogle),
                icon: const Text(
                  'G',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                label: Text(
                  tr(context, 'signInGoogle'),
                  style: const TextStyle(fontSize: 17),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
