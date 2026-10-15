import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n.dart';
import '../models.dart';
import '../services/cloud_service.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/avatar.dart';
import '../widgets/kanz_ui.dart';
import 'chat_screen.dart';

/// الأصدقاء: رمز الصداقة، إضافة صديق، الطلبات، والمحادثة.
class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  late final Stream<List<FriendRequest>> _requests = CloudService.instance.incomingRequests();
  late final Stream<List<RankEntry>> _friends = CloudService.instance.friendsStream();

  @override
  Widget build(BuildContext context) {
    final cloud = context.watch<CloudService>();
    const style = TextStyle(fontSize: 19, fontWeight: FontWeight.w300, color: Colors.white);
    return KanzPage(
      title: tr(context, 'friends'),
      showBack: true,
      action: IconButton(
        tooltip: tr(context, 'addFriend'),
        onPressed: () => _addFriend(context),
        icon: const Icon(Icons.person_add_alt_1_outlined, color: Colors.white, size: 30),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(color: KanzColors.cardBlue, borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr(context, 'myCode'), style: style.copyWith(fontSize: 14)),
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(cloud.friendCode ?? '······',
                            style: const TextStyle(fontSize: 28, letterSpacing: 6, color: Colors.white)),
                      ),
                    ],
                  ),
                ),
                if (cloud.friendCode != null)
                  IconButton(
                    onPressed: () => Clipboard.setData(ClipboardData(text: cloud.friendCode!)),
                    icon: const Icon(Icons.copy, color: Colors.white),
                  ),
              ],
            ),
          ),
          StreamBuilder<List<FriendRequest>>(
            stream: _requests,
            builder: (context, snap) {
              final reqs = snap.data ?? [];
              if (reqs.isEmpty) return const SizedBox.shrink();
              return Column(
                children: [
                  KanzTableHeader(cells: [tr(context, 'requests')]),
                  for (final r in reqs)
                    KanzRow(
                      icon: Avatar(name: r.fromName),
                      title: r.fromName,
                      chevron: false,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => cloud.declineRequest(r),
                            icon: const Icon(Icons.close, color: Colors.white70),
                          ),
                          IconButton(
                            onPressed: () => cloud.acceptRequest(r),
                            icon: const Icon(Icons.check_circle, color: KanzColors.switchGreen, size: 32),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
          StreamBuilder<List<RankEntry>>(
            stream: _friends,
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(30),
                  child: Center(child: CircularProgressIndicator(color: KanzColors.cyan)),
                );
              }
              final friends = snap.data!;
              if (friends.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(30),
                  child: Text(tr(context, 'noFriends'), style: style, textAlign: TextAlign.center),
                );
              }
              return Column(
                children: [
                  for (final f in friends)
                    GestureDetector(
                      onLongPress: () => _confirmRemove(context, f),
                      child: KanzRow(
                        icon: Avatar(name: f.name, url: f.photoUrl),
                        title: f.name,
                        subtitle: '${f.score}',
                        onTap: () => Navigator.of(context)
                            .push(MaterialPageRoute(builder: (_) => ChatScreen(friend: f))),
                      ),
                    ),
                ],
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
          style: const TextStyle(fontSize: 24, letterSpacing: 6),
          decoration: InputDecoration(hintText: tr(context, 'enterCode')),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr(context, 'cancel'))),
          TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: Text(tr(context, 'send'))),
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
