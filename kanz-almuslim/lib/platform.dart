import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// فحص المنصة بشكل آمن (dart:io لا يعمل في نسخة المتصفح التجريبية).
bool get isIOS => !kIsWeb && Platform.isIOS;
bool get isAndroid => !kIsWeb && Platform.isAndroid;
