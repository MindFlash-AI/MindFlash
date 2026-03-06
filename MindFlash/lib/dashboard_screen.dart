import 'package:flutter/material.dart';
import 'constants.dart';
import 'dashboard_header.dart';
import 'stat_card.dart';
import 'create_deck_dialog.dart';
import 'deck_model.dart';
import 'deck_storage_service.dart';
import 'deck_list_item.dart';
import 'deck_view.dart';

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
              child: Stack(
                children: [
                  _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.white))
                      : _decks.isEmpty
                          ? _buildEmptyState()
                          : _buildDeckList(),

                  Positioned(
                    bottom: 40,
                    left: 20,
                    right: 20,
                    child: _buildCreateDeckButton(context),
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
              "Create your first deck and start\nyour learning journey!",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 60),
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
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
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

  Widget _buildCreateDeckButton(BuildContext context) {
    return Container(
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
            showDialog(
              context: context,
              builder: (context) => CreateDeckDialog(
                onDeckCreated: _onDeckCreated,
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.add, color: Colors.black),
              SizedBox(width: 8),
              Text(
                "Create New Deck",
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
    );
  }
}