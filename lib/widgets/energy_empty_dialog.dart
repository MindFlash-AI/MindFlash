import 'package:flutter/material.dart';
import '../../screens/settings/manage_subscription_screen.dart';

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

  @override
  Widget build(BuildContext context) {
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
                Text(
                  "Out of Energy", 
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              "$actionText costs 3 energy. Watch a quick ad to refill your energy, or upgrade to MindFlash Pro for double the daily limit and no ads!",
              style: TextStyle(fontSize: 15, color: Theme.of(context).textTheme.bodyMedium?.color, height: 1.4),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                onWatchAd();
              },
              icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
              label: const Text("Watch Ad to Refill", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
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
            const SizedBox(height: 8),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.grey, fontSize: 15))),
          ],
        ),
      ),
    );
  }
}