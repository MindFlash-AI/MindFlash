import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/deck_model.dart';
import '../../../services/deck_storage_service.dart';
import '../../../services/card_storage_service.dart';

import 'deck_settings_mobile.dart';
import 'deck_settings_web.dart';

// Global Save State for Auto-Save functionality
enum SaveState { saved, saving, typing, error }

class DeckSettingsScreen extends StatefulWidget {
  final Deck deck;

  const DeckSettingsScreen({super.key, required this.deck});

  @override
  State<DeckSettingsScreen> createState() => _DeckSettingsScreenState();
}

class _DeckSettingsScreenState extends State<DeckSettingsScreen> {
  final DeckStorageService _deckStorageService = DeckStorageService();
  final CardStorageService _cardStorageService = CardStorageService();

  late TextEditingController _nameController;
  late TextEditingController _subjectController;
  late Deck _localDeck;
  
  SaveState _saveState = SaveState.saved;
  Timer? _debounceTimer;
  bool _hasChanges = false; 

  @override
  void initState() {
    super.initState();
    _localDeck = widget.deck;
    _nameController = TextEditingController(text: _localDeck.name);
    _subjectController = TextEditingController(text: _localDeck.subject);

    // Attach listeners for frictionless Auto-Save
    _nameController.addListener(_onTextChanged);
    _subjectController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _nameController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  // Evaluates text changes and triggers a debounced auto-save
  void _onTextChanged() {
    final name = _nameController.text.trim();
    final subject = _subjectController.text.trim();
    
    // 1. Validation check
    if (name.isEmpty || subject.isEmpty) {
      setState(() => _saveState = SaveState.error);
      _debounceTimer?.cancel();
      return;
    }
    
    // 2. Check if anything actually changed
    if (name == _localDeck.name && subject == _localDeck.subject) {
      setState(() => _saveState = SaveState.saved);
      _debounceTimer?.cancel();
      return;
    }

    // 3. Initiate Typing state and start debouncer
    setState(() => _saveState = SaveState.typing);
    
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 1000), _performAutoSave);
  }

  Future<void> _performAutoSave() async {
    setState(() => _saveState = SaveState.saving);

    final name = _nameController.text.trim();
    final subject = _subjectController.text.trim();

    _localDeck = Deck(
      id: _localDeck.id,
      name: name,
      subject: subject,
      cardCount: _localDeck.cardCount,
    );

    await _deckStorageService.updateDeck(_localDeck);

    _hasChanges = true;
    if (mounted) {
      setState(() => _saveState = SaveState.saved);
    }
  }

  // Ensures any pending auto-saves finish before the user leaves
  void _handleCancel() {
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
      _performAutoSave().then((_) {
        if (mounted) Navigator.pop(context, _hasChanges);
      });
    } else {
      Navigator.pop(context, _hasChanges);
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
        Navigator.pop(context, true); 
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 850;

        if (isDesktop) {
          return DeckSettingsWeb(
            nameController: _nameController,
            subjectController: _subjectController,
            saveState: _saveState,
            cardCount: widget.deck.cardCount,
            onResetProgress: _confirmResetProgress,
            onDeleteAllCards: _confirmDeleteAllCards,
            onCancel: _handleCancel,
          );
        } else {
          return DeckSettingsMobile(
            nameController: _nameController,
            subjectController: _subjectController,
            saveState: _saveState,
            cardCount: widget.deck.cardCount,
            onResetProgress: _confirmResetProgress,
            onDeleteAllCards: _confirmDeleteAllCards,
            onCancel: _handleCancel,
          );
        }
      },
    );
  }
}