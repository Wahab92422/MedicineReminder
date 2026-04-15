import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Google Play Billing (Android) via [in_app_purchase]. Updates Firestore on success.
class PaymentService {
  PaymentService._();
  static final PaymentService instance = PaymentService._();

  static const String premiumProductId = 'premium_subscription';

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  ProductDetails? _premiumProduct;
  bool _initialized = false;

  ProductDetails? get cachedPremiumProduct => _premiumProduct;

  /// Whether the store reported availability on the last [init] call.
  bool get storeAvailable => _storeAvailable;
  bool _storeAvailable = false;

  final ValueNotifier<String?> lastError = ValueNotifier<String?>(null);

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    _storeAvailable = await _iap.isAvailable();
    if (!_storeAvailable) {
      if (kDebugMode) {
        debugPrint('PaymentService: billing not available on this device.');
      }
      return;
    }

    _purchaseSub ??= _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (Object e) {
        lastError.value = e.toString();
      },
    );
  }

  Future<void> dispose() async {
    await _purchaseSub?.cancel();
    _purchaseSub = null;
    _initialized = false;
  }

  /// Loads product metadata from the store (required before purchase).
  Future<ProductDetails?> queryPremiumProduct() async {
    lastError.value = null;
    await init();
    if (!_storeAvailable) {
      lastError.value = 'In-app purchases are not available.';
      return null;
    }

    final response = await _iap.queryProductDetails({premiumProductId});
    if (response.error != null) {
      lastError.value = response.error!.message;
    }
    if (response.productDetails.isEmpty) {
      if (response.notFoundIDs.contains(premiumProductId)) {
        lastError.value ??= 'Product "$premiumProductId" not found in Play Console.';
      }
      return null;
    }
    _premiumProduct = response.productDetails.first;
    return _premiumProduct;
  }

  /// Starts the purchase flow for [premiumProductId].
  Future<bool> purchasePremium() async {
    lastError.value = null;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      lastError.value = 'You must be signed in to subscribe.';
      return false;
    }

    if (!_storeAvailable) {
      await init();
    }
    if (!_storeAvailable) {
      lastError.value = 'Billing is not available.';
      return false;
    }

    final product = _premiumProduct ?? await queryPremiumProduct();
    if (product == null) {
      lastError.value ??= 'Product not found in the store.';
      return false;
    }

    final purchaseParam = PurchaseParam(productDetails: product);
    try {
      return _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } on Exception catch (e) {
      lastError.value = e.toString();
      return false;
    }
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.productID != premiumProductId) continue;

      switch (purchase.status) {
        case PurchaseStatus.pending:
          break;
        case PurchaseStatus.error:
          lastError.value = purchase.error?.message ?? 'Purchase failed.';
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _applyPremiumFromPurchase(purchase);
          break;
        case PurchaseStatus.canceled:
          break;
      }

      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  Future<void> _applyPremiumFromPurchase(PurchaseDetails purchase) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
      {'isPremium': true},
      SetOptions(merge: true),
    );
  }
}
