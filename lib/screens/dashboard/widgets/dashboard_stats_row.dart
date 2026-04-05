import 'package:flutter/material.dart';
import '../../../services/energy_service.dart';
import '../../../widgets/stat_card.dart';
import '../../../models/deck_model.dart';

class DashboardStatsRow extends StatelessWidget {
  final List<Deck> decks;
  final int totalCards;
  final bool isDark;
  final double maxWidth;

  const DashboardStatsRow({
    super.key,
    required this.decks,
    required this.totalCards,
    required this.isDark,
    required this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
        stream: EnergyService().energyStream,
        initialData: EnergyService().currentEnergy,
        builder: (context, snapshot) {
          final currentEnergy = snapshot.data ?? EnergyService().maxEnergy;
          final maxEnergy = EnergyService().maxEnergy;

          final statCards = [
            StatCard(
              title: "Total Decks",
              count: decks.length.toString(),
              icon: Icons.chrome_reader_mode_outlined,
              colors: isDark
                  ? const [Color(0xFF533E9E), Color(0xFF382773)]
                  : const [Color(0xFF6366F1), Color(0xFF4F46E5)],
              shadowColor: isDark
                  ? Colors.black87
                  : const Color(0xFF4F46E5).withValues(alpha: 0.3),
            ),
            StatCard(
              title: "Total Cards",
              count: totalCards.toString(),
              icon: Icons.library_books_rounded,
              colors: isDark
                  ? const [Color(0xFF863B6B), Color(0xFF5E244B)]
                  : const [Color(0xFFEC4899), Color(0xFFDB2777)],
              shadowColor: isDark
                  ? Colors.black87
                  : const Color(0xFFDB2777).withValues(alpha: 0.3),
            ),
            StatCard(
              title: "AI Energy",
              count: "$currentEnergy / $maxEnergy",
              icon: Icons.electric_bolt_rounded,
              colors: isDark
                  ? const [Color(0xFF0F766E), Color(0xFF172554)]
                  : const [Color(0xFF0EA5E9), Color(0xFF0284C7)],
              shadowColor: isDark
                  ? Colors.black87
                  : const Color(0xFF0284C7).withValues(alpha: 0.3),
            ),
          ];

          final isLandscape =
              MediaQuery.of(context).orientation == Orientation.landscape;

          if (maxWidth >= 850 || (isLandscape && maxWidth >= 600)) {
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: statCards[0]),
                  const SizedBox(width: 16),
                  Expanded(child: statCards[1]),
                  const SizedBox(width: 16),
                  Expanded(child: statCards[2]),
                ],
              ),
            );
          } else {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              clipBehavior: Clip.none,
              child: Row(
                children: [
                  statCards[2],
                  const SizedBox(width: 12),
                  statCards[0],
                  const SizedBox(width: 12),
                  statCards[1],
                ],
              ),
            );
          }
        });
  }
}
