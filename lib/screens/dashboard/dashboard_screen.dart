import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';

import '../../constants/constants.dart';
import '../../models/deck_model.dart';
import '../../services/deck_storage_service.dart';
import '../../services/card_storage_service.dart';
import '../../services/ai_service.dart';
import '../../services/ad_helper.dart';
import '../../services/pro_service.dart';
import '../../services/secure_cache_service.dart';

import '../../widgets/create_deck_dialog.dart';
import '../../widgets/create_deck_ai_dialog.dart';
import '../../widgets/update_deck_ai_dialog.dart';
import '../../widgets/universal_sidebar.dart';
import '../../widgets/dialogs/feedback_dialog.dart';
import '../../widgets/web_pro_gate.dart';

import '../deck_view/deck_view.dart';
import '../study_pad/widgets/saved_notes_sheet.dart';
import '../web_landing/web_landing_screen.dart';

import 'dashboard_web.dart';
import 'dashboard_mobile.dart';
import 'widgets/dashboard_stats_row.dart';
import 'widgets/dashboard_action_buttons.dart';
import 'widgets/dashboard_empty_state.dart';
import 'widgets/dashboard_deck_list_view.dart';

enum SortOption { nameAsc, nameDesc, countDesc, countAsc }

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  final DeckStorageService _storageService = DeckStorageService();
  final CardStorageService _cardStorageService = CardStorageService();

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Deck> _decks = [];
  bool _isLoading = true;
  int _totalCards = 0;
  late AnimationController _pulseController;
  SortOption _currentSort = SortOption.nameAsc;

  NativeAd? _nativeAd;
  bool _isNativeAdLoaded = false;
  bool _isNativeAdLoading = false;

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isNativeAdLoading && _nativeAd == null) {
      _isNativeAdLoading = true;
      _loadNativeAd();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _nativeAd?.dispose();
    super.dispose();
  }

  void _loadNativeAd() {
    if (kIsWeb || ProService().isPro) return;

    final adUnitId = AdHelper.nativeAdUnitId;
    if (adUnitId.isEmpty) return;

    _nativeAd = NativeAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (mounted) setState(() => _isNativeAdLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('NativeAd failed to load: $error');
        },
      ),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.small,
        mainBackgroundColor: Theme.of(context).cardColor,
        cornerRadius: 16.0,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: const Color(0xFF8B4EFF),
          style: NativeTemplateFontStyle.bold,
          size: 14.0,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: Theme.of(context).textTheme.bodyLarge?.color,
          backgroundColor: Colors.transparent,
          style: NativeTemplateFontStyle.bold,
          size: 16.0,
        ),
      ),
    )..load();
  }

  void _applySort() {
    switch (_currentSort) {
      case SortOption.nameAsc:
        _decks.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case SortOption.nameDesc:
        _decks.sort(
            (a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
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
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final cachedData = prefs.getString('dashboard_decks_cache_$uid');
        if (cachedData != null && _decks.isEmpty) {
          final decryptedData = SecureCacheService.decrypt(cachedData, uid);
          if (decryptedData.isNotEmpty) {
            final List<dynamic> decoded = jsonDecode(decryptedData);
            final cachedDecks = decoded
                .map((e) => Deck(
                      id: e['id']?.toString() ?? '',
                      name: e['name']?.toString() ?? '',
                      subject: e['subject']?.toString() ?? '',
                      cardCount: (e['cardCount'] as num?)?.toInt() ?? 0,
                      cardOrder: e['cardOrder'] != null
                          ? List<String>.from(e['cardOrder'])
                          : [],
                    ))
                .toList();

            if (mounted) {
              setState(() {
                _decks = cachedDecks;
                _totalCards =
                    cachedDecks.fold(0, (sum, deck) => sum + deck.cardCount);
                _isLoading = false;
                _applySort();
              });
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Error loading cached decks: $e");
    }

    final decks = await _storageService.getDecks();
    if (!mounted) return;
    setState(() {
      _decks = decks;
      _totalCards = decks.fold(0, (sum, deck) => sum + deck.cardCount);
      _isLoading = false;
      _applySort();
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final String encoded = jsonEncode(decks
            .map((d) => {
                  'id': d.id,
                  'name': d.name,
                  'subject': d.subject,
                  'cardCount': d.cardCount,
                  'cardOrder': d.cardOrder,
                })
            .toList());
        final encryptedData = SecureCacheService.encrypt(encoded, uid);
        await prefs.setString('dashboard_decks_cache_$uid', encryptedData);
      }
    } catch (e) {
      debugPrint("Error saving cached decks: $e");
    }
  }

  void _onDeckCreated(Deck deck) async {
    setState(() {
      _decks.add(deck);
      _applySort();
    });
    await _storageService.addDeck(deck);
  }

  void _deleteDeck(String id) async {
    setState(() {
      _decks.removeWhere((deck) => deck.id == id);
      _totalCards = _decks.fold(0, (sum, d) => sum + d.cardCount);
    });

    await _storageService.deleteDeck(id);
    await _cardStorageService.deleteCardsByDeck(id);
  }

  void _showManualDeckModal() {
    if (_decks.length >= 20) {
      HapticFeedback.heavyImpact();
      FeedbackDialog.show(context, false,
          "You have reached the maximum limit of 20 decks. Please delete some to create new ones! 🛑");
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateDeckDialog(onDeckCreated: _onDeckCreated),
    );
  }

  void _navigateToStudyPad() async {
    if (_scaffoldKey.currentState?.isDrawerOpen == true) {
      Navigator.pop(context);
    }

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SavedNotesSheet(),
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

  Future<void> _quickScanImage() async {
    HapticFeedback.lightImpact();
    if (_decks.length >= 20) {
      HapticFeedback.heavyImpact();
      FeedbackDialog.show(context, false,
          "You have reached the maximum limit of 20 decks. Please delete some to create new ones! 🛑");
      return;
    }

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (photo != null) {
        final Uint8List fileBytes = await photo.readAsBytes();

        if (fileBytes.length > 5 * 1024 * 1024) {
          FeedbackDialog.show(
              context, false, "Image is too large. Please select an image under 5MB.");
          return;
        }

        String extension = photo.name.split('.').last.toLowerCase();
        if (extension.isEmpty) extension = 'jpg';
        String fileContent =
            "data:image/$extension;base64,${base64Encode(fileBytes)}";

        if (mounted) {
          final successMessage = await showModalBottomSheet<String>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => CreateDeckAIDialog(
              initialFileName: "Scanned Document.$extension",
              initialFileText: fileContent,
              onGenerate: (topic, fileText, fileName) => _processAIGeneration(
                  context, topic,
                  fileText: fileText, fileName: fileName),
            ),
          );

          if (successMessage != null && mounted) {
            HapticFeedback.mediumImpact();
            FeedbackDialog.show(context, true, successMessage);
          }
        }
      }
    } catch (e) {
      if (mounted) FeedbackDialog.show(context, false, "Error reading image: $e");
    }
  }

  Future<String> _processAIGeneration(BuildContext context, String prompt,
      {String? fileText, String? fileName, String? targetDeckId}) async {
    try {
      final aiService = AIService();
      final response = await aiService.processInput(
        text: prompt,
        fileText: fileText,
        fileName: fileName,
        targetDeckId: targetDeckId,
      );

      await _loadDecks();
      return response.message;
    } catch (e) {
      if (context.mounted) {
        HapticFeedback.heavyImpact();
        FeedbackDialog.show(
          context,
          false,
          "Failed to generate flashcards.\n\nError: ${e.toString().replaceAll('Exception:', '').trim()}",
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
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalContext).viewInsets.bottom),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(modalContext).cardColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 30.0),
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
                                  color: Theme.of(modalContext)
                                      .textTheme
                                      .bodyLarge
                                      ?.color,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(modalContext).pop(),
                              icon: Icon(Icons.close,
                                  color: isDark ? Colors.white54 : Colors.grey),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Choose how you want MindFlash AI to help you.",
                          style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white54 : Colors.grey[600]),
                        ),
                        const SizedBox(height: 24),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color:
                                  const Color(0xFF5B4FE6).withValues(alpha: 0.1),
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
                              color: Theme.of(modalContext)
                                  .textTheme
                                  .bodyLarge
                                  ?.color,
                            ),
                          ),
                          subtitle: Text(
                            "Generate a completely new deck from a prompt",
                            style: TextStyle(
                                color: isDark
                                    ? Colors.white70
                                    : Colors.grey.shade600),
                          ),
                          onTap: () async {
                            HapticFeedback.lightImpact();
                            Navigator.pop(modalContext);

                            if (_decks.length >= 20) {
                              HapticFeedback.heavyImpact();
                              FeedbackDialog.show(
                                parentContext,
                                false,
                                "You have reached the maximum limit of 20 decks. Please delete some to create new ones! 🛑",
                              );
                              return;
                            }

                            final successMessage =
                                await showModalBottomSheet<String>(
                              context: parentContext,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => CreateDeckAIDialog(
                                onGenerate: (topic, fileText, fileName) =>
                                    _processAIGeneration(parentContext, topic,
                                        fileText: fileText, fileName: fileName),
                              ),
                            );

                            if (successMessage != null &&
                                parentContext.mounted) {
                              HapticFeedback.mediumImpact();
                              FeedbackDialog.show(
                                  parentContext, true, successMessage);
                            }
                          },
                        ),
                        Divider(
                            height: 30,
                            color: isDark ? Colors.white12 : Colors.grey.shade200),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color:
                                  const Color(0xFFE940A3).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child:
                                const Icon(Icons.update, color: Color(0xFFE940A3)),
                          ),
                          title: Text(
                            "Update Deck with AI",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Theme.of(modalContext)
                                  .textTheme
                                  .bodyLarge
                                  ?.color,
                            ),
                          ),
                          subtitle: Text(
                            "Add newly generated cards to an existing deck",
                            style: TextStyle(
                                color: isDark
                                    ? Colors.white70
                                    : Colors.grey.shade600),
                          ),
                          onTap: () async {
                            HapticFeedback.lightImpact();
                            Navigator.pop(modalContext);

                            if (_decks.isEmpty) {
                              HapticFeedback.heavyImpact();
                              FeedbackDialog.show(
                                parentContext,
                                false,
                                "You need to create a deck first before updating one!",
                              );
                              return;
                            }

                            final successMessage =
                                await showModalBottomSheet<String>(
                              context: parentContext,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => UpdateDeckAIDialog(
                                decks: _decks,
                                onGenerate: (Deck deck, String topic) {
                                  final engineeredPrompt =
                                      "Update the deck '${deck.name}' with the following topic/cards: $topic";
                                  return _processAIGeneration(
                                      parentContext, engineeredPrompt,
                                      targetDeckId: deck.id);
                                },
                              ),
                            );

                            if (successMessage != null &&
                                parentContext.mounted) {
                              HapticFeedback.mediumImpact();
                              FeedbackDialog.show(
                                  parentContext, true, successMessage);
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
        });
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
              ? SystemUiOverlayStyle.light
                  .copyWith(statusBarColor: Colors.transparent)
              : SystemUiOverlayStyle.dark
                  .copyWith(statusBarColor: Colors.transparent),
          child: LayoutBuilder(builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            final isDesktop = maxWidth >= 850;

            final sidebar = UniversalSidebar(
              activeItem: SidebarActiveItem.dashboard,
              onDashboardTap: () {
                if (_scaffoldKey.currentState?.isDrawerOpen == true) {
                  Navigator.pop(context);
                }
              },
              onStudyPadTap: _navigateToStudyPad,
              onWebsiteTap: _navigateToWebsite,
            );

            final overview = DashboardStatsRow(
              decks: _decks,
              totalCards: _totalCards,
              isDark: isDark,
              maxWidth: maxWidth,
            );

            final actions = DashboardActionButtons(
              isDark: isDark,
              maxWidth: maxWidth,
              pulseController: _pulseController,
              onManualDeckTap: _showManualDeckModal,
              onQuickScanTap: _quickScanImage,
              onAIOptionsTap: () => _showAIOptionsModal(context),
              onStudyPadTap: _navigateToStudyPad,
            );

            final deckList = _isLoading
                ? DashboardDeckListView(
                    decks: const [],
                    isDark: isDark,
                    isLoading: true,
                    currentSort: _currentSort,
                    onSortChanged: (_) {},
                    isNativeAdLoaded: false,
                    onDeleteDeck: (_) {},
                    onDeckTap: (_) {},
                  )
                : _decks.isEmpty
                    ? DashboardEmptyState(
                        isDark: isDark,
                        pulseController: _pulseController,
                        onGenerateTap: () => _showAIOptionsModal(context),
                      )
                    : DashboardDeckListView(
                        decks: _decks,
                        isDark: isDark,
                        isLoading: false,
                        currentSort: _currentSort,
                        onSortChanged: (option) {
                          setState(() {
                            _currentSort = option;
                            _applySort();
                          });
                        },
                        nativeAd: _nativeAd,
                        isNativeAdLoaded: _isNativeAdLoaded,
                        onDeleteDeck: _deleteDeck,
                        onDeckTap: (deck) async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DeckView(deck: deck),
                            ),
                          );
                          setState(() {
                            _totalCards =
                                _decks.fold(0, (sum, d) => sum + d.cardCount);
                            _applySort();
                          });
                        },
                      );

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
          }),
        ),
      ),
    );
  }
}
