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
  String? _selectedPlanId;

  @override
  Widget build(BuildContext context) {
    final offeringsAsync = ref.watch(offeringsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upgrade to Pro'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.teal.shade50,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.amber.shade400, Colors.orange.shade400],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.workspace_premium, size: 60, color: Colors.white),
                      const SizedBox(height: 12),
                      const Text(
                        'DoseAlert Pro',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Unlock the full potential',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Features
                _buildFeatureRow(Icons.all_inclusive, 'Unlimited Medications'),
                _buildFeatureRow(Icons.notifications_off, 'Ad-Free Experience'),
                _buildFeatureRow(Icons.support_agent, 'Priority Support'),
                _buildFeatureRow(Icons.new_releases, 'Early Access Features'),
                _buildFeatureRow(Icons.local_fire_department, 'Streak Tracking & Badges'),

                const SizedBox(height: 24),

                // Subscription Plans
                Expanded(
                  child: offeringsAsync.when(
                    data: (offerings) => _buildSubscriptionPlans(offerings),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => _buildFallbackPlans(),
                  ),
                ),

                // Error message
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Purchase button
                ThreeDButton(
                  color: _selectedPlanId != null ? Colors.teal : Colors.grey,
                  onPressed: _isLoading || _selectedPlanId == null
                      ? null
                      : () => _purchaseSelectedPlan(),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Continue',
                          style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                ),
                const SizedBox(height: 12),

                // Restore purchases
                TextButton(
                  onPressed: _isLoading ? null : _restorePurchases,
                  child: const Text('Restore Purchases'),
                ),

                // Terms
                Text(
                  'Subscriptions auto-renew unless cancelled 24h before period ends.',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionPlans(Offerings? offerings) {
    final packages = offerings?.current?.availablePackages ?? [];

    if (packages.isEmpty) {
      return _buildFallbackPlans();
    }

    // Sort packages: Monthly, Yearly, Lifetime
    final sortedPackages = List<Package>.from(packages);
    sortedPackages.sort((a, b) {
      const order = {'monthly': 0, 'annual': 1, 'yearly': 1, 'lifetime': 2};
      final aOrder = order[a.identifier.toLowerCase()] ?? 3;
      final bOrder = order[b.identifier.toLowerCase()] ?? 3;
      return aOrder.compareTo(bOrder);
    });

    return ListView.builder(
      shrinkWrap: true,
      itemCount: sortedPackages.length,
      itemBuilder: (context, index) {
        final package = sortedPackages[index];
        return _buildPlanCard(
          id: package.identifier,
          title: _getPlanTitle(package.identifier),
          price: package.storeProduct.priceString,
          description: _getPlanDescription(package.identifier),
          badge: _getPlanBadge(package.identifier),
          isSelected: _selectedPlanId == package.identifier,
          onTap: () => setState(() => _selectedPlanId = package.identifier),
        );
      },
    );
  }

  Widget _buildFallbackPlans() {
    return Column(
      children: [
        _buildPlanCard(
          id: 'monthly',
          title: 'Monthly',
          price: '£2.99/month',
          description: 'Billed monthly',
          isSelected: _selectedPlanId == 'monthly',
          onTap: () => setState(() => _selectedPlanId = 'monthly'),
        ),
        _buildPlanCard(
          id: 'yearly',
          title: 'Yearly',
          price: '£24.99/year',
          description: 'Save 30% - Billed annually',
          badge: 'BEST VALUE',
          isSelected: _selectedPlanId == 'yearly',
          onTap: () => setState(() => _selectedPlanId = 'yearly'),
        ),
        _buildPlanCard(
          id: 'lifetime',
          title: 'Lifetime',
          price: '£49.99',
          description: 'One-time purchase, forever',
          isSelected: _selectedPlanId == 'lifetime',
          onTap: () => setState(() => _selectedPlanId = 'lifetime'),
        ),
      ],
    );
  }

  Widget _buildPlanCard({
    required String id,
    required String title,
    required String price,
    required String description,
    String? badge,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.teal.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.teal : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Radio indicator
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.teal : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.teal,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),

            // Plan details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),

            // Price
            Text(
              price,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.teal : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPlanTitle(String identifier) {
    final id = identifier.toLowerCase();
    if (id.contains('month')) return 'Monthly';
    if (id.contains('year') || id.contains('annual')) return 'Yearly';
    if (id.contains('lifetime')) return 'Lifetime';
    return identifier;
  }

  String _getPlanDescription(String identifier) {
    final id = identifier.toLowerCase();
    if (id.contains('month')) return 'Billed monthly';
    if (id.contains('year') || id.contains('annual')) return 'Save 30% - Billed annually';
    if (id.contains('lifetime')) return 'One-time purchase, forever';
    return '';
  }

  String? _getPlanBadge(String identifier) {
    final id = identifier.toLowerCase();
    if (id.contains('year') || id.contains('annual')) return 'BEST VALUE';
    return null;
  }

  Future<void> _purchaseSelectedPlan() async {
    if (_selectedPlanId == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final purchaseService = ref.read(purchaseServiceProvider);
      final offerings = await purchaseService.getOfferings();
      final packages = offerings?.current?.availablePackages ?? [];

      Package? selectedPackage;
      for (final pkg in packages) {
        if (pkg.identifier == _selectedPlanId) {
          selectedPackage = pkg;
          break;
        }
      }

      if (selectedPackage == null) {
        // Fallback: simulated purchase for testing
        await _simulatePurchase();
        return;
      }

      final success = await purchaseService.purchasePackage(selectedPackage);

      if (success) {
        await ref.read(settingsServiceProvider).setIsPro(true);
        ref.invalidate(isProUserProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Welcome to DoseAlert Pro! 🎉')),
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
    await Future.delayed(const Duration(seconds: 1));
    await ref.read(settingsServiceProvider).setIsPro(true);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Welcome to DoseAlert Pro! (Test Mode) 🎉')),
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
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.teal, size: 20),
          ),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }
}
