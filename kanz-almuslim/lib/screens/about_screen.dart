import 'package:flutter/material.dart';

import '../l10n.dart';
import '../widgets/kanz_ui.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return KanzPage(
      title: tr(context, 'about'),
      showBack: true,
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
        children: [
          const Center(child: KanzLogo(size: 92)),
          const SizedBox(height: 8),
          const Text(
            'كنز المسلم',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const Text(
            'KANZ ALMUSLIM',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 26),
          Text(
            tr(context, 'aboutBody'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              height: 1.6,
              fontWeight: FontWeight.w300,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '2.0.0',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54),
          ),
        ],
      ),
    );
  }
}
