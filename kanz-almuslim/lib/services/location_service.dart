import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// موقع تقريبي لحساب وقتي الفجر والعصر (لأوقات التسبيح المباركة).
/// دقة منخفضة تكفي، ولا يُرسل الموقع لأي مكان: يبقى على الجهاز.
class LocationService {
  static Future<(double lat, double lng)?> current() async {
    if (kIsWeb) return null;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
      if (p == LocationPermission.denied || p == LocationPermission.deniedForever) return null;
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return (pos.latitude, pos.longitude);
    } catch (e) {
      debugPrint('Location unavailable: $e');
      return null;
    }
  }
}
