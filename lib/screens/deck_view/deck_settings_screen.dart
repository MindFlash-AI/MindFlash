import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/deck_model.dart';
import '../../services/deck_storage_service.dart';
import '../../services/card_storage_service.dart';

class DeckSettingsScreen extends StatefulWidget {
  final Deck deck;

  const DeckSettingsScreen({super.key, required this.deck});

  @override
  State<DeckSettingsScreen> createState() => _DeckSettingsScreenState();
}

class _DeckSettingsScreenState extends State<DeckSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final DeckStorageService _deckStorageService = DeckStorageService();
  final CardStorageService _cardStorageService = CardStorageService();

  late TextEditingController _nameController;
  late TextEditingController _subjectController;
  
  bool _isSaving = false;
  bool _hasChanges = false; // Tracks if we need to reload the parent screen

  final LinearGradient _brandGradient = const LinearGradient(
    colors: [Color(0xFF8B4EFF), Color(0xFFE841A1)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.deck.name);
    _subjectController = TextEditingController(text: widget.deck.subject);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  void _saveDetails() async {
    if (_formKey.currentState!.validate()) {
      HapticFeedback.mediumImpact();
      setState(() => _isSaving = true);

      final updatedDeck = Deck(
        id: widget.deck.id,
        name: _nameController.text.trim(),
        subject: _subjectController.text.trim(),
        cardCount: widget.deck.cardCount,
      );

      await _deckStorageService.updateDeck(updatedDeck);

      setState(() {
        _isSaving = false;
        _hasChanges = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Deck details updated!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to trigger reload
      }
    }
  }

  void _confirmResetProgress() async {
    HapticFeedback.heavyImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Row(
          children: [
            const Icon(Icons.refresh_rounded, color: Colors.orange),
            const SizedBox(width: 8),
            Text(
              "Reset Progress?",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
        content: Text(
          "This will reset all your mastery, flags, and Spaced Repetition (SRS) stats for this deck back to zero. You cannot undo this.",
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.orange.withOpacity(0.2) : Colors.orange.shade50,
              foregroundColor: Colors.orange,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Reset", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _cardStorageService.resetStatsForDeck(widget.deck.id);
      _hasChanges = true;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Study progress has been reset."),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _confirmDeleteAllCards() async {
    HapticFeedback.heavyImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            const SizedBox(width: 8),
            Text(
              "Delete All Cards?",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
        content: Text(
          "Are you absolutely sure you want to delete all ${widget.deck.cardCount} cards in this deck? This cannot be undone.",
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.red.withOpacity(0.2) : Colors.red.shade50,
              foregroundColor: Colors.redAccent,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Delete All", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _cardStorageService.deleteCardsByDeck(widget.deck.id);
      
      // Update deck count
      widget.deck.cardCount = 0;
      await _deckStorageService.updateDeck(widget.deck);
      
      _hasChanges = true;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("All cards deleted."),
            backgroundColor: Colors.redAccent,
          ),
        );
        Navigator.pop(context, true); // Pop back to deck view because it's empty now
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Theme.of(context).textTheme.bodyLarge?.color),
          onPressed: () => Navigator.pop(context, _hasChanges),
        ),
        title: Text(
          "Deck Settings",
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Edit Details Section ---
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                "EDIT DETAILS",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white38 : Colors.grey.shade500,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputLabel("Deck Name", Icons.style_rounded),
                    const SizedBox(height: 8),
                    _buildTextFormField(
                      controller: _nameController,
                      hint: "e.g., Biology 101",
                      validator: (val) => val == null || val.trim().isEmpty ? 'Name required' : null,
                    ),
                    const SizedBox(height: 20),
                    _buildInputLabel("Subject", Icons.bookmark_border_rounded),
                    const SizedBox(height: 8),
                    _buildTextFormField(
                      controller: _subjectController,
                      hint: "e.g., Science",
                      validator: (val) => val == null || val.trim().isEmpty ? 'Subject required' : null,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveDetails,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: _brandGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            child: _isSaving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text(
                                    "Save Changes",
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            // --- Danger Zone Section ---
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                "DANGER ZONE",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent.withOpacity(0.8),
                  letterSpacing: 1.2,
                ),
              ),
            ),
            Container(
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
                    onTap: widget.deck.cardCount > 0 ? _confirmResetProgress : null,
                    title: Text(
                      "Reset Study Progress",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: widget.deck.cardCount > 0 ? Colors.orange : Colors.grey,
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
                        color: widget.deck.cardCount > 0 ? Colors.orange.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.refresh_rounded, color: widget.deck.cardCount > 0 ? Colors.orange : Colors.grey),
                    ),
                  ),
                  Divider(height: 1, indent: 60, color: isDark ? Colors.white12 : Colors.grey.shade200),
                  ListTile(
                    onTap: widget.deck.cardCount > 0 ? _confirmDeleteAllCards : null,
                    title: Text(
                      "Delete All Cards",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: widget.deck.cardCount > 0 ? Colors.redAccent : Colors.grey,
                      ),
                    ),
                    subtitle: Text(
                      "Erase all ${widget.deck.cardCount} cards in this deck",
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white54 : Colors.grey.shade600,
                      ),
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: widget.deck.cardCount > 0 ? Colors.redAccent.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.delete_sweep_rounded, color: widget.deck.cardCount > 0 ? Colors.redAccent : Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label, IconData icon) {
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

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String hint,
    required String? Function(String?) validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return TextFormField(
      controller: controller,
      validator: validator,
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
}