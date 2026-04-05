import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/deck_model.dart';
import '../../models/card_model.dart';
import '../../services/card_storage_service.dart';
import '../../services/deck_storage_service.dart';

import '../../widgets/create_card_dialog.dart';
import '../../services/quiz_creator.dart';
import '../../widgets/dialogs/confirmation_dialog.dart';
import 'components/deck_settings_screen.dart';
import '../review/review_screen.dart';
import '../quiz/quiz_screen.dart';
import '../chat/ai_chat_screen.dart'; 
import 'deck_view_mobile.dart';
import 'deck_view_web.dart';
import '../../widgets/edit_card_dialog.dart';

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
  bool _isSelectionMode = false;
  Set<String> _selectedCards = {};

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

    if (_currentDeck.cardOrder.isNotEmpty) {
      final orderMap = {
        for (int i = 0; i < _currentDeck.cardOrder.length; i++)
          _currentDeck.cardOrder[i]: i
      };
      cards.sort((a, b) {
        final indexA = orderMap[a.id] ?? 999999;
        final indexB = orderMap[b.id] ?? 999999;
        return indexA.compareTo(indexB);
      });
    }

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

  void _syncUpdatedCard(Flashcard updatedCard) {
    final index = _cards.indexWhere((c) => c.id == updatedCard.id);
    if (index != -1) {
      setState(() => _cards[index] = updatedCard);
    }
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

  void _onReorderCards(int oldIndex, int newIndex) async {
    HapticFeedback.selectionClick();
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final Flashcard item = _cards.removeAt(oldIndex);
      _cards.insert(newIndex, item);
      
      _currentDeck.cardOrder = _cards.map((c) => c.id).toList();
    });
    
    // Save the new order to Firestore in the background
    await _deckStorageService.updateDeck(_currentDeck);
  }

  void _toggleSelectionMode() {
    HapticFeedback.selectionClick();
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      _selectedCards.clear();
    });
  }

  void _toggleCardSelection(String cardId) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedCards.contains(cardId)) {
        _selectedCards.remove(cardId);
      } else {
        _selectedCards.add(cardId);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _isSelectionMode = false;
      _selectedCards.clear();
    });
  }

  Future<void> _confirmDeleteSelected() async {
    if (_selectedCards.isEmpty) {
      _toggleSelectionMode();
      return;
    }
    
    HapticFeedback.heavyImpact();
    
    final bool? confirm = await ConfirmationDialog.show(
      context,
      title: "Delete ${_selectedCards.length} Cards?",
      content: "Are you sure? This action cannot be undone.",
      confirmLabel: "Delete",
      isDangerous: true,
    );

    if (confirm == true) {
      final List<String> toDelete = _selectedCards.toList();
      await _cardStorageService.deleteCards(toDelete);
      
      if (!mounted) return;
      setState(() {
        if (_currentDeck.cardCount >= toDelete.length) {
          _currentDeck.cardCount -= toDelete.length;
        } else {
          _currentDeck.cardCount = 0;
        }
        _currentDeck.cardOrder.removeWhere((id) => toDelete.contains(id));
        _isSelectionMode = false;
        _selectedCards.clear();
      });
      await _deckStorageService.updateDeck(_currentDeck);
    }
  }

  void _onCardCreated(Flashcard card) async {
    await _cardStorageService.addCard(card);
    if (!mounted) return;
    setState(() {
      _cards.add(card); // 🚀 OPTIMIZATION: Mutate local list instead of re-fetching from DB
      _currentDeck.cardCount += 1;
      if (!_currentDeck.cardOrder.contains(card.id)) {
        _currentDeck.cardOrder.add(card.id);
      }
    });
    await _deckStorageService.updateDeck(_currentDeck);
  }

  Future<void> _confirmDeleteCard(String cardId) async {
    HapticFeedback.heavyImpact();
    
    final bool? confirm = await ConfirmationDialog.show(
      context,
      title: "Delete Card?",
      content: "Are you sure? This action cannot be undone.",
      confirmLabel: "Delete",
      isDangerous: true,
    );

    if (confirm == true) {
      await _cardStorageService.deleteCard(cardId);
      if (!mounted) return;
      setState(() {
        _cards.removeWhere((c) => c.id == cardId); // 🚀 OPTIMIZATION: Update UI immediately locally
        if (_currentDeck.cardCount > 0) _currentDeck.cardCount -= 1;
        _currentDeck.cardOrder.remove(cardId);
      });
      await _deckStorageService.updateDeck(_currentDeck);
    }
  }

  void _startReview() async {
    HapticFeedback.lightImpact();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ReviewScreen(deck: _currentDeck, cards: _cards, isShuffleOn: false, onCardUpdated: _syncUpdatedCard),
      ),
    );
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
          onCardUpdated: _syncUpdatedCard,
        ),
      ),
    );
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
          _syncUpdatedCard(updatedCard); // 🚀 OPTIMIZATION: Update locally
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
            onReorderCards: _onReorderCards,
            isSelectionMode: _isSelectionMode,
            selectedCards: _selectedCards,
            onToggleSelectionMode: _toggleSelectionMode,
            onToggleCardSelection: _toggleCardSelection,
            onClearSelection: _clearSelection,
            onDeleteSelected: _confirmDeleteSelected,
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
            onReorderCards: _onReorderCards,
            isSelectionMode: _isSelectionMode,
            selectedCards: _selectedCards,
            onToggleSelectionMode: _toggleSelectionMode,
            onToggleCardSelection: _toggleCardSelection,
            onClearSelection: _clearSelection,
            onDeleteSelected: _confirmDeleteSelected,
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