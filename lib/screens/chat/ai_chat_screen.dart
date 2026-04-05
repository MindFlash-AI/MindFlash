import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/deck_model.dart';
import '../../models/card_model.dart';
import '../../services/ai_service.dart';
import '../../services/energy_service.dart';
import '../../services/ad_helper.dart';
import '../../services/card_storage_service.dart';
import '../../services/pro_service.dart'; 
import '../../widgets/animated_mascot.dart'; 
import '../dashboard/dashboard_screen.dart';
import '../web_landing/web_landing_screen.dart';
import 'ai_chat_mobile.dart';
import 'ai_chat_web.dart';

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});

  Map<String, dynamic> toJson() {
    // 🛡️ SECURITY FIX 3: Prevent 1MB Database Crashes
    // Cap saved messages to 2,500 characters. If they pasted a massive document, 
    // it was already sent to the AI. We don't need to save the whole 40k chars to DB history!
    final safeText = text.length > 2500 
        ? '${text.substring(0, 2500)}... [Message truncated to save space]' 
        : text;

    return {
      'text': safeText,
      'isUser': isUser,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        text: json['text']?.toString() ?? '',
        isUser: json['isUser'] == true,
      );
}

class AIChatScreen extends StatefulWidget {
  final Deck deck;
  final String? initialPrompt;

  const AIChatScreen({super.key, required this.deck, this.initialPrompt});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _isSidebarVisible = true;
  final List<ChatMessage> _messages = [];
  List<Flashcard> _deckCards = [];
  
  final AIService _aiService = AIService();
  final EnergyService _energyService = EnergyService();
  final CardStorageService _cardStorage = CardStorageService();

