import 'package:flutter/material.dart';
import '../../../models/deck_model.dart';

class DeckInfoCard extends StatelessWidget {
  final Deck deck;
  final VoidCallback onSettings;
  final LinearGradient brandGradient;

  const DeckInfoCard({
    super.key,
    required this.deck,
    required this.onSettings,
    required this.brandGradient,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String firstLetter = deck.name.isNotEmpty ? deck.name[0].toUpperCase() : "?";

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white12
              : const Color(0xFF8B4EFF).withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black45
                : const Color(0xFF8B4EFF).withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: brandGradient,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B4EFF).withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                firstLetter,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 28,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deck.name,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  deck.subject,
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.grey.shade600,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF8B4EFF).withValues(alpha: 0.15)
                        : const Color(0xFFF4F6FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    "${deck.cardCount} card${deck.cardCount == 1 ? '' : 's'}",
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFFB48AFF)
                          : const Color(0xFF5A6DFF),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onSettings,
            icon: Icon(
              Icons.settings_rounded,
              color: isDark ? Colors.white38 : Colors.grey.shade400,
              size: 26,
            ),
            tooltip: 'Deck Settings',
          ),
        ],
      ),
    );
  }
}
