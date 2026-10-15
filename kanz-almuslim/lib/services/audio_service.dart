import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

/// مشغّل صوت واحد للتطبيق كله.
///
/// في النسخة القديمة كانت كل لمسة تنشئ مشغّلاً جديداً فتتداخل الأصوات.
/// هنا يوجد مشغّل واحد فقط: أي صوت جديد يوقف السابق أولاً.
class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  /// يُطفأ في الاختبارات حيث لا يوجد مشغّل صوت فعلي.
  static bool enabled = true;

  late final AudioPlayer _player = AudioPlayer();
  String? _loaded;
  final Set<String> _missing = {};

  /// يشغّل ملف `assets/sounds/<name>.mp3`. إذا الملف غير موجود يتجاهل بهدوء.
  Future<void> play(String? name) async {
    if (!enabled || name == null || _missing.contains(name)) return;
    try {
      await _player.stop();
      if (_loaded != name) {
        await _player.setAsset('assets/sounds/$name.mp3');
        _loaded = name;
      } else {
        await _player.seek(Duration.zero);
      }
      // لا ننتظر انتهاء الصوت حتى لا نعطّل اللمسة التالية.
      _player.play();
    } on PlatformException catch (e) {
      _markMissing(name, e);
    } on PlayerException catch (e) {
      _markMissing(name, e);
    } catch (e) {
      _markMissing(name, e);
    }
  }

  void _markMissing(String name, Object e) {
    _missing.add(name);
    _loaded = null;
    debugPrint('Sound $name unavailable: $e');
  }

  Future<void> stop() async {
    if (enabled) await _player.stop();
  }
}
