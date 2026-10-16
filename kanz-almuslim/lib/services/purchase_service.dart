import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// مشتريات دعم التطبيق (العضوية المميزة) بنفس معرّفات النسخة الأصلية
/// حتى تبقى المنتجات الموجودة في App Store Connect صالحة.
class PurchaseService extends ChangeNotifier {
  PurchaseService._();
  static final PurchaseService instance = PurchaseService._();

  static const productIds = <String>[
    'com.sci3ntist.kanzalmuslim.onetimepayment',
    'com.sci3ntist.kanzalmuslim.monthly2.99',
    'com.sci3ntist.kanzalmuslim.monthly3.99',
  ];

  bool available = false;
  bool loading = false;
  List<ProductDetails> products = [];

  /// يُستدعى عند نجاح شراء أو استعادة.
  void Function()? onPremium;

  StreamSubscription<List<PurchaseDetails>>? _sub;

  Future<void> init() async {
    if (kIsWeb) return;
    final iap = InAppPurchase.instance;
    try {
      available = await iap.isAvailable();
    } catch (e) {
      debugPrint('IAP unavailable: $e');
      available = false;
    }
    if (!available) return;
    _sub = iap.purchaseStream.listen(
      _onPurchases,
      onError: (e) => debugPrint('IAP error: $e'),
    );
    await loadProducts();
  }

  Future<void> loadProducts() async {
    if (!available) return;
    loading = true;
    notifyListeners();
    try {
      final res = await InAppPurchase.instance.queryProductDetails(
        productIds.toSet(),
      );
      products = res.productDetails
        ..sort((a, b) => a.rawPrice.compareTo(b.rawPrice));
    } catch (e) {
      debugPrint('IAP query failed: $e');
    }
    loading = false;
    notifyListeners();
  }

  Future<void> buy(ProductDetails p) => InAppPurchase.instance.buyNonConsumable(
    purchaseParam: PurchaseParam(productDetails: p),
  );

  Future<void> restore() => InAppPurchase.instance.restorePurchases();

  Future<void> _onPurchases(List<PurchaseDetails> list) async {
    for (final p in list) {
      if (p.status == PurchaseStatus.purchased ||
          p.status == PurchaseStatus.restored) {
        onPremium?.call();
      }
      if (p.pendingCompletePurchase) {
        await InAppPurchase.instance.completePurchase(p);
      }
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
