import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n.dart';
import '../platform.dart';
import '../models.dart';
import '../services/cloud_service.dart';
import '../services/games_service.dart';
import '../theme.dart';
import '../widgets/avatar.dart';
import 'sign_in_sheet.dart';

/// ترتيب أكثر الذاكرين: اليوم / الأسبوع / الشهر / الكل، عالمياً أو بين الأصدقاء.
class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  RankPeriod _period = RankPeriod.day;
  bool _friendsOnly = false;
  Future<List<RankEntry>>? _future;
  String? _loadedFor;

  void _reload() {
    final cloud = CloudService.instance;
    setState(() {
      _future = cloud.flush().then((_) =>
          _friendsOnly ? cloud.friendsRanking(_period) : cloud.worldRanking(_period));
    });
  }

  @override
  Widget build(BuildContext context) {
    final cloud = context.watch<CloudService>();
    if (cloud.signedIn && _loadedFor != cloud.user!.uid) {
      _loadedFor = cloud.user!.uid;
      WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, 'tabRanking')),
        actions: [
          if (cloud.available)
            IconButton(
              tooltip: tr(context, isIOS ? 'gameCenter' : 'playGames'),
              icon: const Icon(Icons.sports_esports_outlined),
              onPressed: GamesService.instance.showLeaderboard,
            ),
        ],
      ),
      body: !cloud.available
          // بدون سيرفر: الترتيب عبر Game Center / Play Games.
          ? _Message(
              icon: Icons.emoji_events_outlined,
              text: tr(context, 'signInToCompete'),
              action: FilledButton.icon(
                onPressed: GamesService.instance.showLeaderboard,
                icon: const Icon(Icons.sports_esports_outlined),
                label: Text(tr(context, isIOS ? 'gameCenter' : 'playGames')),
              ),
            )
          : !cloud.signedIn
              ? _Message(
                  icon: Icons.emoji_events_outlined,
                  text: tr(context, 'signInToCompete'),
                  action: FilledButton(
                    onPressed: () => showSignInSheet(context),
                    child: Text(tr(context, 'signIn')),
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: SegmentedButton<bool>(
                        segments: [
                          ButtonSegment(value: false, label: Text(tr(context, 'world')), icon: const Icon(Icons.public)),
                          ButtonSegment(value: true, label: Text(tr(context, 'friends')), icon: const Icon(Icons.people)),
                        ],
                        selected: {_friendsOnly},
                        onSelectionChanged: (s) {
                          _friendsOnly = s.first;
                          _reload();
                        },
                      ),
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Row(
                        children: [
                          for (final (p, key) in [
                            (RankPeriod.day, 'today'),
                            (RankPeriod.week, 'thisWeek'),
                            (RankPeriod.month, 'thisMonth'),
                            (RankPeriod.all, 'allTime'),
                          ])
                            Padding(
                              padding: const EdgeInsetsDirectional.only(end: 8),
                              child: ChoiceChip(
                                label: Text(tr(context, key)),
                                selected: _period == p,
                                onSelected: (_) {
                                  _period = p;
                                  _reload();
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          _reload();
                          await _future;
                        },
                        child: FutureBuilder<List<RankEntry>>(
                          future: _future,
                          builder: (context, snap) {
                            if (snap.connectionState != ConnectionState.done) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            if (snap.hasError) {
                              debugPrint('Ranking error: ${snap.error}');
                              return ListView(children: [
                                _Message(icon: Icons.error_outline, text: tr(context, 'error')),
                              ]);
                            }
                            final list = snap.data ?? [];
                            if (list.isEmpty) {
                              return ListView(children: [
                                _Message(icon: Icons.emoji_events_outlined, text: tr(context, 'noOneYet')),
                              ]);
                            }
                            return ListView.builder(
                              padding: const EdgeInsets.only(bottom: 24, top: 4),
                              itemCount: list.length,
                              itemBuilder: (_, i) => _RankTile(
                                rank: i + 1,
                                entry: list[i],
                                isMe: list[i].uid == cloud.user!.uid,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _RankTile extends StatelessWidget {
  const _RankTile({required this.rank, required this.entry, required this.isMe});
  final int rank;
  final RankEntry entry;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final medal = switch (rank) {
      1 => const Color(0xFFE6B422),
      2 => const Color(0xFFB8C4CC),
      3 => const Color(0xFFCD8B5A),
      _ => null,
    };
    return Card(
      color: isMe ? KanzColors.mint.withValues(alpha: 0.18) : null,
      child: ListTile(
        leading: SizedBox(
          width: 76,
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: medal != null
                    ? Icon(Icons.emoji_events, color: medal)
                    : Text(fmtNum(context, rank),
                        textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 8),
              Avatar(name: entry.name, url: entry.photoUrl),
            ],
          ),
        ),
        title: Text(isMe ? '${entry.name} (${tr(context, 'you')})' : entry.name,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Text(
          fmtNum(context, entry.score),
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: KanzColors.cyan),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, this.action});
  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: KanzColors.paleAqua),
            const SizedBox(height: 16),
            Text(text, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}
