import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Service to handle RevenueCat in-app purchases
class PurchaseService {
  // RevenueCat Public SDK Key from https://app.revenuecat.com
  static const String _apiKey = 'test_nXCbgNcJQxxjLjELMuhxQlBbrQN';
  
  // Entitlement ID configured in RevenueCat dashboard
  static const String _proEntitlementId = 'DoseAlert Pro';

  bool _isInitialized = false;
  final StreamController<CustomerInfo> _customerInfoController = StreamController<CustomerInfo>.broadcast();

  /// Initialize RevenueCat SDK
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      PurchasesConfiguration configuration;
      if (defaultTargetPlatform == TargetPlatform.android) {
        configuration = PurchasesConfiguration(_apiKey);
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        configuration = PurchasesConfiguration(_apiKey);
      } else {
        // For web/desktop, purchases are not supported
        debugPrint('PurchaseService: Platform not supported for purchases');
        return;
      }

      await Purchases.setLogLevel(LogLevel.debug);
      
      await Purchases.configure(configuration);
      Purchases.addCustomerInfoUpdateListener((info) {
        _customerInfoController.add(info);
      });
      _isInitialized = true;
      debugPrint('PurchaseService: Initialized successfully');
    } catch (e) {
      debugPrint('PurchaseService: Failed to initialize - $e');
    }
  }

  /// Check if user has Pro entitlement
  Future<bool> isProUser() async {
    if (!_isInitialized) return false;
    
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.active.containsKey(_proEntitlementId);
    } catch (e) {
      debugPrint('PurchaseService: Error checking pro status - $e');
      return false;
    }
  }

  /// Get available offerings (products)
  Future<Offerings?> getOfferings() async {
    if (!_isInitialized) return null;
    
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      debugPrint('PurchaseService: Error getting offerings - $e');
      return null;
    }
  }

  /// Purchase a package
  Future<bool> purchasePackage(Package package) async {
    if (!_isInitialized) return false;
    
    try {
      final customerInfo = await Purchases.purchasePackage(package);
      return customerInfo.entitlements.active.containsKey(_proEntitlementId);
    } on PurchasesErrorCode catch (e) {
      if (e == PurchasesErrorCode.purchaseCancelledError) {
        debugPrint('PurchaseService: Purchase cancelled by user');
      } else {
        debugPrint('PurchaseService: Purchase error - $e');
      }
      return false;
    } catch (e) {
      debugPrint('PurchaseService: Purchase error - $e');
      return false;
    }
  }

  /// Restore previous purchases
  Future<bool> restorePurchases() async {
    if (!_isInitialized) return false;
    
    try {
      final customerInfo = await Purchases.restorePurchases();
      return customerInfo.entitlements.active.containsKey(_proEntitlementId);
    } catch (e) {
      debugPrint('PurchaseService: Error restoring purchases - $e');
      return false;
    }
  }

  /// Listen to customer info changes
  Stream<CustomerInfo> get customerInfoStream {
    return _customerInfoController.stream;
  }
}

// Providers
final purchaseServiceProvider = Provider<PurchaseService>((ref) {
  return PurchaseService();
});

final isProUserProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(purchaseServiceProvider);
  return service.isProUser();
});

final offeringsProvider = FutureProvider<Offerings?>((ref) async {
  final service = ref.watch(purchaseServiceProvider);
  return service.getOfferings();
});
