import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/deck_model.dart';
import '../../models/card_model.dart';
import '../../services/card_storage_service.dart';
import '../../services/deck_storage_service.dart';

import '../../widgets/create_card_dialog.dart';
import '../../widgets/edit_card_dialog.dart';

import '../review/review_screen.dart';
import '../quiz/quiz_screen.dart';
import '../chat/ai_chat_screen.dart';
import '../../services/quiz_creator.dart';
import 'components/deck_settings_screen.dart'; // NEW: Deck Settings Import

import 'deck_view_mobile.dart';
import 'deck_view_web.dart';

class DeckView extends StatefulWidget {
  final Deck deck;

  const DeckView({super.key, required this.deck});

  @override
  State<DeckView> createState() => _DeckViewState();
}

class _DeckViewState extends State<DeckView> with TickerProviderStateMixin {
  final CardStorageService _cardStorageService = CardStorageService();
  final DeckStorageService _deckStorageService = DeckStorageService();
  final ScrollController _scrollController = ScrollController();

  late AnimationController _actionsExpandController;
  late Animation<double> _expandAnimation;

  late Deck _currentDeck; // NEW: Tracks local deck state changes
  List<Flashcard> _cards = [];
  bool _isLoading = true;

  final LinearGradient _brandGradient = const LinearGradient(
    colors: [Color(0xFF8B4EFF), Color(0xFFE841A1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void initState() {
    super.initState();
    _currentDeck = widget.deck; // Initialize with passed deck

    _actionsExpandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _actionsExpandController,
      curve: Curves.easeOutCubic,
    );

    _scrollController.addListener(() {
      if (_scrollController.offset <= 0 && _actionsExpandController.value > 0) {
        _actionsExpandController.value = 0.0;
      }
    });

    _loadCards();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _actionsExpandController.dispose();
    super.dispose();
  }

  Future<void> _loadCards() async {
    final cards = await _cardStorageService.getCardsForDeck(_currentDeck.id);
    if (!mounted) return;
    setState(() {
      _cards = cards;
      _isLoading = false;
    });
  }
  
  // NEW: Method to reload deck data after returning from Settings
  Future<void> _reloadDeckInfo() async {
    final decks = await _deckStorageService.getDecks();
    final updatedDeck = decks.firstWhere((d) => d.id == _currentDeck.id, orElse: () => _currentDeck);
    setState(() {
      _currentDeck = updatedDeck;
    });
    _loadCards();
  }

  void _openDeckSettings() async {
    HapticFeedback.selectionClick();
    final didChange = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeckSettingsScreen(deck: _currentDeck),
      ),
    );

    // If the user made changes in the settings (title, subject, resets, deletion), reload!
    if (didChange == true) {
      _reloadDeckInfo();
    }
  }

  void _onCardCreated(Flashcard card) async {
    await _cardStorageService.addCard(card);
    if (!mounted) return;
    setState(() {
      _currentDeck.cardCount += 1;
    });
    await _deckStorageService.updateDeck(_currentDeck);
    _loadCards();
  }

  Future<void> _confirmDeleteCard(String cardId) async {
    HapticFeedback.heavyImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text(
          "Delete Card?",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        content: Text(
          "Are you sure? This action cannot be undone.",
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
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
              foregroundColor: isDark ? Colors.redAccent : Colors.red,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Delete",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _cardStorageService.deleteCard(cardId);
      if (!mounted) return;
      setState(() {
        if (_currentDeck.cardCount > 0) _currentDeck.cardCount -= 1;
      });
      await _deckStorageService.updateDeck(_currentDeck);
      _loadCards();
    }
  }

  void _startReview() async {
    HapticFeedback.lightImpact();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ReviewScreen(deck: _currentDeck, cards: _cards, isShuffleOn: false),
      ),
    );
    _loadCards();
  }

  void _startFlaggedReview() async {
    HapticFeedback.lightImpact();
    final flaggedCards = _cards.where((c) => c.isFlagged).toList();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewScreen(
          deck: _currentDeck,
          cards: flaggedCards,
          isShuffleOn: false,
        ),
      ),
    );
    _loadCards();
  }

  void _startQuiz() {
    HapticFeedback.lightImpact();
    final quizQuestions = LocalQuizEngine.generateMCQ(_cards);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            QuizScreen(quiz: quizQuestions, deckId: _currentDeck.id, deckTitle: _currentDeck.name),
      ),
    );
  }

  void _openAITutor() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AIChatScreen(deck: _currentDeck),
      ),
    );
  }

  void _showDisabledSnackBar(String message) {
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showAddCardDialog(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateCardDialog(
        deckId: _currentDeck.id,
        onCardCreated: _onCardCreated,
      ),
    );
  }

  void _editCard(Flashcard card) {
    HapticFeedback.selectionClick();
    showDialog(
      context: context,
      builder: (context) => EditCardDialog(
        card: card,
        onCardUpdated: (updatedCard) async {
          await _cardStorageService.updateCard(updatedCard);
          _loadCards();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 850;

        if (isDesktop) {
          return DeckViewWeb(
            deck: _currentDeck,
            cards: _cards,
            isLoading: _isLoading,
            onSettings: _openDeckSettings,
            onAddCard: () => _showAddCardDialog(context),
            onEditCard: _editCard,
            onDeleteCard: _confirmDeleteCard,
            onReview: _startReview,
            onFlaggedReview: _startFlaggedReview,
            onQuiz: _startQuiz,
            onAITutor: _openAITutor,
            onDisabledAction: _showDisabledSnackBar,
          );
        } else {
          return DeckViewMobile(
            deck: _currentDeck,
            cards: _cards,
            isLoading: _isLoading,
            scrollController: _scrollController,
            actionsExpandController: _actionsExpandController,
            expandAnimation: _expandAnimation,
            onSettings: _openDeckSettings,
            onAddCard: () => _showAddCardDialog(context),
            onEditCard: _editCard,
            onDeleteCard: _confirmDeleteCard,
            onReview: _startReview,
            onFlaggedReview: _startFlaggedReview,
            onQuiz: _startQuiz,
            onAITutor: _openAITutor,
            onDisabledAction: _showDisabledSnackBar,
          );
        }
      },
    );
  }
}