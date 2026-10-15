import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme.dart';

/// الخلفية المتدرجة الأصلية (كحلي → فيروزي).
class KanzBackground extends StatelessWidget {
  const KanzBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(gradient: KanzColors.background),
        child: child,
      );
}

/// صفحة بالشكل الأصلي: خلفية متدرجة + شريط عنوان علوي.
class KanzPage extends StatelessWidget {
  const KanzPage({
    super.key,
    required this.title,
    required this.body,
    this.onHeart,
    this.showBack = false,
    this.action,
  });

  final String title;
  final Widget body;

  /// زر القلب في أعلى اليسار (يفتح شاشة الدعم).
  final VoidCallback? onHeart;
  final bool showBack;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: KanzBackground(
        child: Column(
          children: [
            KanzHeader(title: title, onHeart: onHeart, showBack: showBack, action: action),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

class KanzHeader extends StatelessWidget {
  const KanzHeader({super.key, required this.title, this.onHeart, this.showBack = false, this.action});
  final String title;
  final VoidCallback? onHeart;
  final bool showBack;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      color: KanzColors.header,
      padding: EdgeInsets.only(top: top),
      child: Column(
        children: [
          SizedBox(
            height: 64,
            width: double.infinity,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w300, color: Colors.white)),
                if (showBack)
                  PositionedDirectional(
                    start: 4,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 22),
                    ),
                  ),
                // القلب دائماً في أعلى اليسار كما في الأصل.
                if (onHeart != null)
                  Positioned(
                    left: 6,
                    child: IconButton(
                      onPressed: onHeart,
                      icon: const Icon(Icons.favorite_border, color: Colors.white, size: 34, weight: 200),
                    ),
                  ),
                if (action != null) Positioned(left: onHeart != null ? 54 : 6, child: action!),
              ],
            ),
          ),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.06)),
        ],
      ),
    );
  }
}

/// مفتاح أخضر مثل iOS (كما في النسخة الأصلية).
class KanzSwitch extends StatelessWidget {
  const KanzSwitch({super.key, required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => CupertinoSwitch(
        value: value,
        activeTrackColor: KanzColors.switchGreen,
        inactiveTrackColor: const Color(0x40FFFFFF),
        onChanged: onChanged,
      );
}

/// صف بالشكل الأصلي: أيقونة على اليمين، نص، وسهم أو مفتاح على اليسار.
class KanzRow extends StatelessWidget {
  const KanzRow({
    super.key,
    required this.title,
    this.icon,
    this.trailing,
    this.onTap,
    this.subtitle,
    this.separatorColor = KanzColors.separator,
    this.indentSeparator = true,
    this.chevron = true,
    this.height = 64,
  });

  final String title;
  final Widget? icon;
  final Widget? trailing;
  final VoidCallback? onTap;
  final String? subtitle;
  final Color separatorColor;
  final bool indentSeparator;
  final bool chevron;
  final double height;

  @override
  Widget build(BuildContext context) {
    final end = trailing ??
        (chevron && onTap != null
            // السهم يشير لليسار دائماً كما في النسخة الأصلية.
            ? const Directionality(
                textDirection: TextDirection.ltr,
                child: Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 18),
              )
            : null);
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: height),
            child: Padding(
              padding: const EdgeInsetsDirectional.only(start: 18, end: 16),
              child: Row(
                children: [
                  if (icon != null) ...[
                    SizedBox(width: 40, height: 40, child: Center(child: icon)),
                    const SizedBox(width: 14),
                  ],
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w300, color: Colors.white)),
                        if (subtitle != null)
                          Text(subtitle!,
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w300, color: Colors.white.withValues(alpha: 0.7))),
                      ],
                    ),
                  ),
                  ?end,
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsetsDirectional.only(end: indentSeparator ? 34 : 0),
            child: Container(height: 1, color: separatorColor.withValues(alpha: 0.9)),
          ),
        ],
      ),
    );
  }
}

/// أيقونة داخل دائرة رفيعة (مثل نجمة التقييم والقمر في الإعدادات).
class CircledIcon extends StatelessWidget {
  const CircledIcon(this.icon, {super.key, this.size = 36});
  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1.6),
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.6),
      );
}

