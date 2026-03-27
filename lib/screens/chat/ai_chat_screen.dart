import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'; // Required for kIsWeb
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../models/deck_model.dart';
import '../../services/ai_service.dart';
import '../../services/ad_helper.dart';
import '../../services/energy_service.dart'; // Import EnergyService

class AIChatScreen extends StatefulWidget {
  final Deck deck;

  const AIChatScreen({super.key, required this.deck});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AIService _aiService = AIService();
  final EnergyService _energyService = EnergyService(); // Initialize EnergyService
  
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  // Energy State
  int _currentEnergy = 0;
  bool _isEnergyLoaded = false;

  // Banner Ad State
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  // Rewarded Ad State
  RewardedAd? _rewardedAd;
  bool _isRewardedAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _initEnergySystem();
    _loadBannerAd();
    _loadRewardedAd();
    
    // Initial greeting
    _messages.add(
      ChatMessage(
        text: "Hi! I'm your AI tutor for **${widget.deck.name}**. What would you like to discuss or learn more about?",
        isUser: false,
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _bannerAd?.dispose();
    _rewardedAd?.dispose();
    super.dispose();
  }

  Future<void> _initEnergySystem() async {
    await _energyService.init();
    if (mounted) {
      setState(() {
        _currentEnergy = _energyService.currentEnergy;
        _isEnergyLoaded = true;
      });
    }
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
          debugPrint('Failed to load a banner ad: ${err.message}');
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
              _loadRewardedAd(); // Preload the next ad instantly
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _loadRewardedAd(); // Attempt reload on failure
            },
          );
          setState(() {
            _rewardedAd = ad;
            _isRewardedAdLoaded = true;
          });
        },
        onAdFailedToLoad: (err) {
          debugPrint('Failed to load a rewarded ad: ${err.message}');
          setState(() {
            _isRewardedAdLoaded = false;
          });
        },
      ),
    );
  }

  void _showRewardedAd() {
    HapticFeedback.mediumImpact();
    
    // Fallback for web testing so you don't get stuck
    if (kIsWeb) {
      _grantEnergyReward();
      return;
    }

    if (_isRewardedAdLoaded && _rewardedAd != null) {
      _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          _grantEnergyReward();
        },
      );
      // Reset state so we wait for the preloaded ad
      setState(() {
        _rewardedAd = null;
        _isRewardedAdLoaded = false;
      });
    } else {
      // Provide a backup if ad fails to load due to connection
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Ad not ready yet. Please ensure you have internet and try again."),
          backgroundColor: Colors.black87,
        ),
      );
      _loadRewardedAd(); // Retry loading
    }
  }

  Future<void> _grantEnergyReward() async {
    await _energyService.refillEnergy();
    if (mounted) {
      setState(() {
        _currentEnergy = _energyService.currentEnergy;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚡ 15 Energy Restored!"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Phase 3: Energy System Check
    if (_currentEnergy <= 0) {
      HapticFeedback.heavyImpact();
      return;
    }

    // Deduct 1 energy
    final hasEnergy = await _energyService.deductEnergy();
    if (!hasEnergy) return;

    setState(() {
      _currentEnergy = _energyService.currentEnergy;
      _messages.add(ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();
    HapticFeedback.lightImpact();

    try {
      final response = await _aiService.processInput(
        text: "Regarding my deck '${widget.deck.name}': $text"
      );
      setState(() {
        _messages.add(ChatMessage(text: response.message, isUser: false));
        _isLoading = false;
      });
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black12,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "AI Tutor",
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            Text(
              widget.deck.name,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          // Phase 3: Energy Indicator
          if (_isEnergyLoaded)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _currentEnergy > 0 
                  ? const Color(0xFF6B48FF).withOpacity(0.1) 
                  : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.bolt_rounded,
                    color: _currentEnergy > 0 ? const Color(0xFF6B48FF) : Colors.red,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "$_currentEnergy",
                    style: TextStyle(
                      color: _currentEnergy > 0 ? const Color(0xFF6B48FF) : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // AdMob Banner Ad placement at the top
            if (_isBannerAdLoaded && _bannerAd != null)
              Container(
                alignment: Alignment.center,
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                color: Colors.white,
                child: AdWidget(ad: _bannerAd!),
              ),
              
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16.0),
                itemCount: _messages.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length && _isLoading) {
                    return _buildLoadingIndicator();
                  }
                  final msg = _messages[index];
                  return _buildMessageBubble(msg);
                },
              ),
            ),
            
            // Phase 3: Dynamic Input Area (Input vs Refill Button)
            _isEnergyLoaded && _currentEnergy <= 0
                ? _buildAdRefillButton()
                : _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  // ... (Keep _buildMessageBubble and _buildLoadingIndicator exactly the same as before)
  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF6B48FF).withOpacity(0.1),
              child: const Icon(Icons.auto_awesome, size: 16, color: Color(0xFF6B48FF)),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF6B48FF) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                boxShadow: isUser ? [] : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: isUser 
                  ? Text(
                      message.text,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    )
                  : MarkdownBody(
                      data: message.text,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(color: Colors.black87, fontSize: 16, height: 1.4),
                        code: TextStyle(
                          backgroundColor: Colors.grey.shade100,
                          fontFamily: 'monospace',
                        ),
                        codeblockDecoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFFE0E0E0),
              child: Icon(Icons.person, size: 16, color: Colors.black54),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFF6B48FF).withOpacity(0.1),
            child: const Icon(Icons.auto_awesome, size: 16, color: Color(0xFF6B48FF)),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF6B48FF),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdRefillButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: ElevatedButton(
        onPressed: _showRewardedAd,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6B48FF),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.play_circle_outline_rounded, size: 24),
            SizedBox(width: 8),
            Text(
              "Watch Ad to Restore Energy ⚡",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              enabled: !_isLoading,
              textCapitalization: TextCapitalization.sentences,
              minLines: 1,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Ask a question about this deck...",
                hintStyle: TextStyle(color: Colors.grey.shade400),
                filled: true,
                fillColor: const Color(0xFFF8F9FA),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: _isLoading ? Colors.grey.shade300 : const Color(0xFF6B48FF),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white),
              onPressed: _isLoading ? null : _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}