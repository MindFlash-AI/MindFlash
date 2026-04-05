import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum SidebarActiveItem { dashboard, studyPad, none }

class UniversalSidebar extends StatelessWidget {
  final SidebarActiveItem activeItem;
  final VoidCallback? onDashboardTap;
  final VoidCallback? onStudyPadTap;
  final VoidCallback? onWebsiteTap;
  final bool showMinimizeButton;
  final VoidCallback? onMinimizeTap;

  const UniversalSidebar({
    super.key,
    required this.activeItem,
    this.onDashboardTap,
    this.onStudyPadTap,
    this.onWebsiteTap,
    this.showMinimizeButton = false,
    this.onMinimizeTap,
  });

  Widget _buildSidebarItem(BuildContext context, bool isDark, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: isActive ? [
          BoxShadow(
            color: const Color(0xFF8B4EFF).withValues(alpha: isDark ? 0.3 : 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ] : [],
      ),
      child: Material(
        color: isActive 
            ? (isDark ? const Color(0xFF8B4EFF).withValues(alpha: 0.2) : Colors.white)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive 
                    ? const Color(0xFF8B4EFF).withValues(alpha: 0.4) 
                    : Colors.transparent,
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(
                  icon, 
                  color: isActive ? const Color(0xFF8B4EFF) : (isDark ? Colors.white54 : Colors.black54),
                  size: 22,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                    color: isActive ? const Color(0xFF8B4EFF) : (isDark ? Colors.white70 : Colors.black87),
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      color: isDark ? const Color(0xFF130E24) : Theme.of(context).cardColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo & Minimize Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8), 
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8B4EFF), Color(0xFFE841A1)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "MindFlash",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5, color: Theme.of(context).textTheme.bodyLarge?.color),
                      ),
                    ],
                  ),
                  if (showMinimizeButton)
                    IconButton(
                      icon: Icon(Icons.keyboard_double_arrow_left_rounded, color: isDark ? Colors.white54 : Colors.black54),
                      onPressed: onMinimizeTap,
                      tooltip: "Minimize Sidebar",
                    ),
                ],
              ),
              
              const SizedBox(height: 32),
              Divider(color: isDark ? Colors.white12 : Colors.grey.shade200, height: 1),
              const SizedBox(height: 24),
              
              Text(
                "MENU",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: isDark ? Colors.white38 : Colors.black38),
              ),
              const SizedBox(height: 16),
              
              _buildSidebarItem(context, isDark, icon: Icons.dashboard_rounded, title: "Dashboard", isActive: activeItem == SidebarActiveItem.dashboard, onTap: onDashboardTap ?? () {}),
              _buildSidebarItem(context, isDark, icon: Icons.edit_note_rounded, title: "Study Pad", isActive: activeItem == SidebarActiveItem.studyPad, onTap: onStudyPadTap ?? () {}),

              const Spacer(),
              
              Divider(color: isDark ? Colors.white12 : Colors.grey.shade200, height: 1),
              const SizedBox(height: 16),
              _buildSidebarItem(context, isDark, icon: Icons.public_rounded, title: "Back to Website", onTap: onWebsiteTap ?? () {}),
            ],
          ),
        ),
      ),
    );
  }
}