/// أيقونة السبحة في الشريط السفلي: حبات حول دائرة.
class BeadsIcon extends StatelessWidget {
  const BeadsIcon({super.key, required this.color, this.size = 40});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _BeadsIconPainter(color));
}

class _BeadsIconPainter extends CustomPainter {
  _BeadsIconPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width * 0.36;
    final p = Paint()..color = color;
    for (var i = 0; i < 8; i++) {
      final a = -pi / 2 + i * 2 * pi / 8;
      // الحبات تكبر تدريجياً كما في الأيقونة الأصلية.
      final br = size.width * (0.06 + 0.012 * ((i + 3) % 8));
      canvas.drawCircle(c + Offset(cos(a), sin(a)) * r, br, p);
    }
  }

  @override
  bool shouldRepaint(_BeadsIconPainter old) => old.color != color;
}

/// شعار كنز المسلم (المكعب). رسم تقريبي للشعار الأصلي.
class KanzLogo extends StatelessWidget {
  const KanzLogo({super.key, this.size = 90, this.color = Colors.white, this.hole = KanzColors.bgTop});
  final double size;
  final Color color;
  final Color hole;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _LogoPainter(color, hole));
}

class _LogoPainter extends CustomPainter {
  _LogoPainter(this.color, this.hole);
  final Color color;
  final Color hole;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100;
    Offset p(double x, double y) => Offset(x * s, y * s);
    Path poly(List<Offset> pts) => Path()..addPolygon(pts, true);

    final white = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final round = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10 * s
      ..strokeJoin = StrokeJoin.round;
    final dark = Paint()..color = hole;
    final darkRound = Paint()
      ..color = hole
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4 * s
      ..strokeJoin = StrokeJoin.round;

    // المسدس الخارجي بزوايا مدوّرة.
    final hex = poly([p(50, 6), p(89, 28), p(89, 72), p(50, 94), p(11, 72), p(11, 28)]);
    canvas.drawPath(hex, white);
    canvas.drawPath(hex, round);

    // غطاء المكعب.
    final lid = poly([p(50, 17), p(73, 30), p(50, 43), p(27, 30)]);
    canvas.drawPath(lid, dark);
    canvas.drawPath(lid, darkRound);

    // الوجه الأيسر والأيمن.
    final left = poly([p(19, 38), p(44, 52), p(44, 83), p(19, 69)]);
    final right = poly([p(81, 38), p(56, 52), p(56, 83), p(81, 69)]);
    for (final f in [left, right]) {
      canvas.drawPath(f, dark);
      canvas.drawPath(f, darkRound);
    }

    // الفتحة الصغيرة في الوجه الأيسر.
    final slot = RRect.fromRectAndRadius(Rect.fromLTWH(26 * s, 52 * s, 6 * s, 16 * s), Radius.circular(3 * s));
    canvas.drawRRect(slot, white);

    // العمود في الوجه الأيمن.
    final stem = RRect.fromRectAndRadius(Rect.fromLTWH(66 * s, 50 * s, 6 * s, 24 * s), Radius.circular(3 * s));
    canvas.drawRRect(stem, white);
  }

  @override
  bool shouldRepaint(_LogoPainter old) => old.color != color || old.hole != hole;
}

/// صف جدول بالشكل الأصلي (رأس السجل).
class KanzTableHeader extends StatelessWidget {
  const KanzTableHeader({super.key, required this.cells, this.selected, this.onTap});
  final List<String> cells;
  final int? selected;
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < cells.length; i++)
          Expanded(
            child: GestureDetector(
              onTap: onTap == null ? null : () => onTap!(i),
              child: Container(
                height: 52,
                margin: EdgeInsetsDirectional.only(end: i == cells.length - 1 ? 0 : 2),
                color: selected == i ? KanzColors.inputBox : KanzColors.cardBlue,
                alignment: Alignment.center,
                child: Text(
                  cells[i],
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w300,
                    color: selected == null || selected == i ? KanzColors.cyan : Colors.white70,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

Future<void> showKanzSnack(BuildContext context, String text) async {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}
