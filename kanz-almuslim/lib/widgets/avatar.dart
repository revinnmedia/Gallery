import 'package:flutter/material.dart';

import '../theme.dart';

class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.name, this.url, this.radius = 20});

  final String name;
  final String? url;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '؟' : name.trim().characters.first;
    final fallback = CircleAvatar(
      radius: radius,
      backgroundColor: KanzColors.inputBox,
      foregroundColor: Colors.white,
      child: Text(
        initial,
        style: TextStyle(fontSize: radius * 0.8, fontWeight: FontWeight.w700),
      ),
    );
    if (url == null || url!.isEmpty) return fallback;
    return ClipOval(
      child: Image.network(
        url!,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }
}
