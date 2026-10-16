import 'dart:async';

import '../platform.dart';

import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models.dart';
import 'demo_cloud.dart';

enum RankPeriod { day, week, month, all }

class FriendRequest {
  const FriendRequest({required this.id, required this.fromUid, required this.fromName, this.message = ''});
  final String id;
  final String fromUid;
  final String fromName;

  /// رسالة دعوة المنافسة (آية قرآنية وكلمة اختيارية).
  final String message;
}

class ChatMessage {
  const ChatMessage({required this.from, required this.text, required this.at});
  final String from;
  final String text;
  final DateTime at;
}

/// كل ما يخص السيرفر (Firebase): الدخول، الترتيب، الأصدقاء، المحادثة.
///
/// التطبيق يعمل بالكامل بدون Firebase (التسبيح والسجل والتذكير محلية).
/// إذا لم تُضف ملفات إعداد Firebase بعد، تبقى [available] = false
/// وتُخفى ميزات الترتيب والأصدقاء بهدوء.
class CloudService extends ChangeNotifier {
  CloudService._();
  static final CloudService instance = CloudService._();

  bool available = false;
  User? user;
  Map<String, dynamic>? profile;

  FirebaseFirestore get _db => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  int _pending = 0;
  Timer? _flushTimer;
  StreamSubscription<User?>? _authSub;

  /// معاينة المتصفح: بيانات وهمية لعرض شكل الترتيب والأصدقاء (لا تعمل على الجوال).
  DemoCloud? demo;

  /// مجموع تسبيحات المستخدم المحلي (للمعاينة فقط).
  int Function() localTotal = () => 0;

  bool get signedIn => demo != null ? demo!.signedIn : available && user != null;
  String? get uid => demo != null ? DemoCloud.myUid : user?.uid;
  String get displayName => demo != null
      ? (demo!.signedIn ? demo!.myName : '')
      : (profile?['name'] as String?) ?? user?.displayName ?? '';
  String? get friendCode => demo != null ? DemoCloud.myCode : profile?['code'] as String?;

  Future<void> init() async {
    // نسخة المتصفح للتجربة فقط: بدون سيرفر، مع بيانات وهمية.
    if (kIsWeb) {
      demo = DemoCloud();
      available = true;
      return;
    }
    try {
      await Firebase.initializeApp();
      available = true;
    } catch (e) {
      debugPrint('Firebase not configured: $e');
      available = false;
      return;
    }
    _authSub = _auth.authStateChanges().listen((u) async {
      user = u;
      profile = null;
      if (u != null) await _ensureProfile(u);
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _flushTimer?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------- الدخول

  Future<void> signInWithApple() async {
    if (demo != null) return _demoSignIn();
    final provider = AppleAuthProvider()
      ..addScope('name')
      ..addScope('email');
    final cred = await _auth.signInWithProvider(provider);
    // Apple ترسل الاسم مرة واحدة فقط عند أول دخول.
    final name = cred.user?.displayName;
    if (cred.user != null && (name == null || name.isEmpty)) {
      final given = cred.additionalUserInfo?.profile?['name'];
      if (given is String && given.isNotEmpty) {
        await cred.user!.updateDisplayName(given);
      }
    }
  }

  Future<void> _demoSignIn() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    demo!.signedIn = true;
    notifyListeners();
  }

  bool _googleInitialized = false;

  /// Web client (client_type 3) من google-services.json لمشروع kanz-almuslim.
  static const _webClientId = '557667158104-5cugdr6vnd3u12ahi62h9dotrd9r6t7u.apps.googleusercontent.com';

  Future<void> signInWithGoogle() async {
    if (demo != null) return _demoSignIn();
    final google = GoogleSignIn.instance;
    if (!_googleInitialized) {
      // على أندرويد نحتاج "Web client" ليرجع idToken يقبله Firebase.
      await google.initialize(serverClientId: isAndroid ? _webClientId : null);
      _googleInitialized = true;
    }
    final account = await google.authenticate();
    final idToken = account.authentication.idToken;
    final credential = GoogleAuthProvider.credential(idToken: idToken);
    await _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    if (demo != null) {
      demo!.signedIn = false;
      notifyListeners();
      return;
    }
    await flush();
    if (_googleInitialized) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }
    await _auth.signOut();
  }

  /// حذف الحساب: مطلوب من Apple لأي تطبيق فيه إنشاء حساب.
  Future<void> deleteAccount() async {
    if (demo != null) return signOut();
    final u = user;
    if (u == null) return;
    final code = friendCode;
    final batch = _db.batch();
    final friendships = await _db.collection('friendships').where('members', arrayContains: u.uid).get();
    for (final d in friendships.docs) {
      batch.delete(d.reference);
    }
    if (code != null) batch.delete(_db.collection('codes').doc(code));
    batch.delete(_db.collection('users').doc(u.uid));
    await batch.commit();
    try {
      await u.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        // نطلب دخولاً جديداً ثم نحذف.
        if (isIOS) {
          await u.reauthenticateWithProvider(AppleAuthProvider());
        } else {
          await signInWithGoogle();
        }
        await _auth.currentUser?.delete();
      } else {
        rethrow;
      }
    }
  }

