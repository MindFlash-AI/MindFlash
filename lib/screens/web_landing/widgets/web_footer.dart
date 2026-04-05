import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../web_landing_screen.dart'; // Imported to access the HoverScale widget
import '../../../constants/legal_texts.dart';
import '../../../widgets/dialogs/legal_document_dialog.dart';

class WebFooter extends StatelessWidget {
  const WebFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 40, horizontal: isMobile ? 32 : 64),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05))),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: isMobile
              ? Column(
                  children: [
                    _buildFooterLogo(context),
                    const SizedBox(height: 24),
                    _buildFooterLinks(context, isDark),
                    const SizedBox(height: 24),
                    Text(
                      "© ${DateTime.now().year} MindFlash. All rights reserved.",
                      style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 14),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFooterLogo(context),
                        const SizedBox(height: 12),
                        Text(
                          "© ${DateTime.now().year} MindFlash. All rights reserved.",
                          style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 14),
                        ),
                      ],
                    ),
                    _buildFooterLinks(context, isDark),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildFooterLogo(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.bolt_rounded, color: Color(0xFF8B4EFF), size: 24),
        const SizedBox(width: 8),
        Text(
          "MindFlash",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildFooterLinks(BuildContext context, bool isDark) {
    return Wrap(
      spacing: 24,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        HoverScale(
          scaleFactor: 1.05,
          onTap: () {
            HapticFeedback.lightImpact();
            LegalDocumentDialog.show(context, "Privacy Policy", LegalTexts.privacyPolicy);
          },
          child: _buildFooterLink("Privacy Policy", isDark),
        ),
        HoverScale(
          scaleFactor: 1.05,
          onTap: () {
            HapticFeedback.lightImpact();
            LegalDocumentDialog.show(context, "Terms of Service", LegalTexts.termsOfService);
          },
          child: _buildFooterLink("Terms of Service", isDark),
        ),
        HoverScale(
          scaleFactor: 1.05,
          onTap: () {
            HapticFeedback.lightImpact();
            LegalDocumentDialog.show(context, "Data Compliance", LegalTexts.dataCompliance);
          },
          child: _buildFooterLink("Data Compliance", isDark),
        ),
        HoverScale(child: _buildFooterLink("Contact Support", isDark), scaleFactor: 1.05),
      ],
    );
  }

  Widget _buildFooterLink(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        color: isDark ? Colors.white70 : Colors.black87,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
    );
  }
}