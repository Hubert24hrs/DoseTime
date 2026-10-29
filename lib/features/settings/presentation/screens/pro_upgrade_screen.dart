import 'package:dose_time/core/theme/app_theme.dart';
import 'package:dose_time/core/widgets/three_d_button.dart';
import 'package:dose_time/core/services/purchase_service.dart';
import 'package:dose_time/core/utils/app_constants.dart';
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
              brandBlue.shade50,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
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
                _buildFeatureRow(Icons.all_inclusive, 'Unlimited medications'),
                _buildFeatureRow(Icons.family_restroom, 'Track every prescription and supplement'),
                _buildFeatureRow(Icons.favorite_outline, 'Support DoseAlert\'s development'),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'The free plan includes up to ${AppConstants.freeMedicationLimit} medications.',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                ),

                const SizedBox(height: 24),
                
                // Section title
                const Text(
                  'Choose Your Plan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                // Subscription Plans
                offeringsAsync.when(
                  data: (offerings) => _buildSubscriptionPlans(offerings),
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (e, _) => _buildUnavailable(),
                ),

                const SizedBox(height: 20),

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
                  color: brandBlue,
                  onPressed: _isLoading || _selectedPlanId == null ? null : () => _purchaseSelectedPlan(),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          _selectedPlanId == null ? 'Choose a plan' : 'Get ${_getPlanDisplayName(_selectedPlanId!)}',
                          style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                ),
                const SizedBox(height: 12),

                // Restore purchases
                Center(
                  child: TextButton(
                    onPressed: _isLoading ? null : _restorePurchases,
                    child: const Text('Restore Purchases'),
                  ),
                ),

                const SizedBox(height: 8),

                // Terms
                Text(
                  'Payment is charged to your Google Play account. Subscriptions renew automatically '
                  'unless cancelled at least 24 hours before the end of the current period. '
                  'Manage or cancel anytime in Google Play → Payments & subscriptions.',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getPlanDisplayName(String id) {
    if (id.toLowerCase().contains('month')) return 'Monthly';
    if (id.toLowerCase().contains('year') || id.toLowerCase().contains('annual')) return 'Yearly';
    if (id.toLowerCase().contains('lifetime')) return 'Lifetime';
    return 'Pro';
  }

  Widget _buildSubscriptionPlans(Offerings? offerings) {
    final packages = offerings?.current?.availablePackages ?? [];

    if (packages.isEmpty) {
      return _buildUnavailable();
    }

    // Sort packages: Monthly, Yearly, Lifetime
    final sortedPackages = List<Package>.from(packages);
    sortedPackages.sort((a, b) {
      const order = {'monthly': 0, 'annual': 1, 'yearly': 1, 'lifetime': 2};
      final aOrder = order[a.identifier.toLowerCase()] ?? 3;
      final bOrder = order[b.identifier.toLowerCase()] ?? 3;
      return aOrder.compareTo(bOrder);
    });

    // Pre-select the yearly plan when offered, otherwise the first one.
    if (_selectedPlanId == null || !sortedPackages.any((p) => p.identifier == _selectedPlanId)) {
      final yearly = sortedPackages.where((p) => p.packageType == PackageType.annual);
      final pick = (yearly.isNotEmpty ? yearly.first : sortedPackages.first).identifier;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedPlanId = pick);
      });
    }

    return Column(
      children: sortedPackages.map((package) {
        return _buildPlanCard(
          id: package.identifier,
          title: _getPlanTitle(package.identifier),
          price: package.storeProduct.priceString,
          description: _getPlanDescription(package.identifier),
          badge: _getPlanBadge(package.identifier),
          isSelected: _selectedPlanId == package.identifier,
          onTap: () {
            setState(() => _selectedPlanId = package.identifier);
          },
        );
      }).toList(),
    );
  }

  /// Shown when the store can't provide plans (offline, or purchases not set
  /// up for this build). Nothing can be bought or unlocked from here.
  Widget _buildUnavailable() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_outlined, color: Colors.grey, size: 32),
          const SizedBox(height: 8),
          const Text(
            'Plans aren\'t available right now',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Check your internet connection and make sure Google Play is signed in, then try again.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          TextButton(
            onPressed: () => ref.invalidate(offeringsProvider),
            child: const Text('Try again'),
          ),
        ],
      ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: isSelected ? brandBlue.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? brandBlue : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
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
                      color: isSelected ? brandBlue : Colors.grey.shade400,
                      width: 2,
                    ),
                    color: isSelected ? brandBlue : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? brandBlue : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
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
    if (id.contains('year') || id.contains('annual')) return 'Billed once a year';
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
      final matches = packages.where((p) => p.identifier == _selectedPlanId);

      if (matches.isEmpty) {
        setState(() => _error = 'This plan isn\'t available right now. Please try again later.');
        return;
      }

      final outcome = await purchaseService.purchasePackage(matches.first);
      ref.invalidate(isProUserProvider);

      switch (outcome) {
        case PurchaseOutcome.success:
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Welcome to DoseAlert Pro! 🎉')),
            );
            context.pop();
          }
        case PurchaseOutcome.cancelled:
          break;
        case PurchaseOutcome.pending:
          setState(() => _error = 'Your payment is pending. Pro unlocks as soon as Google Play confirms it.');
        case PurchaseOutcome.failed:
          setState(() => _error = 'The purchase didn\'t go through. You haven\'t been charged; please try again.');
      }
    } catch (e) {
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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

      ref.invalidate(isProUserProvider);
      if (success) {

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Purchases restored successfully!')),
          );
          context.pop();
        }
      } else {
        setState(() {
          _error = 'No active Pro purchase found for this Google account.';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Couldn\'t reach Google Play. Please try again.';
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
              color: brandBlue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: brandBlue, size: 20),
          ),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }
}
