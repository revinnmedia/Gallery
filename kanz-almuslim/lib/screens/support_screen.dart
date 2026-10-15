import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n.dart';
import '../services/purchase_service.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/kanz_ui.dart';

/// شاشة "الاشتراك و دعم التطبيق" (القلب) بنفس تصميم النسخة الأصلية.
class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final state = context.watch<AppState>();
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: KanzBackground(
        child: ListenableBuilder(
          listenable: PurchaseService.instance,
          builder: (context, _) {
            final iap = PurchaseService.instance;
            return Column(
              children: [
                Container(
                  color: KanzColors.header,
                  padding: EdgeInsets.only(top: top),
                  height: top + 56,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(tr(context, 'back'),
                                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w300)),
                            const Icon(Icons.chevron_right, color: Colors.white, size: 30),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      const SizedBox(height: 40),
                      const Center(child: KanzLogo(size: 92, hole: Color(0xFF07385A))),
                      const SizedBox(height: 8),
                      const Text('كنز المسلم',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w500, color: Colors.white)),
                      const Text('KANZ ALMUSLIM',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white)),
                      const SizedBox(height: 26),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 34),
                        child: Text(
                          tr(context, 'supportBody'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16, height: 1.5, fontWeight: FontWeight.w300, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 40),
                      Container(
                        height: 56,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(colors: [Color(0xFF0E8E92), Color(0xFF0B9D9C)]),
                          border: Border(bottom: BorderSide(color: Color(0xFF4ECCCB))),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                state.premium ? tr(context, 'thanksPremium') : tr(context, 'getPremium'),
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w300, color: Colors.white),
                              ),
                            ),
                            const Icon(Icons.favorite, color: Colors.white, size: 40),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 26),
                        child: iap.products.isEmpty
                            ? SizedBox(
                                height: 120,
                                child: Center(
                                  child: iap.loading
                                      ? const CircularProgressIndicator(color: KanzColors.cyan)
                                      : Text(tr(context, 'storeUnavailable'),
                                          style: const TextStyle(color: Colors.white70)),
                                ),
                              )
                            : Row(
                                children: [
                                  for (final p in iap.products)
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 6),
                                        child: _PriceCard(price: p.price, onTap: () => iap.buy(p)),
                                      ),
                                    ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 26),
                      Center(
                        child: SizedBox(
                          width: 230,
                          height: 50,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: KanzColors.restoreButton,
                              shape: const RoundedRectangleBorder(),
                            ),
                            onPressed: iap.available ? iap.restore : null,
                            child: Text(tr(context, 'restore'),
                                style: const TextStyle(fontSize: 19, color: Colors.white)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  const _PriceCard({required this.price, required this.onTap});
  final String price;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 104,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: KanzColors.cyan.withValues(alpha: 0.8)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [KanzColors.cyan.withValues(alpha: 0.35), KanzColors.tabBar],
            ),
          ),
          alignment: Alignment.center,
          child: FittedBox(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Text(price, style: const TextStyle(fontSize: 26, color: Colors.white, fontWeight: FontWeight.w300)),
            ),
          ),
        ),
      );
}
