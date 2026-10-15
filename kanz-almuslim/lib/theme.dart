import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// ألوان التطبيق الأصلي، مأخوذة مباشرة من صور الشاشات القديمة.
class KanzColors {
  // الخلفية المتدرجة من الكحلي إلى الفيروزي.
  static const bgTop = Color(0xFF063153);
  static const bgMid = Color(0xFF0E6B72);
  static const bgBottom = Color(0xFF128781);

  /// شريط العنوان العلوي.
  static const header = Color(0xFF063153);

  /// بطاقة المستخدم ورأس جدول السجل.
  static const cardBlue = Color(0xFF005689);

  /// مربع الكأس والنقاط.
  static const trophyBox = Color(0xFF034055);

  /// الشريط السفلي.
  static const tabBar = Color(0xFF128983);

  /// الفيروزي الفاقع: العنصر النشط والخط فوق الشريط السفلي.
  static const cyan = Color(0xFF38F4F3);

  /// نقاط الصفحات غير النشطة.
  static const dotCyan = Color(0xFF75FDFD);

  /// خطوط الفصل بين صفوف الإعدادات.
  static const separator = Color(0xFF5B9EB8);

  /// خطوط الفصل في شاشة الإشعارات (فيروزية).
  static const separatorCyan = Color(0xFF8BE0F4);

  /// مربع إدخال الدقائق.
  static const inputBox = Color(0xFF006D70);

  /// زر الاستعادة في شاشة الدعم.
  static const restoreButton = Color(0xFF00465F);

  /// شريط "احصل على عضوية مميزة".
  static const supportBand = Color(0xFF0E9A99);

  /// مفتاح التشغيل الأخضر (مثل iOS).
  static const switchGreen = Color(0xFF34C759);

  /// الكأس الذهبي.
  static const gold = Color(0xFFF4D40B);

  // أعمدة السحب.
  static const pillarTop = Color(0xFF078790);
  static const pillarBottom = Color(0xFF08B2B2);
  static const pillarActiveTop = Color(0xFF019FAA);
  static const pillarActiveBottom = Color(0xFF01DCE2);
  static const pillarChevron = Color(0xFF0C6A78);

  // حبات السبحة.
  static const beadDim = Color(0x2A8FE3EE);
  static const beadLit = Color(0xFF1FD6DF);

  static const background = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [bgTop, bgMid, bgBottom],
    stops: [0.05, 0.6, 0.95],
  );
}

class KanzTheme {
  static const font = 'Tajawal';

  static ThemeData build() {
    final scheme = ColorScheme.fromSeed(
      seedColor: KanzColors.cardBlue,
      brightness: Brightness.dark,
      primary: KanzColors.cyan,
      secondary: KanzColors.cyan,
      surface: KanzColors.bgTop,
    );
    const white = Colors.white;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      fontFamily: font,
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: KanzColors.bgTop,
      textTheme: const TextTheme(
        bodyLarge: TextStyle(fontWeight: FontWeight.w300, color: white),
        bodyMedium: TextStyle(fontWeight: FontWeight.w300, color: white),
        titleMedium: TextStyle(fontWeight: FontWeight.w300, color: white),
        titleLarge: TextStyle(fontWeight: FontWeight.w300, color: white),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: KanzColors.bgTop,
        titleTextStyle: TextStyle(fontFamily: font, fontSize: 20, color: white),
        contentTextStyle: TextStyle(fontFamily: font, fontSize: 16, color: white, fontWeight: FontWeight.w300),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: KanzColors.bgTop,
        dragHandleColor: KanzColors.separator,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: KanzColors.cardBlue,
        contentTextStyle: TextStyle(fontFamily: font, color: white),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: KanzColors.cyan),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: KanzColors.separator)),
        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: KanzColors.cyan)),
        hintStyle: TextStyle(color: Colors.white54),
      ),
      cupertinoOverrideTheme: const CupertinoThemeData(primaryColor: KanzColors.cyan),
    );
  }
}
