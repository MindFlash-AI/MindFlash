import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../../models/deck_model.dart';
import '../../../widgets/deck_list_item.dart';
import '../dashboard_screen.dart'; // For SortOption

class DashboardDeckListView extends StatelessWidget {
  final List<Deck> decks;
  final bool isDark;
  final bool isLoading;
  final SortOption currentSort;
  final ValueChanged<SortOption> onSortChanged;
  final NativeAd? nativeAd;
  final bool isNativeAdLoaded;
  final Function(String) onDeleteDeck;
  final Function(Deck) onDeckTap;

  const DashboardDeckListView({
    super.key,
    required this.decks,
    required this.isDark,
    required this.isLoading,
    required this.currentSort,
    required this.onSortChanged,
    this.nativeAd,
    required this.isNativeAdLoaded,
    required this.onDeleteDeck,
    required this.onDeckTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildDeckListSkeleton(context);
    }

    if (decks.isEmpty) {
      return const SizedBox.shrink(); // Handled by DashboardEmptyState
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          decoration: BoxDecoration(
            color: isDark ? Theme.of(context).cardColor : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
            border: Border(
              bottom: BorderSide(
                color: isDark ? Colors.white12 : Colors.grey.shade100,
                width: 1,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "My Decks",
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  PopupMenuButton<SortOption>(
                    icon: Icon(
                      Icons.sort_rounded,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      size: 24,
                    ),
                    color: Theme.of(context).cardColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    onSelected: (SortOption option) {
                      HapticFeedback.selectionClick();
                      onSortChanged(option);
                    },
                    itemBuilder: (context) => [
                      _buildSortMenuItem(context, SortOption.nameAsc,
                          "Name (A to Z)", Icons.sort_by_alpha),
                      _buildSortMenuItem(context, SortOption.nameDesc,
                          "Name (Z to A)", Icons.sort_by_alpha),
                      _buildSortMenuItem(context, SortOption.countDesc,
                          "Cards (High to Low)", Icons.format_list_numbered),
                      _buildSortMenuItem(context, SortOption.countAsc,
                          "Cards (Low to High)", Icons.format_list_numbered_rtl),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Storage Quota",
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color:
                              isDark ? Colors.white54 : Colors.grey.shade600)),
                  Text("${decks.length} / 20 Decks",
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: decks.length >= 18
                              ? Colors.redAccent
                              : const Color(0xFF8B4EFF))),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (decks.length / 20.0).clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor:
                      isDark ? Colors.white12 : Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(decks.length >= 18
                      ? Colors.redAccent
                      : const Color(0xFF8B4EFF)),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 380,
              mainAxisExtent: 140,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
            ),
            itemCount: decks.length + (isNativeAdLoaded ? 1 : 0),
            itemBuilder: (context, index) {
              final int adIndex = decks.length >= 2 ? 2 : decks.length;

              if (isNativeAdLoaded && index == adIndex) {
                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : const Color.fromARGB(255, 224, 224, 224),
                        width: 2),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 16))
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: AdWidget(ad: nativeAd!),
                );
              }

              final int deckIndex =
                  (isNativeAdLoaded && index > adIndex) ? index - 1 : index;
              final deck = decks[deckIndex];
              final int delayMultiplier = deckIndex.clamp(0, 10);

              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 400 + (delayMultiplier * 50)),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 30 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: DeckListItem(
                  deck: deck,
                  onDelete: () => onDeleteDeck(deck.id),
                  onTap: () => onDeckTap(deck),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  PopupMenuItem<SortOption> _buildSortMenuItem(
      BuildContext context, SortOption value, String text, IconData icon) {
    final isSelected = currentSort == value;
    return PopupMenuItem<SortOption>(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            color: isSelected
                ? const Color(0xFF8B4EFF)
                : (isDark ? Colors.white70 : Colors.grey.shade700),
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              color: isSelected
                  ? const Color(0xFF8B4EFF)
                  : Theme.of(context).textTheme.bodyLarge?.color,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeckListSkeleton(BuildContext context) {
    final baseColor = isDark ? Colors.white10 : Colors.grey.shade300;
    final highlightColor = isDark ? Colors.white24 : Colors.grey.shade100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          decoration: BoxDecoration(
            color: isDark ? Theme.of(context).cardColor : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
            border: Border(
              bottom: BorderSide(
                  color: isDark ? Colors.white12 : Colors.grey.shade100,
                  width: 1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Shimmer.fromColors(
                    baseColor: baseColor,
                    highlightColor: highlightColor,
                    child: Container(
                        width: 120,
                        height: 24,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6))),
                  ),
                  Shimmer.fromColors(
                    baseColor: baseColor,
                    highlightColor: highlightColor,
                    child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6))),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Shimmer.fromColors(
                    baseColor: baseColor,
                    highlightColor: highlightColor,
                    child: Container(
                        width: 80,
                        height: 16,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4))),
                  ),
                  Shimmer.fromColors(
                    baseColor: baseColor,
                    highlightColor: highlightColor,
                    child: Container(
                        width: 60,
                        height: 16,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4))),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Shimmer.fromColors(
                baseColor: baseColor,
                highlightColor: highlightColor,
                child: Container(
                    width: double.infinity,
                    height: 6,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4))),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 380,
              mainAxisExtent: 140,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
            ),
            itemCount: 8,
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : const Color.fromARGB(255, 224, 224, 224),
                      width: 2),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 16))
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Shimmer.fromColors(
                        baseColor: baseColor,
                        highlightColor: highlightColor,
                        child: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14)))),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Shimmer.fromColors(
                              baseColor: baseColor,
                              highlightColor: highlightColor,
                              child: Container(
                                  width: double.infinity,
                                  height: 18,
                                  decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(6)))),
                          const SizedBox(height: 8),
                          Shimmer.fromColors(
                              baseColor: baseColor,
                              highlightColor: highlightColor,
                              child: Container(
                                  width: 100,
                                  height: 14,
                                  decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(4)))),
                          const SizedBox(height: 12),
                          Shimmer.fromColors(
                              baseColor: baseColor,
                              highlightColor: highlightColor,
                              child: Container(
                                  width: 60,
                                  height: 20,
                                  decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(6)))),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Shimmer.fromColors(
                        baseColor: baseColor,
                        highlightColor: highlightColor,
                        child: Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                                color: Colors.white, shape: BoxShape.circle))),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
