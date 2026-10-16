import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n.dart';
import '../models.dart';
import '../services/cloud_service.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/avatar.dart';
import 'chat_screen.dart';
import 'sign_in_sheet.dart';

/// الأصدقاء: رمز الصداقة، إضافة صديق، الطلبات، والمحادثة.
class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cloud = context.watch<CloudService>();
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, 'tabFriends')),
        actions: [
          if (cloud.signedIn)
            IconButton(
              tooltip: tr(context, 'addFriend'),
              icon: const Icon(Icons.person_add_alt_1),
              onPressed: () => _addFriend(context),
            ),
        ],
      ),
      body: !cloud.available
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.people_outline, size: 64, color: KanzColors.paleAqua),
                    const SizedBox(height: 16),
                    Text(tr(context, 'noFriends'),
                        textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(tr(context, 'cloudOff'), style: const TextStyle(color: Colors.white60)),
                  ],
                ),
              ),
            )
          : !cloud.signedIn
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.people_outline, size: 64, color: KanzColors.paleAqua),
                        const SizedBox(height: 16),
                        Text(tr(context, 'noFriends'),
                            textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: () => showSignInSheet(context),
                          child: Text(tr(context, 'signIn')),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    _CodeCard(code: cloud.friendCode),
                    StreamBuilder<List<FriendRequest>>(
                      stream: cloud.incomingRequests(),
                      builder: (context, snap) {
                        final reqs = snap.data ?? [];
                        if (reqs.isEmpty) return const SizedBox.shrink();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionTitle(tr(context, 'requests')),
                            ...reqs.map((r) => Card(
                                  child: ListTile(
                                    leading: Avatar(name: r.fromName),
                                    title: Text(r.fromName),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          tooltip: tr(context, 'decline'),
                                          icon: const Icon(Icons.close),
                                          onPressed: () => cloud.declineRequest(r),
                                        ),
                                        IconButton.filled(
                                          tooltip: tr(context, 'accept'),
                                          style: IconButton.styleFrom(backgroundColor: KanzColors.switchGreen),
                                          icon: const Icon(Icons.check),
                                          onPressed: () => cloud.acceptRequest(r),
                                        ),
                                      ],
                                    ),
                                  ),
                                )),
                          ],
                        );
                      },
                    ),
                    _SectionTitle(tr(context, 'friends')),
                    StreamBuilder<List<RankEntry>>(
                      stream: cloud.friendsStream(),
                      builder: (context, snap) {
                        if (!snap.hasData) {
                          return const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final friends = snap.data!;
                        if (friends.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(tr(context, 'noFriends'), textAlign: TextAlign.center),
                          );
                        }
                        return Column(
                          children: friends
                              .map((f) => Card(
                                    child: ListTile(
                                      leading: Avatar(name: f.name, url: f.photoUrl),
                                      title: Text(f.name),
                                      subtitle: Text('${tr(context, 'total')}: ${fmtNum(context, f.score)}'),
                                      trailing: const Icon(Icons.chat_bubble_outline),
                                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                                        builder: (_) => ChatScreen(friend: f),
                                      )),
                                      onLongPress: () => _confirmRemove(context, f),
                                    ),
                                  ))
                              .toList(),
                        );
                      },
                    ),
                  ],
                ),
    );
  }

  Future<void> _confirmRemove(BuildContext context, RankEntry f) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(f.name),
        content: Text(tr(context, 'removeFriend')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr(context, 'cancel'))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr(context, 'removeFriend'))),
        ],
      ),
    );
    if (ok == true) await CloudService.instance.removeFriend(f.uid);
  }

  Future<void> _addFriend(BuildContext context) async {
    final lang = context.read<AppState>().language;
    final messenger = ScaffoldMessenger.of(context);
    final ctrl = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr(context, 'addFriend')),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          textAlign: TextAlign.center,
          maxLength: 6,
          style: const TextStyle(fontSize: 24, letterSpacing: 6, fontWeight: FontWeight.w700),
          decoration: InputDecoration(hintText: tr(context, 'enterCode')),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr(context, 'cancel'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: Text(tr(context, 'send'))),
        ],
      ),
    );
    ctrl.dispose();
    if (code == null || code.trim().isEmpty) return;
    try {
      final ok = await CloudService.instance.sendFriendRequest(code);
      messenger.showSnackBar(SnackBar(content: Text(trLang(lang, ok ? 'requestSent' : 'codeNotFound'))));
    } catch (e) {
      debugPrint('Friend request failed: $e');
      messenger.showSnackBar(SnackBar(content: Text(trLang(lang, 'error'))));
    }
  }
}

class _CodeCard extends StatelessWidget {
  const _CodeCard({required this.code});
  final String? code;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: KanzColors.cardStrong,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: KanzColors.cyan.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr(context, 'myCode'), style: TextStyle(color: Colors.white.withValues(alpha: 0.8))),
                const SizedBox(height: 6),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    code ?? '······',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      letterSpacing: 6,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (code != null)
            IconButton(
              color: Colors.white,
              icon: const Icon(Icons.copy),
              onPressed: () => Clipboard.setData(ClipboardData(text: code!)),
            ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
        child: Text(text, style: Theme.of(context).textTheme.titleMedium),
      );
}
