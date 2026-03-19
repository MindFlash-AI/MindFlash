import 'package:flutter/material.dart';
import 'constants.dart';
import 'dashboard_header.dart';
import 'stat_card.dart';
import 'create_deck_dialog.dart';
import 'create_deck_ai_dialog.dart';
import 'update_deck_ai_dialog.dart';
import 'deck_model.dart';
import 'deck_storage_service.dart';
import 'deck_list_item.dart';
import 'deck_view.dart';
import 'ai_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DeckStorageService _storageService = DeckStorageService();
  List<Deck> _decks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDecks();
  }

  Future<void> _loadDecks() async {
    final decks = await _storageService.getDecks();
    setState(() {
      _decks = decks;
      _isLoading = false;
    });
  }

  void _onDeckCreated(Deck deck) async {
    await _storageService.addDeck(deck);
    _loadDecks();
  }

  void _deleteDeck(String id) async {
    setState(() {
      _decks.removeWhere((deck) => deck.id == id);
    });
    await _storageService.deleteDeck(id);
    _loadDecks();
  }

  // --- NEW: Helper method to handle AI loading state and API calls ---
  Future<void> _processAIGeneration(BuildContext context, String prompt) async {
    // 1. Show a loading dialog so the user knows AI is thinking
    showDialog(
      context: context,
      barrierDismissible:
          false, // Prevent user from dismissing it by tapping outside
      builder: (loadingContext) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(color: Color(0xFF5B4FE6)),
              SizedBox(height: 16),
              Text(
                "MindFlash AI is thinking...",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration
                      .none, // Removes yellow underline from dialog text
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      // 2. Call your actual backend service
      final aiService = AIService();
      final response = await aiService.processInput(text: prompt);

      // 3. Close the loading dialog safely
      if (context.mounted) Navigator.pop(context);

      // 4. Refresh the decks to show the newly generated content
      _loadDecks();

      // 5. Show success message from the server
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Close the loading dialog safely on error
      if (context.mounted) Navigator.pop(context);

      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Generation Failed: ${e.toString()}"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // --- AI Options Menu ---
  void _showAIOptionsModal(BuildContext parentContext) {
    showModalBottomSheet(
      context: parentContext,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "AI Generation",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(modalContext).pop(),
                    icon: const Icon(Icons.close, color: Colors.grey),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "Choose how you want MindFlash AI to help you.",
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),

              // Option 1: Create New Deck
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5B4FE6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Color(0xFF5B4FE6),
                  ),
                ),
                title: const Text(
                  "Create New Deck with AI",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: const Text(
                  "Generate a completely new deck from a prompt",
                ),
                onTap: () {
                  Navigator.pop(modalContext);

                  showModalBottomSheet(
                    context: parentContext,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => CreateDeckAIDialog(
                      // CONNECTED TO AI SERVICE
                      onGenerate: (topic) =>
                          _processAIGeneration(parentContext, topic),
                    ),
                  );
                },
              ),
              const Divider(height: 30),

              // Option 2: Update Existing Deck
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE940A3).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.update, color: Color(0xFFE940A3)),
                ),
                title: const Text(
                  "Update Deck with AI",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: const Text(
                  "Add newly generated cards to an existing deck",
                ),
                onTap: () {
                  Navigator.pop(modalContext);

                  if (_decks.isEmpty) {
                    ScaffoldMessenger.of(parentContext).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "You need to create a deck first before updating one!",
                        ),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                    return;
                  }

                  showModalBottomSheet(
                    context: parentContext,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => UpdateDeckAIDialog(
                      decks: _decks,
                      // CONNECTED TO AI SERVICE WITH CONTEXTUAL PROMPT
                      onGenerate: (Deck deck, String topic) {
                        // We format the prompt so the backend knows exactly which deck to update
                        final engineeredPrompt =
                            "Update the deck '${deck.name}' with the following topic/cards: $topic";
                        _processAIGeneration(parentContext, engineeredPrompt);
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const DashboardHeader(),
                  const SizedBox(height: 25),
                  _buildStatsRow(),
                ],
              ),
            ),
          ),

          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: AppColors.mainBackgroundGradient,
                ),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          )
                        : _decks.isEmpty
                        ? _buildEmptyState()
                        : _buildDeckList(),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
                    child: _buildActionButtons(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    int totalCards = _decks.fold(0, (sum, deck) => sum + deck.cardCount);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: StatCard(
              title: "Total Decks",
              count: _decks.length.toString(),
              icon: Icons.chrome_reader_mode_outlined,
              colors: AppColors.deckCardGradient,
              shadowColor: const Color(0xFF3525AF),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatCard(
              title: "Total Cards",
              count: totalCards.toString(),
              icon: Icons.auto_awesome_outlined,
              colors: AppColors.cardCardGradient,
              shadowColor: const Color(0xFF7B52DD),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildEmptyStateIcon(),
            const SizedBox(height: 20),
            const Text(
              "No Decks Yet",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Create your first deck manually or\nlet AI build one for you!",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeckList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Text(
            "My Decks (${_decks.length})",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 15),
            itemCount: _decks.length,
            itemBuilder: (context, index) {
              final deck = _decks[index];
              return DeckListItem(
                deck: deck,
                onDelete: () => _deleteDeck(deck.id),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DeckView(deck: deck),
                    ),
                  );
                  _loadDecks();
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyStateIcon() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Center(
        child: Icon(Icons.menu_book_rounded, color: Colors.white, size: 40),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // AI Generate Button Menu Trigger
        Container(
          height: 55,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2C1A8A), Color(0xFF5B4FE6)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showAIOptionsModal(context),
              borderRadius: BorderRadius.circular(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.auto_awesome, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    "Generate with AI",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Manual Create Button Bottom Sheet Trigger
        Container(
          height: 55,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) =>
                      CreateDeckDialog(onDeckCreated: _onDeckCreated),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.add, color: Colors.black),
                  SizedBox(width: 8),
                  Text(
                    "Create Deck Manually",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
