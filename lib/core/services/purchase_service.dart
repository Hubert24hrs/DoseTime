import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PurchaseOutcome { success, cancelled, pending, failed }

/// Google Play / App Store purchases through RevenueCat.
///
/// The public SDK keys are supplied at build time so no key lives in source:
///   flutter build appbundle --dart-define=REVENUECAT_GOOGLE_API_KEY=goog_xxx
/// Without a key, purchases are unavailable (the upgrade screen says so);
/// nothing is ever unlocked without a verified store purchase.
class PurchaseService {
  static final PurchaseService _instance = PurchaseService._internal();
  factory PurchaseService() => _instance;
  PurchaseService._internal();

  static const String _googleApiKey = String.fromEnvironment('REVENUECAT_GOOGLE_API_KEY');
  static const String _appleApiKey = String.fromEnvironment('REVENUECAT_APPLE_API_KEY');

  /// Entitlement identifier configured in the RevenueCat dashboard.
  static const String proEntitlementId = 'DoseAlert Pro';

  /// Cached result of the last verified entitlement check (offline fallback).
  static const String _proCacheKey = 'is_pro';

  /// Earlier test builds could set the Pro flag without a purchase; clear it
  /// once so only verified purchases count.
  static const String _cacheResetKey = 'pro_cache_verified_v2';

  bool _isInitialized = false;
  final StreamController<CustomerInfo> _customerInfoController = StreamController<CustomerInfo>.broadcast();

  bool get isAvailable => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_cacheResetKey) != true) {
      await prefs.setBool(_proCacheKey, false);
      await prefs.setBool(_cacheResetKey, true);
    }

    final String apiKey;
    if (defaultTargetPlatform == TargetPlatform.android) {
      apiKey = _googleApiKey;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      apiKey = _appleApiKey;
    } else {
      debugPrint('PurchaseService: Platform not supported for purchases');
      return;
    }
    if (apiKey.isEmpty) {
      debugPrint('PurchaseService: No RevenueCat key for this build; purchases unavailable');
      return;
    }

    try {
      await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.warn);
      await Purchases.configure(PurchasesConfiguration(apiKey));
      Purchases.addCustomerInfoUpdateListener((info) {
        _cacheEntitlement(info);
        _customerInfoController.add(info);
      });
      _isInitialized = true;
      _cacheEntitlement(await Purchases.getCustomerInfo());
      debugPrint('PurchaseService: Initialized');
    } catch (e) {
      debugPrint('PurchaseService: Failed to initialize - $e');
    }
  }

  bool _hasPro(CustomerInfo info) => info.entitlements.active.containsKey(proEntitlementId);

  Future<void> _cacheEntitlement(CustomerInfo info) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_proCacheKey, _hasPro(info));
  }

  Future<bool> _cachedPro() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_proCacheKey) ?? false;
  }

  /// Whether the user has an active Pro entitlement. Falls back to the last
  /// verified result when the store can't be reached.
  Future<bool> isProUser() async {
    if (!_isInitialized) return _cachedPro();
    try {
      final info = await Purchases.getCustomerInfo();
      await _cacheEntitlement(info);
      return _hasPro(info);
    } catch (e) {
      debugPrint('PurchaseService: Error checking pro status - $e');
      return _cachedPro();
    }
  }

  Future<Offerings?> getOfferings() async {
    if (!_isInitialized) return null;
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      debugPrint('PurchaseService: Error getting offerings - $e');
      return null;
    }
  }

  Future<PurchaseOutcome> purchasePackage(Package package) async {
    if (!_isInitialized) return PurchaseOutcome.failed;
    try {
      final info = await Purchases.purchasePackage(package);
      await _cacheEntitlement(info);
      return _hasPro(info) ? PurchaseOutcome.success : PurchaseOutcome.failed;
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) return PurchaseOutcome.cancelled;
      if (code == PurchasesErrorCode.paymentPendingError) return PurchaseOutcome.pending;
      debugPrint('PurchaseService: Purchase error - $code');
      return PurchaseOutcome.failed;
    } catch (e) {
      debugPrint('PurchaseService: Purchase error - $e');
      return PurchaseOutcome.failed;
    }
  }

  Future<bool> restorePurchases() async {
    if (!_isInitialized) return false;
    try {
      final info = await Purchases.restorePurchases();
      await _cacheEntitlement(info);
      return _hasPro(info);
    } catch (e) {
      debugPrint('PurchaseService: Error restoring purchases - $e');
      return false;
    }
  }

  Stream<CustomerInfo> get customerInfoStream => _customerInfoController.stream;
}

final purchaseServiceProvider = Provider<PurchaseService>((ref) => PurchaseService());

final isProUserProvider = FutureProvider<bool>((ref) async {
  return ref.watch(purchaseServiceProvider).isProUser();
});

final offeringsProvider = FutureProvider<Offerings?>((ref) async {
  return ref.watch(purchaseServiceProvider).getOfferings();
});
