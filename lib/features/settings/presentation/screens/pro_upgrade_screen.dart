import 'package:dose_time/core/widgets/three_d_button.dart';
import 'package:dose_time/core/services/purchase_service.dart';
import 'package:dose_time/features/settings/services/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class ProUpgradeScreen extends ConsumerStatefulWidget {
  const ProUpgradeScreen({super.key});

  @override
  ConsumerState<ProUpgradeScreen> createState() => _ProUpgradeScreenState();
}

class _ProUpgradeScreenState extends ConsumerState<ProUpgradeScreen> {
  bool _isLoading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final offeringsAsync = ref.watch(offeringsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Upgrade to Pro')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.star_rounded, size: 80, color: Colors.amber),
            const SizedBox(height: 16),
            const Text(
              'Unlock Full Potential',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _buildFeatureRow(Icons.check, 'Unlimited Medications'),
            _buildFeatureRow(Icons.check, 'Priority Support'),
            _buildFeatureRow(Icons.check, 'Ad-Free Experience'),
            _buildFeatureRow(Icons.check, 'Early Access Features'),
            const Spacer(),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            offeringsAsync.when(
              data: (offerings) => _buildPurchaseButton(offerings),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _buildFallbackPurchaseButton(),
            ),
            const SizedBox(height: 12),
            ThreeDButton(
              height: 40,
              color: Colors.white,
              onPressed: _isLoading ? null : _restorePurchases,
              child: const Text('Restore Purchases', style: TextStyle(color: Colors.teal)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseButton(Offerings? offerings) {
    final package = offerings?.current?.availablePackages.firstOrNull;
    final priceString = package?.storeProduct.priceString ?? '\$4.99';

    return ThreeDButton(
      color: Colors.amber,
      onPressed: _isLoading ? null : () => _purchasePro(package),
      child: _isLoading
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
            )
          : Text(
              'Get Lifetime Access - $priceString',
              style: const TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold),
            ),
    );
  }

  Widget _buildFallbackPurchaseButton() {
    // Fallback when offerings fail to load (e.g., RevenueCat not configured)
    return ThreeDButton(
      color: Colors.amber,
      onPressed: _isLoading ? null : _simulatePurchase,
      child: _isLoading
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
            )
          : const Text(
              'Get Lifetime Access - \$4.99',
              style: TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold),
            ),
    );
  }

  Future<void> _purchasePro(Package? package) async {
    if (package == null) {
      // Fall back to simulated purchase if no package available
      _simulatePurchase();
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final purchaseService = ref.read(purchaseServiceProvider);
      final success = await purchaseService.purchasePackage(package);

      if (success) {
        // Also update local settings for offline access
        await ref.read(settingsServiceProvider).setIsPro(true);
        ref.invalidate(isProUserProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Welcome to Pro! 🎉')),
          );
          context.pop();
        }
      } else {
        setState(() {
          _error = 'Purchase was cancelled or failed';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'An error occurred: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _simulatePurchase() async {
    // Simulated purchase flow when RevenueCat is not configured yet
    setState(() {
      _isLoading = true;
      _error = null;
    });

    await Future.delayed(const Duration(seconds: 1));
    await ref.read(settingsServiceProvider).setIsPro(true);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Welcome to Pro! (Simulated) 🎉')),
      );
      context.pop();
    }
  }

  Future<void> _restorePurchases() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final purchaseService = ref.read(purchaseServiceProvider);
      final success = await purchaseService.restorePurchases();

      if (success) {
        await ref.read(settingsServiceProvider).setIsPro(true);
        ref.invalidate(isProUserProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Purchases restored successfully!')),
          );
          context.pop();
        }
      } else {
        setState(() {
          _error = 'No previous purchases found';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to restore: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.green),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
