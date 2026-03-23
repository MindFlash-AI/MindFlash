import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants.dart';
import '../../models/deck_model.dart';
import '../../services/deck_storage_service.dart';
import '../../services/ai_service.dart';

import '../../widgets/stat_card.dart';
import '../../widgets/deck_list_item.dart';
import '../../widgets/create_deck_dialog.dart';
import '../../widgets/create_deck_ai_dialog.dart';
import '../../widgets/update_deck_ai_dialog.dart';

import '../deck_view/deck_view.dart';
import 'widgets/dashboard_header.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  final DeckStorageService _storageService = DeckStorageService();
  List<Deck> _decks = [];
  bool _isLoading = true;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _loadDecks();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
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

  void _showFeedbackModal(BuildContext context, bool isSuccess, String message) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 20,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSuccess ? Colors.green.shade50 : Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSuccess
                      ? Icons.check_circle_outline_rounded
                      : Icons.error_outline_rounded,
                  color: isSuccess ? Colors.green : Colors.redAccent,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isSuccess ? "Success!" : "Oops!",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSuccess
                        ? const Color(0xFF5B4FE6)
                        : Colors.redAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    isSuccess ? "Awesome" : "Close",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String> _processAIGeneration(
    BuildContext context, 
    String prompt, 
    {String? fileText, String? fileName}
  ) async {
    try {
      final aiService = AIService();
      final response = await aiService.processInput(
        text: prompt,
        fileText: fileText,
        fileName: fileName,
      );

      await _loadDecks();
      return response.message;
    } catch (e) {
      if (context.mounted) {
        HapticFeedback.heavyImpact();
        _showFeedbackModal(
          context,
          false,
          "Failed to generate flashcards. Please check your connection and try again.\n\nError: ${e.toString().replaceAll('Exception:', '').trim()}",
        );
      }
      rethrow; 
    }
  }

  void _showAIOptionsModal(BuildContext parentContext) {
    showModalBottomSheet(
      context: parentContext,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (modalContext) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(modalContext).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Flexible(
                          child: Text(
                            "AI Generation",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
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
                      onTap: () async {
                        HapticFeedback.lightImpact();
                        Navigator.pop(modalContext);

                        final successMessage = await showModalBottomSheet<String>(
                          context: parentContext,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => CreateDeckAIDialog(
                            onGenerate: (topic, fileText, fileName) =>
                                _processAIGeneration(
                                  parentContext, 
                                  topic, 
                                  fileText: fileText, 
                                  fileName: fileName
                                ),
                          ),
                        );

                        if (successMessage != null && parentContext.mounted) {
                          HapticFeedback.mediumImpact();
                          _showFeedbackModal(parentContext, true, successMessage);
                        }
                      },
                    ),
                    const Divider(height: 30),

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
                      onTap: () async {
                        HapticFeedback.lightImpact();
                        Navigator.pop(modalContext);

                        if (_decks.isEmpty) {
                          HapticFeedback.heavyImpact();
                          _showFeedbackModal(
                            parentContext,
                            false,
                            "You need to create a deck first before updating one!",
                          );
                          return;
                        }

                        final successMessage = await showModalBottomSheet<String>(
                          context: parentContext,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => UpdateDeckAIDialog(
                            decks: _decks,
                            onGenerate: (Deck deck, String topic) {
                              final engineeredPrompt =
                                  "Update the deck '${deck.name}' with the following topic/cards: $topic";
                              return _processAIGeneration(parentContext, engineeredPrompt);
                            },
                          ),
                        );

                        if (successMessage != null && parentContext.mounted) {
                          HapticFeedback.mediumImpact();
                          _showFeedbackModal(parentContext, true, successMessage);
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 💡 FIX: AnnotatedRegion forces the status bar icons to be DARK (black) so they are visible against the white background.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent, // Keeps the background of the status bar transparent
      ),
      child: Scaffold(
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
                    SafeArea(
                      top: false,
                      bottom: true,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                        child: _buildActionButtons(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
    return Stack(
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 60.0),
            child: _buildAnimatedDeckGhost(),
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                const Text(
                  "No Decks Yet",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Create your first deck manually or\nlet AI build one for you!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedDeckGhost() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(seconds: 3),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        final floatValue = (value * 2 - 1).abs() - 1;
        return Transform.translate(
          offset: Offset(0, floatValue * 15),
          child: Opacity(opacity: 0.15, child: child),
        );
      },
      onEnd: () {
        setState(() {});
      },
      child: Container(
        height: 280,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 3),
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.1),
              Colors.white.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 120,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: 160,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: 200,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  3,
                  (index) => Container(
                    width: 50,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                  ),
                ),
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
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 30 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: DeckListItem(
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
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final scale =
                1.0 +
                (0.05 *
                    (0.5 *
                        (1 +
                            ((_pulseController.value * 2 - 1).abs() - 0.5) *
                                2)));
            return Transform.scale(scale: scale, child: child);
          },
          child: Container(
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
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _showAIOptionsModal(context);
                },
                borderRadius: BorderRadius.circular(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.auto_awesome, color: Colors.white),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        "Generate with AI",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
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
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
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
                  Flexible(
                    child: Text(
                      "Create Deck Manually",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
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