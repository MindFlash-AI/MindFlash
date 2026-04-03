import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb; 
import 'widgets/dashboard_header.dart';

class DashboardMobile extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final Widget sidebar;
  final Widget overview;
  final Widget deckList;
  final Widget actions;

  const DashboardMobile({
    super.key,
    required this.scaffoldKey,
    required this.sidebar,
    required this.overview,
    required this.deckList,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const double maxContentWidth = 800; 

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      
      drawer: kIsWeb ? Drawer(
        backgroundColor: isDark ? const Color(0xFF130E24) : Theme.of(context).cardColor,
        child: sidebar,
      ) : null,
      
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxContentWidth),
          child: Column(
            children: [
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (kIsWeb)
                            IconButton(
                              icon: Icon(Icons.menu_rounded, size: 28, color: Theme.of(context).textTheme.bodyLarge?.color),
                              onPressed: () => scaffoldKey.currentState?.openDrawer(),
                            ),
                          const Flexible(child: DashboardHeader()),
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
                  decoration: BoxDecoration(
                    // 🛡️ FIX: Replaced the hardcoded dark gradient with proper clean theme colors
                    color: Theme.of(context).cardColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                    boxShadow: isDark ? [] : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 20,
                        offset: const Offset(0, -4),
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                    child: Column(
                      children: [
                        Expanded(child: deckList), 
                        
                        SafeArea(
                          top: false,
                          bottom: true,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                            child: actions, 
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}