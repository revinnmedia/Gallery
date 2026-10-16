import 'dart:async';

import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';
import 'cloud_service.dart';

/// بيانات وهمية لمعاينة المتصفح فقط: تُظهر شكل الترتيب والأصدقاء والمحادثة
/// قبل ربط Firebase. لا تُستخدم أبداً في نسخة الجوال.
class DemoCloud {
  static const myUid = 'me';
  static const myCode = 'KNZ7Q2';

  String myName = 'أنت';
  bool signedIn = true;

  static const _people = <(String, String, int)>[
    ('u1', 'عبدالله', 48210),
    ('u2', 'مريم', 39875),
    ('u3', 'أبو أحمد', 31540),
    ('u4', 'نور', 27760),
    ('u5', 'يوسف', 22105),
    ('u6', 'فاطمة', 18930),
    ('u7', 'خالد', 15400),
    ('u8', 'ليلى', 12650),
    ('u9', 'عمر', 9875),
    ('u10', 'هدى', 7340),
    ('u11', 'سليمان', 5120),
    ('u12', 'آمنة', 3305),
  ];

  final _friends = <String>{'u2', 'u5', 'u9'};
  final _requests = <FriendRequest>[const FriendRequest(id: 'r1', fromUid: 'u4', fromName: 'نور')];
  final _friendsCtrl = StreamController<List<RankEntry>>.broadcast();
  final _requestsCtrl = StreamController<List<FriendRequest>>.broadcast();
  final _chats = <String, List<ChatMessage>>{};
  final _chatCtrls = <String, StreamController<List<ChatMessage>>>{};

  /// نسبة كل فترة من المجموع الكلي، مع اختلاف بسيط بين الأشخاص.
  static double _share(RankPeriod p, int i) => switch (p) {
    RankPeriod.day => 0.012 + (i % 4) * 0.004,
    RankPeriod.week => 0.07 + (i % 3) * 0.02,
    RankPeriod.month => 0.3 + (i % 5) * 0.05,
    RankPeriod.all => 1,
  };

  RankEntry _person(int i, RankPeriod p) {
    final (uid, name, total) = _people[i];
    return RankEntry(uid: uid, name: name, score: (total * _share(p, i)).round());
  }

  RankEntry _me(RankPeriod p, int myTotal) => RankEntry(
    uid: myUid,
    name: myName,
    score: (myTotal * (p == RankPeriod.all ? 1 : _share(p, 5))).round(),
  );

  List<RankEntry> world(RankPeriod p, int myTotal) =>
      [for (var i = 0; i < _people.length; i++) _person(i, p), _me(p, myTotal)]
        ..sort((a, b) => b.score.compareTo(a.score));

  List<RankEntry> friendsRanking(RankPeriod p, int myTotal) => [
    for (var i = 0; i < _people.length; i++)
      if (_friends.contains(_people[i].$1)) _person(i, p),
    _me(p, myTotal),
  ]..sort((a, b) => b.score.compareTo(a.score));

  List<RankEntry> get _friendList => [
    for (var i = 0; i < _people.length; i++)
      if (_friends.contains(_people[i].$1)) _person(i, RankPeriod.all),
  ];

  Stream<List<RankEntry>> friendsStream() async* {
    yield _friendList;
    yield* _friendsCtrl.stream;
  }

  Stream<List<FriendRequest>> requestsStream() async* {
    yield List.of(_requests);
    yield* _requestsCtrl.stream;
  }

  void accept(FriendRequest r) {
    _requests.removeWhere((x) => x.id == r.id);
    _friends.add(r.fromUid);
    _requestsCtrl.add(List.of(_requests));
    _friendsCtrl.add(_friendList);
  }

  void decline(FriendRequest r) {
    _requests.removeWhere((x) => x.id == r.id);
    _requestsCtrl.add(List.of(_requests));
  }

  void remove(String uid) {
    _friends.remove(uid);
    _friendsCtrl.add(_friendList);
  }

  List<ChatMessage> _chat(String uid) => _chats.putIfAbsent(uid, () {
    final now = DateTime.now();
    return [
      ChatMessage(
        from: uid,
        text: 'السلام عليكم، كم وصلت اليوم؟',
        at: now.subtract(const Duration(minutes: 42)),
      ),
      ChatMessage(
        from: myUid,
        text: 'وعليكم السلام، الحمد لله تجاوزت الألف',
        at: now.subtract(const Duration(minutes: 40)),
      ),
      ChatMessage(
        from: uid,
        text: 'ما شاء الله، الله يتقبل منا ومنكم',
        at: now.subtract(const Duration(minutes: 38)),
      ),
    ].reversed.toList();
  });

  Stream<List<ChatMessage>> messages(String uid) async* {
    final ctrl = _chatCtrls.putIfAbsent(uid, StreamController<List<ChatMessage>>.broadcast);
    yield List.of(_chat(uid));
    yield* ctrl.stream;
  }

  void send(String uid, String text) {
    final list = _chat(uid);
    list.insert(0, ChatMessage(from: myUid, text: text, at: DateTime.now()));
    _chatCtrls[uid]?.add(List.of(list));
    // رد تلقائي ليظهر شكل المحادثة.
    Timer(const Duration(milliseconds: 1400), () {
      list.insert(0, ChatMessage(from: uid, text: 'جزاك الله خيراً', at: DateTime.now()));
      _chatCtrls[uid]?.add(List.of(list));
    });
  }
}

/// شريط صغير تحت العنوان يوضّح أن البيانات تجريبية (في معاينة المتصفح فقط).
PreferredSizeWidget? demoNoteBar(CloudService cloud, String lang) {
  if (cloud.demo == null) return null;
  return PreferredSize(
    preferredSize: const Size.fromHeight(26),
    child: Container(
      height: 26,
      alignment: Alignment.center,
      color: KanzColors.gold.withValues(alpha: 0.18),
      child: Text(
        lang == 'ar' ? 'بيانات تجريبية للمعاينة فقط' : 'Demo data for preview only',
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    ),
  );
}
