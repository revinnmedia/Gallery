import 'package:flutter/foundation.dart';

import '../platform.dart';

import 'package:games_services/games_services.dart';

/// ربط اختياري مع Game Center (iOS) و Google Play Games (Android).
///
/// المعرّفات أدناه يجب إنشاؤها بنفس الأسماء في App Store Connect
/// و Google Play Console (انظر docs/SETUP.md). إذا لم تُنشأ بعد،
/// تفشل الاستدعاءات بهدوء ولا تؤثر على التطبيق.
class GamesService {
  GamesService._();
  static final GamesService instance = GamesService._();

  static const iosLeaderboardId = 'kanz_total_tasbeeh';
  // يُنسخ من Play Console بعد إنشاء لوحة الصدارة (يبدأ عادة بـ CgkI...).
  static const androidLeaderboardId = '';

  static const _milestones = <int, (String ios, String android)>{
    100: ('kanz_first_100', ''),
    1000: ('kanz_first_1000', ''),
    10000: ('kanz_first_10000', ''),
    100000: ('kanz_first_100000', ''),
  };

  bool _signedIn = false;
  bool get signedIn => _signedIn;

  bool get _supported =>
      isIOS || (isAndroid && androidLeaderboardId.isNotEmpty);

  Future<void> signIn() async {
    if (!_supported) return;
    try {
      await GamesServices.signIn();
      _signedIn = await GamesServices.isSignedIn;
    } catch (e) {
      debugPrint('Games sign-in skipped: $e');
    }
  }

  Future<void> submitTotal(int total) async {
    if (!_signedIn) return;
    try {
      await GamesServices.submitScore(
        score: Score(
          iOSLeaderboardID: iosLeaderboardId,
          androidLeaderboardID: androidLeaderboardId,
          value: total,
        ),
      );
      for (final entry in _milestones.entries) {
        if (total >= entry.key) {
          final (ios, android) = entry.value;
          if (isAndroid && android.isEmpty) continue;
          await GamesServices.unlock(
            achievement: Achievement(iOSID: ios, androidID: android),
          );
        }
      }
    } catch (e) {
      debugPrint('Games submit skipped: $e');
    }
  }

  Future<void> showLeaderboard() async {
    if (!_signedIn) await signIn();
    if (!_signedIn) return;
    try {
      await GamesServices.showLeaderboards(
        iOSLeaderboardID: iosLeaderboardId,
        androidLeaderboardID: androidLeaderboardId,
      );
    } catch (e) {
      debugPrint('Show leaderboard failed: $e');
    }
  }
}
