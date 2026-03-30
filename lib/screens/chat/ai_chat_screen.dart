import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/deck_model.dart';
import '../../models/card_model.dart';
import '../../services/ai_service.dart';
import '../../services/energy_service.dart';
import '../../services/ad_helper.dart';
import '../../services/card_storage_service.dart';
import '../../widgets/animated_mascot.dart'; 

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});

  Map<String, dynamic> toJson() => {
        'text': text,
        'isUser': isUser,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        text: json['text'],
        isUser: json['isUser'],
      );
}

class AIChatScreen extends StatefulWidget {
  final Deck deck;

  const AIChatScreen({super.key, required this.deck});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  
  final AIService _aiService = AIService();
  final EnergyService _energyService = EnergyService();
  final CardStorageService _cardStorage = CardStorageService();

  bool _isLoading = false;
  int _currentEnergy = 0;

  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;
  RewardedAd? _rewardedAd;

  @override
  void initState() {
    super.initState();
    _initServices();
    _loadBannerAd();
    _loadRewardedAd();
    _loadChatHistory();
  }

  Future<void> _initServices() async {
    await _energyService.init();
    if (mounted) {
      setState(() {
        _currentEnergy = _energyService.currentEnergy;
      });
    }
  }

  Future<void> _loadChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyJson = prefs.getString('chat_history_${widget.deck.id}');

