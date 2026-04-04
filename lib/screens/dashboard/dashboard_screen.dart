import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/constants.dart';
import '../../models/deck_model.dart';
import '../../services/deck_storage_service.dart';
import '../../services/card_storage_service.dart'; // 🛡️ Added Card Storage import
import '../../services/ai_service.dart';
import '../../services/energy_service.dart';

import '../../widgets/stat_card.dart';
import '../../widgets/deck_list_item.dart';
import '../../widgets/create_deck_dialog.dart';
import '../../widgets/create_deck_ai_dialog.dart';
import '../../widgets/update_deck_ai_dialog.dart';

import '../deck_view/deck_view.dart';
import '../../widgets/web_pro_gate.dart';
import '../study_pad/study_pad_screen.dart';
import '../web_landing/web_landing_screen.dart'; 

import 'dashboard_web.dart';
import 'dashboard_mobile.dart';

enum SortOption { nameAsc, nameDesc, countDesc, countAsc }

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  final DeckStorageService _storageService = DeckStorageService();
  final CardStorageService _cardStorageService = CardStorageService(); // 🛡️ Init
  
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  List<Deck> _decks = [];
  bool _isLoading = true;
  int _totalCards = 0; // 🚀 OPTIMIZATION: Cache total cards to prevent O(N) recalculations
  late AnimationController _pulseController;
  SortOption _currentSort = SortOption.nameAsc;

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

  void _applySort() {
    switch (_currentSort) {
      case SortOption.nameAsc:
        _decks.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case SortOption.nameDesc:
        _decks.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case SortOption.countDesc:
        _decks.sort((a, b) => b.cardCount.compareTo(a.cardCount));
        break;
      case SortOption.countAsc:
        _decks.sort((a, b) => a.cardCount.compareTo(b.cardCount));
        break;
    }
  }

  Future<void> _loadDecks() async {
    final decks = await _storageService.getDecks();
    if (!mounted) return;
    setState(() {
      _decks = decks;
      _totalCards = decks.fold(0, (sum, deck) => sum + deck.cardCount);
      _isLoading = false;
      _applySort();
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
    
    // 🛡️ SECURITY FIX 2: Cascading Deletes
    // Deleting the deck AND its orphaned flashcards prevents a massive storage leak
    await _storageService.deleteDeck(id);
    await _cardStorageService.deleteCardsByDeck(id); 
    
    _loadDecks();
  }

  void _showManualDeckModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateDeckDialog(onDeckCreated: _onDeckCreated),
    );
  }

  void _navigateToStudyPad() {
    if (_scaffoldKey.currentState?.isDrawerOpen == true) {
      Navigator.pop(context);
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const StudyPadScreen(),
      ),
    );
  }

  void _navigateToWebsite() {
    HapticFeedback.lightImpact();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const WebLandingScreen()),
      (route) => false,
    );
  }

  void _showFeedbackModal(BuildContext context, bool isSuccess, String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Theme.of(context).cardColor,
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
                  color: isSuccess 
                      ? (isDark ? Colors.green.withOpacity(0.15) : Colors.green.shade50) 
                      : (isDark ? Colors.red.withOpacity(0.15) : Colors.red.shade50),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSuccess
                      ? Icons.check_circle_outline_rounded
                      : Icons.error_outline_rounded,
                  color: isSuccess 
                      ? (isDark ? Colors.greenAccent : Colors.green) 
                      : (isDark ? Colors.redAccent : Colors.redAccent),
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isSuccess ? "Success!" : "Oops!",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
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
                        : (isDark ? Colors.redAccent.shade200 : Colors.redAccent),
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
    {String? fileText, String? fileName, String? targetDeckId}
  ) async {
    try {
      final aiService = AIService();
      final response = await aiService.processInput(
        text: prompt,
        fileText: fileText,
        fileName: fileName,
        targetDeckId: targetDeckId, // 🛡️ BUG FIX: Pass the ID to prevent duplicating cards
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
      builder: (modalContext) {
        final isDark = Theme.of(modalContext).brightness == Brightness.dark;

        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(modalContext).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(modalContext).cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                            color: isDark ? Colors.white24 : Colors.grey[400],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              "AI Generation",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(modalContext).textTheme.bodyLarge?.color,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(modalContext).pop(),
                            icon: Icon(Icons.close, color: isDark ? Colors.white54 : Colors.grey),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Choose how you want MindFlash AI to help you.",
                        style: TextStyle(fontSize: 14, color: isDark ? Colors.white54 : Colors.grey[600]),
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
                        title: Text(
                          "Create New Deck with AI",
                          style: TextStyle(
                            fontWeight: FontWeight.bold, 
                            fontSize: 16,
                            color: Theme.of(modalContext).textTheme.bodyLarge?.color,
                          ),
                        ),
                        subtitle: Text(
                          "Generate a completely new deck from a prompt",
                          style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade600),
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
                      Divider(height: 30, color: isDark ? Colors.white12 : Colors.grey.shade200),

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
                        title: Text(
                          "Update Deck with AI",
                          style: TextStyle(
                            fontWeight: FontWeight.bold, 
                            fontSize: 16,
                            color: Theme.of(modalContext).textTheme.bodyLarge?.color,
                          ),
                        ),
                        subtitle: Text(
                          "Add newly generated cards to an existing deck",
                          style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade600),
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
                        return _processAIGeneration(parentContext, engineeredPrompt, targetDeckId: deck.id);
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
        );
      }
    );
  }

  Widget _buildSidebarContent(BuildContext context, bool isDark) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8), 
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B4EFF), Color(0xFFE841A1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  "MindFlash",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            Divider(color: isDark ? Colors.white12 : Colors.grey.shade200, height: 1),
            const SizedBox(height: 24),
            
            Text(
              "MENU",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildSidebarItem(
              context, 
              isDark, 
              icon: Icons.dashboard_rounded, 
              title: "Dashboard", 
              isActive: true, 
              onTap: () {
                if (_scaffoldKey.currentState?.isDrawerOpen == true) {
                  Navigator.pop(context);
                }
              }
            ),
            
            _buildSidebarItem(
              context, 
              isDark, 
              icon: Icons.edit_note_rounded, 
              title: "Study Pad", 
              onTap: _navigateToStudyPad
            ),

            const Spacer(),
            
            Divider(color: isDark ? Colors.white12 : Colors.grey.shade200, height: 1),
            const SizedBox(height: 16),
            _buildSidebarItem(
              context, 
              isDark, 
              icon: Icons.public_rounded, 
              title: "Back to Website", 
              onTap: _navigateToWebsite
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarItem(BuildContext context, bool isDark, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: isActive ? [
          BoxShadow(
            color: const Color(0xFF8B4EFF).withOpacity(isDark ? 0.3 : 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ] : [],
      ),
      child: Material(
        color: isActive 
            ? (isDark ? const Color(0xFF8B4EFF).withOpacity(0.2) : Colors.white)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive 
                    ? const Color(0xFF8B4EFF).withOpacity(0.4) 
                    : Colors.transparent,
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(
                  icon, 
                  color: isActive ? const Color(0xFF8B4EFF) : (isDark ? Colors.white54 : Colors.black54),
                  size: 22,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                    color: isActive ? const Color(0xFF8B4EFF) : (isDark ? Colors.white70 : Colors.black87),
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewWidgets(BuildContext context, bool isDark, double maxWidth) {
    return StreamBuilder<int>(
      stream: EnergyService().energyStream,
      initialData: EnergyService().currentEnergy,
      builder: (context, snapshot) {
        final currentEnergy = snapshot.data ?? EnergyService().maxEnergy;
        final maxEnergy = EnergyService().maxEnergy;

        final statCards = [
          StatCard(
            title: "Total Decks",
            count: _decks.length.toString(),
            icon: Icons.chrome_reader_mode_outlined,
            colors: isDark 
                ? const [Color(0xFF533E9E), Color(0xFF382773)] 
                : const [Color(0xFF6366F1), Color(0xFF4F46E5)], 
            shadowColor: isDark ? Colors.black87 : const Color(0xFF4F46E5).withOpacity(0.3),
          ),
          StatCard(
            title: "Total Cards",
            count: _totalCards.toString(),
            icon: Icons.library_books_rounded,
            colors: isDark 
                ? const [Color(0xFF863B6B), Color(0xFF5E244B)] 
                : const [Color(0xFFEC4899), Color(0xFFDB2777)], 
            shadowColor: isDark ? Colors.black87 : const Color(0xFFDB2777).withOpacity(0.3),
          ),
          StatCard(
            title: "AI Energy",
            count: "$currentEnergy / $maxEnergy",
            icon: Icons.electric_bolt_rounded,
            colors: isDark 
                ? const [Color(0xFF0F766E), Color(0xFF172554)] 
                : const [Color(0xFF0EA5E9), Color(0xFF0284C7)], 
            shadowColor: isDark ? Colors.black87 : const Color(0xFF0284C7).withOpacity(0.3),
          ),
        ];

        final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

        if (maxWidth >= 850 || (isLandscape && maxWidth >= 600)) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: statCards[0]),
                const SizedBox(width: 16),
                Expanded(child: statCards[1]),
                const SizedBox(width: 16),
                Expanded(child: statCards[2]),
              ],
            ),
          );
        } else if (maxWidth < 380) {
          // 📱 HCI Layout Improvement: Very narrow mobile screens (e.g., iPhone SE)
          return Column(
            children: [
              statCards[0],
              const SizedBox(height: 12),
              statCards[1],
              const SizedBox(height: 12),
              statCards[2],
            ],
          );
        } else {
          return Column(
            children: [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: statCards[0]),
                    const SizedBox(width: 12),
                    Expanded(child: statCards[1]),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: statCards[2]),
                  ],
                ),
              ),
            ],
          );
        }
      }
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Stack(
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 60.0),
            child: _buildAnimatedDeckGhost(isDark),
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
                Text(
                  "No Decks Yet",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Create your first deck manually or\nlet AI build one for you!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 32),
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final scale = 1.0 + (0.05 * (0.5 * (1 + ((_pulseController.value * 2 - 1).abs() - 0.5) * 2)));
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _showAIOptionsModal(context);
                    },
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text("Generate your first Deck", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B4EFF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      elevation: 16, 
                      shadowColor: const Color(0xFF8B4EFF).withOpacity(0.6), 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedDeckGhost(bool isDark) {
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade300;
    final gradientStart = isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.6);
    final gradientEnd = isDark ? Colors.transparent : Colors.white.withOpacity(0.1);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(seconds: 3),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        final floatValue = (value * 2 - 1).abs() - 1;
        return Transform.translate(
          offset: Offset(0, floatValue * 15),
          child: Opacity(opacity: 0.35, child: child), 
        );
      },
      onEnd: () {
        setState(() {});
      },
      child: Container(
        height: 280,
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: 3),
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [gradientStart, gradientEnd],
          ),
          boxShadow: isDark ? [] : [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 15,
              offset: const Offset(0, 5),
            )
          ],
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
                      color: isDark ? Colors.white38 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: 160,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.grey.shade200,
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
                      color: isDark ? Colors.white12 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: 200,
                    height: 10,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white12 : Colors.grey.shade200,
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
                      color: isDark ? Colors.white10 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? Colors.white24 : Colors.grey.shade200,
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

  PopupMenuItem<SortOption> _buildSortMenuItem(SortOption value, String text, IconData icon, bool isDark) {
    final isSelected = _currentSort == value;
    return PopupMenuItem<SortOption>(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            color: isSelected 
                ? const Color(0xFF8B4EFF) 
                : (isDark ? Colors.white70 : Colors.grey.shade700),
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              color: isSelected 
                  ? const Color(0xFF8B4EFF) 
                  : Theme.of(context).textTheme.bodyLarge?.color,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeckList(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          decoration: BoxDecoration(
            color: isDark ? Theme.of(context).cardColor : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
            border: Border(
              bottom: BorderSide(
                color: isDark ? Colors.white12 : Colors.grey.shade100,
                width: 1,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "My Decks (${_decks.length})",
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              PopupMenuButton<SortOption>(
                icon: Icon(
                  Icons.sort_rounded,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  size: 24,
                ),
                color: Theme.of(context).cardColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                onSelected: (SortOption option) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _currentSort = option;
                    _applySort();
                  });
                },
                itemBuilder: (context) => [
                  _buildSortMenuItem(SortOption.nameAsc, "Name (A to Z)", Icons.sort_by_alpha, isDark),
                  _buildSortMenuItem(SortOption.nameDesc, "Name (Z to A)", Icons.sort_by_alpha, isDark),
                  _buildSortMenuItem(SortOption.countDesc, "Cards (High to Low)", Icons.format_list_numbered, isDark),
                  _buildSortMenuItem(SortOption.countAsc, "Cards (Low to High)", Icons.format_list_numbered_rtl, isDark),
                ],
              ),
            ],
          ),
        ),
        
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              // 🚀 HCI Layout Improvement: Ensures tablets show at least 2 columns
              maxCrossAxisExtent: 380, 
              mainAxisExtent: 140,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
            ),
            itemCount: _decks.length,
            itemBuilder: (context, index) {
              final deck = _decks[index];
              final int delayMultiplier = index.clamp(0, 10); 
              
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 400 + (delayMultiplier * 50)),
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

  Widget _buildActionButtons(BuildContext context, bool isDark, double maxWidth) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    if (maxWidth >= 850) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCompactButton(
            context,
            isDark,
            label: "Manual Deck",
            icon: Icons.add,
            onTap: _showManualDeckModal,
            isPrimary: false,
          ),
          const SizedBox(width: 12),
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final scale = 1.0 + (0.03 * (0.5 * (1 + ((_pulseController.value * 2 - 1).abs() - 0.5) * 2)));
              return Transform.scale(scale: scale, child: child);
            },
            child: _buildCompactButton(
              context,
              isDark,
              label: "Generate with AI",
              icon: Icons.auto_awesome,
              onTap: () => _showAIOptionsModal(context),
              isPrimary: true,
            ),
          ),
        ],
      );
    } else {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final scale = 1.0 + (0.05 * (0.5 * (1 + ((_pulseController.value * 2 - 1).abs() - 0.5) * 2)));
              return Transform.scale(scale: scale, child: child);
            },
            child: Container(
              height: 55,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF2C1A8A), Color(0xFF5B4FE6)]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B4EFF).withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  )
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.auto_awesome, color: Colors.white),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          "Generate with AI",
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 55,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2A1B3D) : Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF8B4EFF).withOpacity(0.5), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B4EFF).withOpacity(0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _navigateToStudyPad();
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.edit_note_rounded, color: Color(0xFF8B4EFF)),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              "Study Pad",
                              style: TextStyle(color: Color(0xFF8B4EFF), fontSize: 15, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 55,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: isDark ? Border.all(color: Colors.white.withOpacity(0.05), width: 1) : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _showManualDeckModal();
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, color: Theme.of(context).textTheme.bodyLarge?.color, size: 20),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              "Manual Deck",
                              style: TextStyle(
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                                fontSize: 15,
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
            ],
          ),
        ],
      );
    }
  }

  Widget _buildCompactButton(
    BuildContext context,
    bool isDark, {
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required bool isPrimary,
    Color? color,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        gradient: isPrimary
            ? const LinearGradient(colors: [Color(0xFF2C1A8A), Color(0xFF5B4FE6)])
            : null,
        color: isPrimary ? null : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: isPrimary ? null : Border.all(
          color: color?.withOpacity(0.5) ?? (isDark ? Colors.white24 : Colors.grey.shade200),
          width: 1,
        ),
        boxShadow: isPrimary
            ? [BoxShadow(color: const Color(0xFF8B4EFF).withOpacity(isDark ? 0.4 : 0.3), blurRadius: 20, offset: const Offset(0, 8))]
            : [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: isPrimary ? Colors.white : (color ?? Theme.of(context).textTheme.bodyLarge?.color), size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: isPrimary ? Colors.white : (color ?? Theme.of(context).textTheme.bodyLarge?.color),
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: isDark 
            ? Theme.of(context).scaffoldBackgroundColor 
            : const Color(0xFFE2E4E9), 
      ),
      child: WebProGate(
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: isDark 
              ? SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent)
              : SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
              
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth;
              final isDesktop = maxWidth >= 850;
              
              final sidebar = _buildSidebarContent(context, isDark);
              final overview = _buildOverviewWidgets(context, isDark, maxWidth);
              final actions = _buildActionButtons(context, isDark, maxWidth);
              
              final deckList = _isLoading 
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF8B4EFF))) 
                  : _decks.isEmpty 
                      ? _buildEmptyState(isDark) 
                      : _buildDeckList(isDark);
  
              if (isDesktop) {
                return DashboardWeb(
                  sidebar: sidebar,
                  overview: overview,
                  deckList: deckList,
                  actions: actions,
                );
              } else {
                return DashboardMobile(
                  scaffoldKey: _scaffoldKey,
                  sidebar: sidebar,
                  overview: overview,
                  deckList: deckList,
                  actions: actions,
                );
              }
            }
          ),
        ),
      ),
    );
  }
}