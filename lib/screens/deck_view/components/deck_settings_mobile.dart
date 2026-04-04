import 'package:flutter/material.dart';
import 'deck_settings_screen.dart'; // Imports SaveState Enum

// ==========================================
// MOBILE UI (TabBar Pattern)
// ==========================================
class DeckSettingsMobile extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController subjectController;
  final SaveState saveState;
  final int cardCount;
  final VoidCallback onResetProgress;
  final VoidCallback onDeleteAllCards;
  final VoidCallback onCancel;

  const DeckSettingsMobile({
    super.key,
    required this.nameController,
    required this.subjectController,
    required this.saveState,
    required this.cardCount,
    required this.onResetProgress,
    required this.onDeleteAllCards,
    required this.onCancel,
  });

  Widget _buildSaveIndicator(BuildContext context) {
    IconData icon;
    Color color;
    String text;

    switch (saveState) {
      case SaveState.saved:
        icon = Icons.cloud_done_rounded;
        color = Colors.green;
        text = "Saved";
        break;
      case SaveState.typing:
        icon = Icons.edit_rounded;
        color = Colors.grey;
        text = "Editing...";
        break;
      case SaveState.error:
        icon = Icons.error_outline_rounded;
        color = Colors.redAccent;
        text = "Missing fields";
        break;
      case SaveState.saving:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              height: 14, width: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF8B4EFF)),
            ),
            const SizedBox(width: 8),
            Text("Saving...", style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildInputLabel(BuildContext context, String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF8B4EFF)),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildTextFormField(BuildContext context, {
    required TextEditingController controller,
    required String hint,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return TextFormField(
      controller: controller,
      autovalidateMode: AutovalidateMode.always,
      validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
      textCapitalization: TextCapitalization.words,
      style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade400, fontSize: 15),
        filled: true,
        fillColor: isDark ? const Color(0xFF1E1533) : const Color(0xFFF8F9FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF8B4EFF), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildGeneralTab(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24.0),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: isDark ? Border.all(color: Colors.white.withOpacity(0.05)) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInputLabel(context, "Deck Name", Icons.style_rounded),
            const SizedBox(height: 8),
            _buildTextFormField(
              context,
              controller: nameController,
              hint: "e.g., Biology 101",
            ),
            const SizedBox(height: 20),
            _buildInputLabel(context, "Subject", Icons.bookmark_border_rounded),
            const SizedBox(height: 8),
            _buildTextFormField(
              context,
              controller: subjectController,
              hint: "e.g., Science",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerZoneTab(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24.0),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.redAccent.withOpacity(0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.redAccent.withOpacity(isDark ? 0.1 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            ListTile(
              onTap: cardCount > 0 ? onResetProgress : null,
              title: Text(
                "Reset Study Progress",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: cardCount > 0 ? Colors.orange : Colors.grey,
                ),
              ),
              subtitle: Text(
                "Clear mastered flags and SRS data",
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white54 : Colors.grey.shade600,
                ),
              ),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cardCount > 0 ? Colors.orange.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.refresh_rounded, color: cardCount > 0 ? Colors.orange : Colors.grey),
              ),
            ),
            Divider(height: 1, indent: 60, color: isDark ? Colors.white12 : Colors.grey.shade200),
            ListTile(
              onTap: cardCount > 0 ? onDeleteAllCards : null,
              title: Text(
                "Delete All Cards",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: cardCount > 0 ? Colors.redAccent : Colors.grey,
                ),
              ),
              subtitle: Text(
                "Erase all $cardCount cards in this deck",
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white54 : Colors.grey.shade600,
                ),
              ),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cardCount > 0 ? Colors.redAccent.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.delete_sweep_rounded, color: cardCount > 0 ? Colors.redAccent : Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: Theme.of(context).textTheme.bodyLarge?.color),
            onPressed: onCancel,
          ),
          title: Text(
            "Settings",
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          actions: [
            Center(child: _buildSaveIndicator(context)),
            const SizedBox(width: 16),
          ],
          bottom: const TabBar(
            labelColor: Color(0xFF8B4EFF),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF8B4EFF),
            tabs: [
              Tab(text: "General"),
              Tab(text: "Danger Zone"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildGeneralTab(context),
            _buildDangerZoneTab(context),
          ],
        ),
      ),
    );
  }
}