  bool _isLoading = false;
  bool _isFetchingHistory = true;
  bool _hasSentInitialPrompt = false;

  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;
  RewardedAd? _rewardedAd;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    _initServices();
    _loadBannerAd();
    _loadRewardedAd();
    _loadChatHistory();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      // 🛡️ UX FIX: Wait for the keyboard slide animation to finish, 
      // then auto-scroll to the bottom so the latest messages aren't hidden!
      Future.delayed(const Duration(milliseconds: 300), _scrollToBottom);
    }
  }

  Future<void> _initServices() async {
    await _energyService.init();
    
    final cards = await _cardStorage.getCardsForDeck(widget.deck.id);
    if (mounted) {
      setState(() {
        _deckCards = cards;
      });
    }
  }

  Future<void> _loadChatHistory() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _isFetchingHistory = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('chat')
          .doc(widget.deck.id)
          .get();

      if (doc.exists && doc.data() != null && doc.data()!['messages'] != null) {
        final raw = doc.data()!['messages'];

        if (raw is! List) return;

        final List<dynamic> decoded = List<dynamic>.from(raw);
        if (mounted) {
          setState(() {
            _messages.clear();
            _messages.addAll(
              decoded
                  .where((e) => e is Map)
                  .map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e as Map))).toList()
            );
          });
          _scrollToBottom();
        }
      }
    } catch (e) {
      debugPrint("Error loading chat history from Firestore: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingHistory = false;
        });
        
        // 🚀 Micro-Unlock: Auto-send the contextual question if one was passed in
        if (widget.initialPrompt != null && !_hasSentInitialPrompt) {
          _hasSentInitialPrompt = true;
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              _messageController.text = widget.initialPrompt!;
              _sendMessage();
            }
          });
        }
      }
    }
  }

  Future<void> _saveChatHistory() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final List<ChatMessage> recentMessages = _messages.length > 50 
          ? _messages.sublist(_messages.length - 50) 
          : _messages;

      final List<Map<String, dynamic>> jsonList = recentMessages.map((m) => m.toJson()).toList();
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('chat')
          .doc(widget.deck.id)
          .set({'messages': jsonList});
    } catch (e) {
      debugPrint("Error saving chat history to Firestore: $e");
    }
  }

  Future<void> _clearChat() async {
    HapticFeedback.lightImpact();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Clear Chat?", style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
        content: Text(
          "This will permanently delete your conversation history with the AI Tutor for this deck.",
          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Clear", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('chat')
            .doc(widget.deck.id)
            .delete();
      }
      
      if (mounted) {
        setState(() {
          _messages.clear();
        });
      }
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _bannerAd?.dispose();
    _rewardedAd?.dispose();
    super.dispose();
  }

  void _loadBannerAd() {
    if (kIsWeb || ProService().isPro) return;
    
    _bannerAd = BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isBannerAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
        },
      ),
    )..load();
  }

  void _loadRewardedAd() {
    if (kIsWeb) return;
    RewardedAd.load(
      adUnitId: AdHelper.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
        },
        onAdFailedToLoad: (err) {
          debugPrint('Failed to load a rewarded ad: ${err.message}');
          _rewardedAd = null;
        },
      ),
    );
  }

  void _showEnergyDialog() {
    final int currentEnergy = _energyService.currentEnergy;
    final bool isOutOfEnergy = currentEnergy <= 0;
    final bool isFullEnergy = currentEnergy >= _energyService.maxEnergy;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            AnimatedMascot(
              state: isOutOfEnergy ? MascotState.sad : MascotState.happy,
              size: 100,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isOutOfEnergy 
                      ? Icons.bolt 
                      : (isFullEnergy ? Icons.battery_charging_full_rounded : Icons.battery_4_bar_rounded),
                  color: isOutOfEnergy ? Colors.amber : (isFullEnergy ? const Color(0xFF00C853) : const Color(0xFF8B4EFF)),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  isOutOfEnergy 
                      ? "Out of Energy" 
                      : (isFullEnergy ? "Fully Charged!" : "Looking Good! ⚡"), 
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ],
        ),
        content: Text(
          isOutOfEnergy
              ? "Your AI Tutor needs a quick breather! Your energy automatically resets every day at midnight.\n\nWant to skip the wait? Watch a short ad to fully recharge right now and keep studying!"
              : "You currently have $currentEnergy energy left! You're all set to keep chatting with your AI Tutor.\n\nRemember, your energy automatically refills to full every day at midnight." + (!isFullEnergy ? "\n\nWant to top up to full right now?" : ""),
          textAlign: TextAlign.center,
          style: TextStyle(height: 1.4, color: Theme.of(context).textTheme.bodyMedium?.color),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          if (!isFullEnergy)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                isOutOfEnergy ? "Maybe Later" : "Back to Chat", 
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          if (isFullEnergy)
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B4EFF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text("Awesome!", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          else
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showRewardedAd();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B4EFF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text("Watch Ad", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  void _showRewardedAd() {
    if (kIsWeb) {
      _grantEnergyReward();
      return;
    }

    if (_rewardedAd != null) {
      try {
        _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
          onAdDismissedFullScreenContent: (ad) {
            ad.dispose();
            setState(() => _rewardedAd = null);
            _loadRewardedAd(); 
          },
          onAdFailedToShowFullScreenContent: (ad, error) {
            ad.dispose();
            setState(() => _rewardedAd = null);
            _loadRewardedAd();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Oh no, the ad couldn't be played. Please try again later! 🎬")),
              );
            }
          },
        );

        _rewardedAd!.show(
          onUserEarnedReward: (AdWithoutView ad, RewardItem reward) async {
            await _grantEnergyReward();
          },
        );
      } catch (e) {
        setState(() => _rewardedAd = null);
        _loadRewardedAd();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Oops! The ad system hit a snag. You might have reached your daily limit. Please check back tomorrow! 🌟")),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("We couldn't find an ad right now. You may have reached your daily limit (5/day) to keep the AI healthy! Please try again tomorrow. 🌟")),
        );
      }
      _loadRewardedAd();
    }
  }

  Future<void> _grantEnergyReward() async {
    if (mounted) setState(() => _isLoading = true);

    try {
      if (kIsWeb) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Ad rewards are only available on mobile."),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      await _energyService.refillEnergy();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("⚡ Energy Restored!"),
            backgroundColor: Colors.green,
          ),
        );
      }

    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    if (_energyService.currentEnergy <= 0) {
      HapticFeedback.heavyImpact();
      _showEnergyDialog();
      return;
    }

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });

    // 🚀 COST OPTIMIZATION: Removed redundant _saveChatHistory() here.
    // We wait for the AI to reply and save both messages at once, cutting Firestore writes by 50%!
    _messageController.clear();
    _focusNode.requestFocus();
    _scrollToBottom();
    HapticFeedback.lightImpact();

    try {
      final recentHistory = _messages.length > 8 
          ? _messages.sublist(_messages.length - 8) 
          : _messages;

      final response = await _aiService.processTutorChat(
        text: text,
        deck: widget.deck,
        cards: _deckCards,
        chatHistory: recentHistory.map((m) => m.toJson()).toList(), 
      );
      
      setState(() {
        _messages.add(ChatMessage(text: response.message, isUser: false));
        _isLoading = false;
      });
      _saveChatHistory();
      _focusNode.requestFocus();
      _scrollToBottom();
      HapticFeedback.mediumImpact();
    } catch (e, stackTrace) {
      print("🔥 CRASH REPORT: $e");
      print("🔥 STACK TRACE: $stackTrace");

      if (e.toString().toLowerCase().contains('energy')) {
        setState(() {
          _isLoading = false;
          if (_messages.isNotEmpty && _messages.last.isUser) _messages.removeLast();
        });
        _showEnergyDialog();
      } else {
        setState(() {
          _messages.add(
            ChatMessage(
              text: "Oops, my circuits got a little tangled! 🤖 I couldn't process that right now. Could you please try asking again?",
              isUser: false,
            ),
          );
          _isLoading = false;
        });
        _saveChatHistory();
        _focusNode.requestFocus();
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _toggleSidebar() {
    HapticFeedback.lightImpact();
    setState(() => _isSidebarVisible = !_isSidebarVisible);
  }

  void _navigateToDashboard() {
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const DashboardScreen()), (route) => false);
  }

  void _navigateToWebsite() {
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const WebLandingScreen()), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 850;
        
        if (isDesktop) {
          return AIChatWeb(
            deck: widget.deck,
            messages: _messages,
            isLoading: _isLoading,
            isFetchingHistory: _isFetchingHistory,
            messageController: _messageController,
            scrollController: _scrollController,
            focusNode: _focusNode,
            energyStream: _energyService.energyStream,
            currentEnergy: _energyService.currentEnergy,
            isSidebarVisible: _isSidebarVisible,
            onSendMessage: _sendMessage,
            onClearChat: _clearChat,
            onEnergyTap: _showEnergyDialog,
            onBack: () => Navigator.pop(context),
            onToggleSidebar: _toggleSidebar,
            onDashboardTap: _navigateToDashboard,
            onWebsiteTap: _navigateToWebsite,
          );
        } else {
          return AIChatMobile(
            deck: widget.deck,
            messages: _messages,
            isLoading: _isLoading,
            isFetchingHistory: _isFetchingHistory,
            messageController: _messageController,
            scrollController: _scrollController,
            focusNode: _focusNode,
            energyStream: _energyService.energyStream,
            currentEnergy: _energyService.currentEnergy,
            bannerAd: _bannerAd,
            isBannerAdLoaded: _isBannerAdLoaded,
            onSendMessage: _sendMessage,
            onClearChat: _clearChat,
            onEnergyTap: _showEnergyDialog,
            onBack: () => Navigator.pop(context),
          );
        }
      }
    );
  }
}