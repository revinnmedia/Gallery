import 'package:flutter/material.dart';

import '../platform.dart';

import 'package:provider/provider.dart';

import '../l10n.dart';
import '../models.dart';
import '../services/cloud_service.dart';
import '../services/games_service.dart';
import '../theme.dart';
import '../widgets/kanz_ui.dart';

/// ترتيب أكثر الذاكرين: اليوم / الاسبوع / الشهر / الكل، عالمياً أو بين الأصدقاء.
class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  static const _periods = [
    RankPeriod.day,
    RankPeriod.week,
    RankPeriod.month,
    RankPeriod.all,
  ];
  int _period = 0;
  bool _friends = false;
  late Future<List<RankEntry>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final cloud = CloudService.instance;
    final p = _periods[_period];
    _future = cloud.flush().then(
      (_) => _friends ? cloud.friendsRanking(p) : cloud.worldRanking(p),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cloud = context.watch<CloudService>();
    const style = TextStyle(
      fontSize: 19,
      fontWeight: FontWeight.w300,
      color: Colors.white,
    );
    return KanzPage(
      title: tr(context, 'ranking'),
      showBack: true,
      action: IconButton(
        tooltip: tr(context, isIOS ? 'gameCenter' : 'playGames'),
        onPressed: GamesService.instance.showLeaderboard,
        icon: const Icon(
          Icons.sports_esports_outlined,
          color: Colors.white,
          size: 30,
        ),
      ),
      body: Column(
        children: [
          KanzTableHeader(
            cells: [tr(context, 'world'), tr(context, 'friends')],
            selected: _friends ? 1 : 0,
            onTap: (i) => setState(() {
              _friends = i == 1;
              _load();
            }),
          ),
          const SizedBox(height: 2),
          KanzTableHeader(
            cells: [
              tr(context, 'today'),
              tr(context, 'thisWeek'),
              tr(context, 'thisMonth'),
              tr(context, 'allTime'),
            ],
            selected: _period,
            onTap: (i) => setState(() {
              _period = i;
              _load();
            }),
          ),
          Expanded(
            child: FutureBuilder<List<RankEntry>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(
                    child: CircularProgressIndicator(color: KanzColors.cyan),
                  );
                }
                if (snap.hasError) {
                  debugPrint('Ranking error: ${snap.error}');
                  return Center(
                    child: Text(tr(context, 'error'), style: style),
                  );
                }
                final list = snap.data ?? [];
                if (list.isEmpty) {
                  return Center(
                    child: Text(tr(context, 'noOneYet'), style: style),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    setState(_load);
                    await _future;
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 16),
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final e = list[i];
                      final me = e.uid == cloud.user?.uid;
                      final medal = switch (i) {
                        0 => KanzColors.gold,
                        1 => const Color(0xFFC9D3D8),
                        2 => const Color(0xFFCD8B5A),
                        _ => null,
                      };
                      return Container(
                        height: 50,
                        color: me
                            ? KanzColors.cardBlue.withValues(alpha: 0.6)
                            : null,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 40,
                              child: medal != null
                                  ? Icon(
                                      Icons.emoji_events,
                                      color: medal,
                                      size: 28,
                                    )
                                  : Text(
                                      '${i + 1}',
                                      style: style,
                                      textAlign: TextAlign.center,
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                me
                                    ? '${e.name} (${tr(context, 'you')})'
                                    : e.name,
                                style: style,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${e.score}',
                              style: style.copyWith(color: KanzColors.cyan),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