  Future<void> updateName(String name) async {
    if (demo != null) {
      if (name.trim().isNotEmpty) demo!.myName = name.trim();
      notifyListeners();
      return;
    }
    final u = user;
    if (u == null) return;
    final clean = name.trim();
    if (clean.isEmpty || clean.length > 30) return;
    await _db.collection('users').doc(u.uid).set({'name': clean}, SetOptions(merge: true));
    profile = {...?profile, 'name': clean};
    notifyListeners();
  }

  Future<void> _ensureProfile(User u) async {
    final ref = _db.collection('users').doc(u.uid);
    final snap = await ref.get();
    if (snap.exists) {
      profile = snap.data();
      if (profile?['code'] == null) await _assignCode(ref);
      return;
    }
    final name = (u.displayName?.trim().isNotEmpty ?? false)
        ? u.displayName!.trim()
        : 'ذاكر ${Random().nextInt(9000) + 1000}';
    final now = DateTime.now();
    profile = {
      'name': name.length > 30 ? name.substring(0, 30) : name,
      'photo': u.photoURL,
      'total': 0,
      'dayKey': dayKey(now),
      'dayCount': 0,
      'weekKey': weekKey(now),
      'weekCount': 0,
      'monthKey': monthKey(now),
      'monthCount': 0,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await ref.set(profile!);
    await _assignCode(ref);
  }

  /// رمز صداقة من ٦ أحرف، فريد عبر مجموعة codes.
  Future<void> _assignCode(DocumentReference<Map<String, dynamic>> userRef) async {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random.secure();
    for (var attempt = 0; attempt < 5; attempt++) {
      final code = List.generate(6, (_) => alphabet[rnd.nextInt(alphabet.length)]).join();
      final codeRef = _db.collection('codes').doc(code);
      try {
        await _db.runTransaction((tx) async {
          final existing = await tx.get(codeRef);
          if (existing.exists) throw StateError('taken');
          tx.set(codeRef, {'uid': userRef.id});
          tx.update(userRef, {'code': code});
        });
        profile = {...?profile, 'code': code};
        return;
      } on StateError {
        continue;
      }
    }
  }

  // --------------------------------------------------------------- النقاط

  /// تُستدعى مع كل تسبيحة. نجمع النقاط ونرسلها دفعة واحدة كل ١٠ ثوانٍ
  /// بدل طلب لكل لمسة (النسخة القديمة كانت ترسل طلباً لكل تسبيحة).
  void addPoints(int n) {
    // في المعاينة يُقرأ المجموع المحلي مباشرة من localTotal.
    if (demo != null) return;
    if (!signedIn) return;
    _pending += n;
    _flushTimer ??= Timer(const Duration(seconds: 10), flush);
  }

  Future<void> flush() async {
    if (demo != null) return;
    _flushTimer?.cancel();
    _flushTimer = null;
    final u = user;
    if (u == null || _pending == 0) return;
    final delta = min(_pending, 2000); // نفس الحد الموجود في قواعد الحماية.
    _pending -= delta;
    final ref = _db.collection('users').doc(u.uid);
    final now = DateTime.now();
    final dk = dayKey(now), wk = weekKey(now), mk = monthKey(now);
    try {
      await _db.runTransaction((tx) async {
        final snap = await tx.get(ref);
        final d = snap.data() ?? {};
        int val(String k) => (d[k] as num?)?.toInt() ?? 0;
        tx.set(ref, {
          'total': val('total') + delta,
          'dayKey': dk,
          'dayCount': (d['dayKey'] == dk ? val('dayCount') : 0) + delta,
          'weekKey': wk,
          'weekCount': (d['weekKey'] == wk ? val('weekCount') : 0) + delta,
          'monthKey': mk,
          'monthCount': (d['monthKey'] == mk ? val('monthCount') : 0) + delta,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });
    } catch (e) {
      // إذا فشل الإرسال (بدون إنترنت مثلاً) نرجع النقاط للانتظار.
      _pending += delta;
      debugPrint('Flush failed: $e');
    }
    if (_pending > 0) _flushTimer ??= Timer(const Duration(seconds: 10), flush);
  }

  // -------------------------------------------------------------- الترتيب

  static (String keyField, String? keyValue, String countField) _periodFields(RankPeriod p) {
    final now = DateTime.now();
    return switch (p) {
      RankPeriod.day => ('dayKey', dayKey(now), 'dayCount'),
      RankPeriod.week => ('weekKey', weekKey(now), 'weekCount'),
      RankPeriod.month => ('monthKey', monthKey(now), 'monthCount'),
      RankPeriod.all => ('', null, 'total'),
    };
  }

  Future<List<RankEntry>> worldRanking(RankPeriod p) async {
    if (demo != null) return demo!.world(p, localTotal());
    final (keyField, keyValue, countField) = _periodFields(p);
    Query<Map<String, dynamic>> q = _db.collection('users');
    if (keyValue != null) q = q.where(keyField, isEqualTo: keyValue);
    final snap = await q.orderBy(countField, descending: true).limit(100).get();
    return snap.docs.map((d) => _entry(d.id, d.data(), countField)).where((e) => e.score > 0).toList();
  }

  Future<List<RankEntry>> friendsRanking(RankPeriod p) async {
    if (demo != null) return demo!.friendsRanking(p, localTotal());
    final u = user;
    if (u == null) return [];
    final (keyField, keyValue, countField) = _periodFields(p);
    final ids = [u.uid, ...await friendIds()];
    final entries = <RankEntry>[];
    for (var i = 0; i < ids.length; i += 30) {
      final chunk = ids.sublist(i, min(i + 30, ids.length));
      final snap = await _db.collection('users').where(FieldPath.documentId, whereIn: chunk).get();
      for (final d in snap.docs) {
        final data = d.data();
        final current = keyValue == null || data[keyField] == keyValue;
        entries.add(_entry(d.id, current ? data : {...data, countField: 0}, countField));
      }
    }
    entries.sort((a, b) => b.score.compareTo(a.score));
    return entries;
  }

  RankEntry _entry(String uid, Map<String, dynamic> d, String countField) => RankEntry(
    uid: uid,
    name: (d['name'] as String?) ?? '',
    score: (d[countField] as num?)?.toInt() ?? 0,
    photoUrl: d['photo'] as String?,
  );

  // -------------------------------------------------------------- الأصدقاء

  static String pairId(String a, String b) => a.compareTo(b) < 0 ? '${a}_$b' : '${b}_$a';

  Future<List<String>> friendIds() async {
    final u = user;
    if (u == null) return [];
    final snap = await _db.collection('friendships').where('members', arrayContains: u.uid).get();
    return [
      for (final d in snap.docs) ...(d.data()['members'] as List).cast<String>().where((m) => m != u.uid),
    ];
  }

  Stream<List<RankEntry>> friendsStream() {
    if (demo != null) return demo!.friendsStream();
    final u = user;
    if (u == null) return const Stream.empty();
    return _db.collection('friendships').where('members', arrayContains: u.uid).snapshots().asyncMap((
      snap,
    ) async {
      final ids = [
        for (final d in snap.docs) ...(d.data()['members'] as List).cast<String>().where((m) => m != u.uid),
      ];
      final out = <RankEntry>[];
      for (var i = 0; i < ids.length; i += 30) {
        final chunk = ids.sublist(i, min(i + 30, ids.length));
        final users = await _db.collection('users').where(FieldPath.documentId, whereIn: chunk).get();
        out.addAll(users.docs.map((d) => _entry(d.id, d.data(), 'total')));
      }
      out.sort((a, b) => a.name.compareTo(b.name));
      return out;
    });
  }

  /// يرجع false إذا الرمز غير موجود.
  Future<bool> sendFriendRequest(String code, {String message = ''}) async {
    if (demo != null) return code.trim().length >= 4 && code.trim().toUpperCase() != DemoCloud.myCode;
    final u = user;
    if (u == null) return false;
    final clean = code.trim().toUpperCase();
    if (clean.isEmpty || clean == friendCode) return false;
    final codeSnap = await _db.collection('codes').doc(clean).get();
    final to = codeSnap.data()?['uid'] as String?;
    if (to == null || to == u.uid) return false;
    await _db.collection('friendRequests').doc('${u.uid}_$to').set({
      'from': u.uid,
      'to': to,
      'fromName': displayName,
      if (message.trim().isNotEmpty)
        'message': message.trim().length > 300 ? message.trim().substring(0, 300) : message.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return true;
  }

  Stream<List<FriendRequest>> incomingRequests() {
    if (demo != null) return demo!.requestsStream();
    final u = user;
    if (u == null) return const Stream.empty();
    return _db
        .collection('friendRequests')
        .where('to', isEqualTo: u.uid)
        .snapshots()
        .map(
          (s) => s.docs
              .map(
                (d) => FriendRequest(
                  id: d.id,
                  fromUid: d.data()['from'] as String,
                  fromName: (d.data()['fromName'] as String?) ?? '',
                  message: (d.data()['message'] as String?) ?? '',
                ),
              )
              .toList(),
        );
  }

  Future<void> acceptRequest(FriendRequest r) async {
    if (demo != null) return demo!.accept(r);
    final u = user;
    if (u == null) return;
    // الصداقة تُنشأ أولاً (القواعد تتحقق من وجود الطلب)، ثم يُحذف الطلب.
    await _db.collection('friendships').doc(pairId(u.uid, r.fromUid)).set({
      'members': [u.uid, r.fromUid],
      'request': r.id,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _db.collection('friendRequests').doc(r.id).delete();
  }

  Future<void> declineRequest(FriendRequest r) async {
    if (demo != null) return demo!.decline(r);
    await _db.collection('friendRequests').doc(r.id).delete();
  }

  Future<void> removeFriend(String uid) async {
    if (demo != null) return demo!.remove(uid);
    final u = user;
    if (u == null) return;
    await _db.collection('friendships').doc(pairId(u.uid, uid)).delete();
  }

  // -------------------------------------------------------------- المحادثة

  Stream<List<ChatMessage>> messages(String friendUid) {
    if (demo != null) return demo!.messages(friendUid);
    final u = user;
    if (u == null) return const Stream.empty();
    return _db
        .collection('friendships')
        .doc(pairId(u.uid, friendUid))
        .collection('messages')
        .orderBy('at', descending: true)
        .limit(100)
        .snapshots()
        .map(
          (s) => s.docs.map((d) {
            final m = d.data();
            return ChatMessage(
              from: m['from'] as String,
              text: m['text'] as String,
              at: (m['at'] as Timestamp?)?.toDate() ?? DateTime.now(),
            );
          }).toList(),
        );
  }

  Future<void> sendMessage(String friendUid, String text) async {
    if (demo != null) {
      if (text.trim().isNotEmpty) demo!.send(friendUid, text.trim());
      return;
    }
    final u = user;
    final clean = text.trim();
    if (u == null || clean.isEmpty) return;
    await _db.collection('friendships').doc(pairId(u.uid, friendUid)).collection('messages').add({
      'from': u.uid,
      'text': clean.length > 500 ? clean.substring(0, 500) : clean,
      'at': FieldValue.serverTimestamp(),
    });
  }
}
