import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb; 
import 'widgets/dashboard_header.dart';

class DashboardWeb extends StatelessWidget {
  final Widget sidebar;
  final Widget overview;
  final Widget deckList;
  final Widget actions;

  const DashboardWeb({
    super.key,
    required this.sidebar,
    required this.overview,
    required this.deckList,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Row(
        children: [
          // 🛡️ Sidebar Wrapper
          if (kIsWeb)
            Container(
              width: 260,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF130E24) : Theme.of(context).cardColor,
                border: Border(
                  right: BorderSide(color: isDark ? Colors.white12 : Colors.black.withOpacity(0.05)),
                ),
              ),
              child: sidebar,
            ),

          // 🛡️ Main Dashboard Content Area
          Expanded(
            child: Column(
              children: [
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(32, 20, 32, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Flexible(child: DashboardHeader()),
                            const SizedBox(width: 24),
                            actions, 
                          ],
                        ),
                        const SizedBox(height: 32),
                        Text(
                          "Overview",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 16),
                        overview, 
                      ],
                    ),
                  ),
                ),
        
                Expanded(
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    decoration: BoxDecoration(
                      // 🛡️ FIX: Replaced the hardcoded dark gradient with proper clean theme colors
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: isDark ? Colors.white12 : Colors.black.withOpacity(0.03),
                        width: 1.5,
                      ),
                      boxShadow: isDark ? [] : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: deckList, 
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}