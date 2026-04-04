import 'package:flutter/material.dart';
import 'deck_settings_screen.dart'; // Imports SaveState Enum

// ==========================================
// WEB / DESKTOP UI (Navigation Rail Pattern)
// ==========================================
class DeckSettingsWeb extends StatefulWidget {
  final TextEditingController nameController;
  final TextEditingController subjectController;
  final SaveState saveState;
  final int cardCount;
  final VoidCallback onResetProgress;
  final VoidCallback onDeleteAllCards;
  final VoidCallback onCancel;

  const DeckSettingsWeb({
    super.key,
    required this.nameController,
    required this.subjectController,
    required this.saveState,
    required this.cardCount,
    required this.onResetProgress,
    required this.onDeleteAllCards,
    required this.onCancel,
  });

  @override
  State<DeckSettingsWeb> createState() => _DeckSettingsWebState();
}

class _DeckSettingsWebState extends State<DeckSettingsWeb> {
  int _selectedIndex = 0;

  Widget _buildSaveIndicator(BuildContext context) {
    IconData icon;
    Color color;
    String text;

    switch (widget.saveState) {
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

  Widget _buildGeneralTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "General Information",
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(32),
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
                controller: widget.nameController,
                hint: "e.g., Biology 101",
              ),
              const SizedBox(height: 24),
              _buildInputLabel(context, "Subject", Icons.bookmark_border_rounded),
              const SizedBox(height: 8),
              _buildTextFormField(
                context,
                controller: widget.subjectController,
                hint: "e.g., Science",
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDangerZoneTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Danger Zone",
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.redAccent),
        ),
        const SizedBox(height: 32),
        Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.redAccent.withOpacity(0.05) : Colors.red.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.redAccent.withOpacity(0.3), width: 1),
          ),
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                onTap: widget.cardCount > 0 ? widget.onResetProgress : null,
                title: Text(
                  "Reset Study Progress",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: widget.cardCount > 0 ? Colors.orange : Colors.grey,
                  ),
                ),
                subtitle: Text(
                  "Clear mastered flags and SRS data",
                  style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : Colors.grey.shade600),
                ),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.cardCount > 0 ? Colors.orange.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.refresh_rounded, color: widget.cardCount > 0 ? Colors.orange : Colors.grey),
                ),
              ),
              Divider(height: 1, indent: 72, color: Colors.redAccent.withOpacity(0.2)),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                onTap: widget.cardCount > 0 ? widget.onDeleteAllCards : null,
                title: Text(
                  "Delete All Cards",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: widget.cardCount > 0 ? Colors.redAccent : Colors.grey,
                  ),
                ),
                subtitle: Text(
                  "Erase all ${widget.cardCount} cards in this deck",
                  style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : Colors.grey.shade600),
                ),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.cardCount > 0 ? Colors.redAccent.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.delete_sweep_rounded, color: widget.cardCount > 0 ? Colors.redAccent : Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: Theme.of(context).textTheme.bodyLarge?.color),
          onPressed: widget.onCancel,
        ),
        title: Text(
          "Deck Settings",
          style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        actions: [
          Center(child: _buildSaveIndicator(context)),
          const SizedBox(width: 24),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            selectedIconTheme: const IconThemeData(color: Color(0xFF8B4EFF)),
            selectedLabelTextStyle: const TextStyle(color: Color(0xFF8B4EFF), fontWeight: FontWeight.bold),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.info_outline_rounded),
                selectedIcon: Icon(Icons.info_rounded),
                label: Text('General'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                selectedIcon: Icon(Icons.warning_rounded, color: Colors.redAccent),
                label: Text('Danger Zone', style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          ),
          VerticalDivider(thickness: 1, width: 1, color: Theme.of(context).dividerColor.withOpacity(0.1)),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                  child: _selectedIndex == 0 ? _buildGeneralTab() : _buildDangerZoneTab(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}