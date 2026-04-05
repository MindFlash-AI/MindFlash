import 'package:flutter/material.dart';

class SettingsActionTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  final bool isDestructive;

  const SettingsActionTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isDestructive
            ? Border.all(color: iconColor.withValues(alpha: 0.3), width: 1)
            : (isDark ? Border.all(color: Colors.white.withValues(alpha: 0.05)) : null),
        boxShadow: [
          BoxShadow(
            color: isDestructive 
                ? iconColor.withValues(alpha: isDark ? 0.1 : 0.05) 
                : Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ListTile(
        onTap: onTap,
        title: Text(
          title, 
          style: TextStyle(fontWeight: FontWeight.w600, color: isDestructive ? iconColor : Theme.of(context).textTheme.bodyLarge?.color)
        ),
        subtitle: subtitle != null ? Text(subtitle!, style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : Colors.grey.shade600)) : null,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, color: iconColor),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }
}