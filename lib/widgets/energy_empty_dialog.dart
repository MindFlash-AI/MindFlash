import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../screens/settings/manage_subscription_screen.dart';
import '../../services/pro_service.dart';

class EnergyEmptyDialog extends StatelessWidget {
  final String actionText;
  final VoidCallback onWatchAd;

  const EnergyEmptyDialog({
    super.key,
    required this.actionText,
    required this.onWatchAd,
  });

  static void show(BuildContext context, {required String actionText, required VoidCallback onWatchAd}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => EnergyEmptyDialog(actionText: actionText, onWatchAd: onWatchAd),
    );
  }

  void _handleTopUp(BuildContext context, int amount, double price) {
    // Placeholder for actual Stripe checkout integration
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Stripe Checkout for $amount credits (\$${price.toStringAsFixed(2)}) coming soon!"),
        backgroundColor: const Color(0xFF8B4EFF),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPro = ProService().isPro;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String description = "";
    if (kIsWeb) {
      description = isPro
          ? "Out of energy! Buy extra credits to keep studying and generating cards today."
          : "You've used your 15 daily credits! Upgrade to MindFlash Pro to get 750 monthly credits and unlock the Web App.";
    } else {
      description = isPro
          ? "You've used your 750 monthly credits! To keep studying today, watch a sponsored message or top-up your account."
          : "$actionText costs energy. You've used your 15 daily credits! Watch an ad to keep studying, or upgrade to Pro for 750 monthly credits!";
    }

    return Dialog(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.bolt_rounded, color: Colors.orange, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Out of Energy ⚡", 
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
                ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              description,
              style: TextStyle(fontSize: 15, color: Theme.of(context).textTheme.bodyMedium?.color, height: 1.4),
            ),
            const SizedBox(height: 28),

            if (isPro) ...[
              // PRO USERS TOP-UP UI
              if (!kIsWeb) ...[
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onWatchAd();
                  },
                  icon: const Icon(Icons.play_circle_filled_rounded, color: Colors.white),
                  label: const Text("Watch Sponsored Message (+30 ⚡)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE940A3),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: Divider(color: isDark ? Colors.white24 : Colors.grey.shade300)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text("OR TOP UP", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white54 : Colors.grey)),
                    ),
                    Expanded(child: Divider(color: isDark ? Colors.white24 : Colors.grey.shade300)),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              Row(
                children: [
                  Expanded(child: _buildTopUpButton(context, 500, 1.50)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTopUpButton(context, 1000, 2.50)),
                ],
              ),
            ] else ...[
              // FREE USERS UI
              if (!kIsWeb)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                onWatchAd();
              },
                  icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                  label: const Text("Watch Ad (+15 ⚡)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE940A3),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageSubscriptionScreen()));
                },
                icon: const Icon(Icons.workspace_premium_rounded, color: Color(0xFF8B4EFF)),
                label: const Text("Upgrade to Pro", style: TextStyle(color: Color(0xFF8B4EFF), fontWeight: FontWeight.bold, fontSize: 15)),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B4EFF).withValues(alpha: 0.1), elevation: 0, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              ),
            ],

            const SizedBox(height: 8),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.grey, fontSize: 15))),
          ],
        ),
      ),
    );
  }

  Widget _buildTopUpButton(BuildContext context, int amount, double price) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () => _handleTopUp(context, amount, price),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF8B4EFF).withValues(alpha: 0.1) : const Color(0xFFF4F6FF),
          border: Border.all(color: const Color(0xFF8B4EFF).withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text("+$amount ⚡", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF8B4EFF))),
            const SizedBox(height: 4),
            Text("\$${price.toStringAsFixed(2)}", style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87)),
          ],
        ),
      ),
    );
  }
}