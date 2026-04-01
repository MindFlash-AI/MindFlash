import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/pro_service.dart';

class ManageSubscriptionScreen extends StatelessWidget {
  const ManageSubscriptionScreen({super.key});

  /// Safely opens the native OS subscription management page so users can cancel/downgrade.
  Future<void> _launchSubscriptionManagement(BuildContext context) async {
    final Uri url = Platform.isAndroid
        ? Uri.parse("https://play.google.com/store/account/subscriptions")
        : Uri.parse("https://apps.apple.com/account/subscriptions");

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open subscription settings.")),
        );
      }
    }
  }

  /// Processes the upgrade to Pro
  Future<void> _purchasePro(BuildContext context) async {
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Processing..."), duration: Duration(seconds: 1)),
    );
    
    bool success = await ProService().purchasePro();
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Welcome to MindFlash Pro! 🎉"), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).textTheme.bodyLarge?.color),
        title: const Text("Manage Subscription", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: AnimatedBuilder(
        animation: ProService(),
        builder: (context, child) {
          final isPro = ProService().isPro;

          return ListView(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            children: [
              const Text(
                "Choose Your Plan",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "Select the plan that best fits your study needs.",
                style: TextStyle(fontSize: 15, color: isDark ? Colors.white54 : Colors.grey.shade600),
              ),
              const SizedBox(height: 32),

              // ----------------------------------------------------------------
              // FREE TIER CARD
              // ----------------------------------------------------------------
              _buildPlanCard(
                context: context,
                isDark: isDark,
                title: "MindFlash Free",
                price: "Free",
                isActive: !isPro,
                features: [
                  "15 Daily AI Energy",
                  "Basic Spaced Repetition",
                  "Standard deck creation",
                  "Ad-supported experience",
                ],
                actionButton: !isPro
                    ? _buildStatusBadge("Current Plan", Colors.grey)
                    : _buildActionButton(
                        label: "Downgrade to Free",
                        color: isDark ? Colors.white24 : Colors.grey.shade300,
                        textColor: isDark ? Colors.white : Colors.black87,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _launchSubscriptionManagement(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("To downgrade, please cancel your active subscription in the store.")),
                          );
                        },
                      ),
              ),

              const SizedBox(height: 24),

              // ----------------------------------------------------------------
              // PRO TIER CARD
              // ----------------------------------------------------------------
              _buildPlanCard(
                context: context,
                isDark: isDark,
                title: "MindFlash Pro",
                price: "\$1.00 / month",
                isActive: isPro,
                isPremium: true,
                features: [
                  "30 Daily AI Energy",
                  "Advanced AI Tutor features",
                  "Completely Ad-Free studying",
                  "Priority support",
                ],
                actionButton: isPro
                    ? _buildStatusBadge("Active Plan", Colors.green)
                    : _buildActionButton(
                        label: "Upgrade to Pro",
                        color: const Color(0xFFE841A1),
                        textColor: Colors.white,
                        isPremium: true,
                        onTap: () => _purchasePro(context),
                      ),
              ),

              const SizedBox(height: 40),
              Center(
                child: TextButton(
                  onPressed: () async {
                    HapticFeedback.lightImpact();
                    bool success = await ProService().restorePurchases();
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Purchases Restored!"), backgroundColor: Colors.green),
                      );
                    }
                  },
                  child: const Text("Restore Purchases", style: TextStyle(color: Colors.grey)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPlanCard({
    required BuildContext context,
    required bool isDark,
    required String title,
    required String price,
    required bool isActive,
    required List<String> features,
    required Widget actionButton,
    bool isPremium = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isActive 
              ? (isPremium ? const Color(0xFFE841A1) : Colors.grey.shade400) 
              : (isDark ? Colors.white.withOpacity(0.05) : Colors.transparent),
          width: isActive ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isPremium && isActive
                ? const Color(0xFFE841A1).withOpacity(0.15)
                : Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              if (isPremium)
                const Icon(Icons.workspace_premium_rounded, color: Color(0xFFE841A1)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            price,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isPremium ? const Color(0xFFE841A1) : (isDark ? Colors.white70 : Colors.black87),
            ),
          ),
          const SizedBox(height: 24),
          ...features.map((feature) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 20,
                  color: isPremium ? const Color(0xFF8B4EFF) : Colors.grey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    feature,
                    style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black87),
                  ),
                ),
              ],
            ),
          )),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: actionButton,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
    bool isPremium = false,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(vertical: 16),
        elevation: isPremium ? 4 : 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }
}