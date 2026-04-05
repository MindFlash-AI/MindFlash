import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FeedbackDialog extends StatelessWidget {
  final bool isSuccess;
  final String message;

  const FeedbackDialog({
    super.key,
    required this.isSuccess,
    required this.message,
  });

  static void show(BuildContext context, bool isSuccess, String message) {
    showDialog(
      context: context,
      builder: (context) => FeedbackDialog(isSuccess: isSuccess, message: message),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 20,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSuccess
                    ? (isDark ? Colors.green.withValues(alpha: 0.15) : Colors.green.shade50)
                    : (isDark ? Colors.red.withValues(alpha: 0.15) : Colors.red.shade50),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSuccess ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded,
                color: isSuccess
                    ? (isDark ? Colors.greenAccent : Colors.green)
                    : (isDark ? Colors.redAccent : Colors.redAccent),
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isSuccess ? "Success!" : "Oops!",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Theme.of(context).textTheme.bodyLarge?.color,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.white70 : Colors.grey.shade700,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSuccess
                      ? const Color(0xFF5B4FE6)
                      : (isDark ? Colors.redAccent.shade200 : Colors.redAccent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  isSuccess ? "Awesome" : "Close",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
