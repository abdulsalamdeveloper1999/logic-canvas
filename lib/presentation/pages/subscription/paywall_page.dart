import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:logic_canvas/presentation/cubits/entitlements/entitlements_cubit.dart';
import 'package:logic_canvas/presentation/cubits/entitlements/entitlements_state.dart';

class PaywallPage extends StatefulWidget {
  const PaywallPage({super.key});

  @override
  State<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends State<PaywallPage> {
  Package? _selectedPackage;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EntitlementsCubit, EntitlementsState>(
      builder: (context, state) {
        final offerings = state.offerings;
        final currentOffering = offerings?.current;

        // Auto-select annual if available, otherwise monthly
        if (_selectedPackage == null &&
            currentOffering != null &&
            currentOffering.availablePackages.isNotEmpty) {
          final availableAnnual = currentOffering.annual;
          final availableMonthly = currentOffering.monthly;

          if (availableAnnual != null) {
            _selectedPackage = availableAnnual;
          } else if (availableMonthly != null) {
            _selectedPackage = availableMonthly;
          } else {
            _selectedPackage = currentOffering.availablePackages.first;
          }
        }

        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // Background Glow
              Positioned(
                top: -100,
                right: -100,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blueAccent.withValues(alpha: 0.15),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                    child: Container(color: Colors.transparent),
                  ),
                ),
              ),

              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      // App Identity
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.blueAccent.withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Icon(
                              Icons.auto_fix_high_rounded,
                              color: Colors.blueAccent,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Text(
                            "LogicCanvas",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1.0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        "Elevate Your System Design",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Features List
                      _buildFeatureItem(
                        Icons.draw_rounded,
                        "Advanced Interaction",
                        "Shape detection & handwriting recognition.",
                      ),
                      const SizedBox(height: 16),
                      _buildFeatureItem(
                        Icons.cloud_sync_rounded,
                        "iCloud Sync",
                        "Your boards, synced across all devices.",
                      ),
                      const SizedBox(height: 16),
                      _buildFeatureItem(
                        Icons.picture_as_pdf_rounded,
                        "Pro Export",
                        "High-fidelity PDF and PNG exports.",
                      ),
                      const SizedBox(height: 16),
                      _buildFeatureItem(
                        Icons.layers_rounded,
                        "Unlimited Boards",
                        "Organize every problem effectively.",
                      ),

                      const Spacer(),

                      // Pack Selection
                      // Pack Selection
                      if (state.isLoading)
                        const Center(
                          child: CircularProgressIndicator(
                            color: Colors.blueAccent,
                          ),
                        )
                      else if (currentOffering != null &&
                          currentOffering.availablePackages.isNotEmpty)
                        Column(
                          children: [
                            // Show all available packages sorted by price (most expensive/annual usually first)
                            ...currentOffering.availablePackages.reversed.map((
                              package,
                            ) {
                              final isAnnual =
                                  package.packageType == PackageType.annual;
                              final isMonthly =
                                  package.packageType == PackageType.monthly;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildPackageCard(
                                  package,
                                  description: isAnnual
                                      ? "Only £2.50/month, billed annually. Save 50%!"
                                      : (isMonthly
                                            ? "Flexible month-to-month access."
                                            : null),
                                  badge: isAnnual ? "BEST VALUE" : null,
                                  isSelected:
                                      _selectedPackage?.identifier ==
                                      package.identifier,
                                ),
                              );
                            }),
                          ],
                        )
                      else
                        const Column(
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              color: Colors.redAccent,
                              size: 48,
                            ),
                            SizedBox(height: 16),
                            Text(
                              "No plans available",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Please ensure your RevenueCat Dashboard has a 'Current' offering with products attached.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 32),

                      // Purchase Button
                      SizedBox(
                        width: double.infinity,
                        height: 64,
                        child: ElevatedButton(
                          onPressed:
                              _selectedPackage != null && !state.isLoading
                              ? () => context
                                    .read<EntitlementsCubit>()
                                    .purchasePackage(_selectedPackage!)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.white10,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            elevation: 0,
                          ),
                          child: state.isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  _selectedPackage?.packageType ==
                                          PackageType.annual
                                      ? "Subscribe for ${_selectedPackage!.storeProduct.priceString}/year"
                                      : "Subscribe for ${_selectedPackage!.storeProduct.priceString}/month",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Compliance Text
                      Text(
                        "After the free trial, payment will be charged to your Apple ID account. Subscription automatically renews unless it is canceled at least 24 hours before the end of the current period. You can manage and cancel your subscriptions in your App Store account settings.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.3),
                          fontSize: 10,
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildFooterLink("Terms of Use", () {}),
                          _buildFooterDivider(),
                          _buildFooterLink("Privacy Policy", () {}),
                          _buildFooterDivider(),
                          _buildFooterLink(
                            "Restore",
                            () => context.read<EntitlementsCubit>().restore(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFooterLink(String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }

  Widget _buildFooterDivider() {
    return Text(
      "•",
      style: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.blueAccent, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPackageCard(
    Package package, {
    required bool isSelected,
    String? description,
    String? badge,
  }) {
    final price = package.storeProduct.priceString;
    final isAnnual = package.packageType == PackageType.annual;

    return GestureDetector(
      onTap: () => setState(() => _selectedPackage = package),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blueAccent.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? Colors.blueAccent
                : Colors.white.withValues(alpha: 0.1),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (badge != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    isAnnual ? "Annual Membership" : "Monthly Membership",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    isAnnual ? "Includes 1-week free trial" : "Includes 3-days free trial",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  isAnnual ? "/year" : "/month",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