    if (historyJson != null) {
      final List<dynamic> decoded = jsonDecode(historyJson);
      if (mounted) {
        setState(() {
          _messages.addAll(decoded.map((e) => ChatMessage.fromJson(e)).toList());
        });
        _scrollToBottom();
      }
    }
  }

  Future<void> _saveChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> jsonList = _messages.map((m) => m.toJson()).toList();
    await prefs.setString('chat_history_${widget.deck.id}', jsonEncode(jsonList));
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('chat_history_${widget.deck.id}');
      
      if (mounted) {
        setState(() {
          _messages.clear();
        });
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _bannerAd?.dispose();
    _rewardedAd?.dispose();
    super.dispose();
  }

  void _loadBannerAd() {
    if (kIsWeb) return;
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
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _loadRewardedAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _loadRewardedAd();
            },
          );
          _rewardedAd = ad;
        },
        onAdFailedToLoad: (err) {},
      ),
    );
  }

  void _showEnergyDialog() {
    final bool isOutOfEnergy = _currentEnergy <= 0;
    final bool isFullEnergy = _currentEnergy >= EnergyService.maxEnergy;

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
              : "You currently have $_currentEnergy energy left! You're all set to keep chatting with your AI Tutor.\n\nRemember, your energy automatically refills to full every day at midnight." + (!isFullEnergy ? "\n\nWant to top up to full right now?" : ""),
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
                if (_rewardedAd != null) {
                  _rewardedAd!.show(
                    onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
                      _grantEnergyReward();
                    },
                  );
                } else {
                  _grantEnergyReward();
                }
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

  Future<void> _grantEnergyReward() async {
    await _energyService.refillEnergy();
    if (mounted) {
      setState(() {
        _currentEnergy = _energyService.currentEnergy;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚡ Energy Restored!"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    if (_currentEnergy <= 0) {
      HapticFeedback.heavyImpact();
      _showEnergyDialog();
      return;
    }

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });

    _saveChatHistory();
    _messageController.clear();
    _scrollToBottom();
    HapticFeedback.lightImpact();

    try {
      final List<Flashcard> cards = await _cardStorage.getCardsForDeck(widget.deck.id);

      final response = await _aiService.processTutorChat(
        text: text,
        deck: widget.deck,
        cards: cards,
      );
      
      await _energyService.deductEnergy();
      
      setState(() {
        _currentEnergy = _energyService.currentEnergy;
        _messages.add(ChatMessage(text: response.message, isUser: false));
        _isLoading = false;
      });
      _saveChatHistory();
      _scrollToBottom();
      HapticFeedback.mediumImpact();
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(
            text: "Sorry, I encountered an error: ${e.toString()}",
            isUser: false,
          ),
        );
        _isLoading = false;
      });
      _saveChatHistory();
      _scrollToBottom();
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          children: [
            const Text("AI Tutor", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(
              widget.deck.name,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white70 : Colors.grey.shade600,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Theme.of(context).appBarTheme.foregroundColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, color: isDark ? Colors.white54 : Colors.black54),
            onPressed: _clearChat,
            tooltip: 'Clear Chat',
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Material(
              color: _currentEnergy > 0 
                  ? const Color(0xFF8B4EFF).withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  HapticFeedback.lightImpact();
                  _showEnergyDialog();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    children: [
                      Icon(
                        Icons.bolt,
                        color: _currentEnergy > 0 ? const Color(0xFF8B4EFF) : Colors.red,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "$_currentEnergy",
                        style: TextStyle(
                          color: _currentEnergy > 0 ? const Color(0xFF8B4EFF) : Colors.red,
                          fontWeight: FontWeight.bold,
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
      body: Column(
        children: [
          // Fixed 50px space reservation to prevent chat layout jump!
          if (!kIsWeb)
            SizedBox(
              height: 50,
              width: double.infinity,
              child: (_isBannerAdLoaded && _bannerAd != null)
                  ? AdWidget(ad: _bannerAd!)
                  : const SizedBox.shrink(),
            ),
            
          Expanded(
            child: _messages.isEmpty 
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const AnimatedMascot(state: MascotState.happy, size: 150),
                      const SizedBox(height: 24),
                      Text(
                        "Ready to study?",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Ask me anything about ${widget.deck.name}!",
                        style: TextStyle(
                          fontSize: 15,
                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    return _buildMessageBubble(_messages[index]);
                  },
                ),
          ),

          if (_isLoading)
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const AnimatedMascot(state: MascotState.thinking, size: 46),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                        bottomLeft: Radius.circular(4), 
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF8B4EFF)),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Thinking...",
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Input Area
          Container(
            padding: EdgeInsets.fromLTRB(
              16, 12, 16, 
              MediaQuery.of(context).padding.bottom > 0 
                  ? MediaQuery.of(context).padding.bottom 
                  : 16
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
                  offset: const Offset(0, -4),
                  blurRadius: 16,
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 4,
                    minLines: 1,
                    textInputAction: TextInputAction.newline,
                    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                    decoration: InputDecoration(
                      hintText: "Ask a question...",
                      hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade400),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E1533) : const Color(0xFFF8F9FA),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  margin: const EdgeInsets.only(bottom: 2),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF8B4EFF), Color(0xFFE841A1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                    onPressed: _isLoading ? null : _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) ...[
            const Padding(
              padding: EdgeInsets.only(right: 8.0), 
              child: AnimatedMascot(state: MascotState.happy, size: 38),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14.0),
              decoration: BoxDecoration(
                color: message.isUser ? null : Theme.of(context).cardColor,
                gradient: message.isUser
                    ? const LinearGradient(
                        colors: [Color(0xFF8B4EFF), Color(0xFFE841A1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(message.isUser ? 20 : 4), 
                  bottomRight: Radius.circular(message.isUser ? 4 : 20),
                ),
                boxShadow: message.isUser
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.3 : 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: message.isUser
                  ? Text(
                      message.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  : MarkdownBody(
                      data: message.text,
                      selectable: true,
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16, height: 1.5),
                        strong: TextStyle(fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black),
                        em: TextStyle(fontStyle: FontStyle.italic, color: isDark ? Colors.white70 : Colors.black87),
                        listBullet: const TextStyle(color: Color(0xFF8B4EFF), fontSize: 16),
                        h1: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                        h2: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                        h3: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                        code: TextStyle(
                          backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                          color: const Color(0xFFE841A1),
                          fontFamily: 'monospace',
                          fontSize: 14,
                        ),
                        codeblockDecoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade200),
                        ),
                        blockquoteDecoration: BoxDecoration(
                          border: const Border(left: BorderSide(color: Color(0xFF8B4EFF), width: 4)),
                          color: const Color(0xFF8B4EFF).withOpacity(0.05),
                        ),
                        blockquotePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
            ),
          ),
          if (message.isUser) const SizedBox(width: 24),
        ],
      ),
    );
  }
}