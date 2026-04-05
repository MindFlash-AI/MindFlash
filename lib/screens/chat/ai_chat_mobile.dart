import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../models/deck_model.dart';
import '../../services/pro_service.dart';
import '../../widgets/animated_mascot.dart';
import 'ai_chat_screen.dart'; // For ChatMessage model
import 'widgets/chat_message_bubble.dart';

class AIChatMobile extends StatelessWidget {
  final Deck deck;
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isFetchingHistory;
  final TextEditingController messageController;
  final ScrollController scrollController;
  final FocusNode focusNode;
  final Stream<int> energyStream;
  final int currentEnergy;
  final BannerAd? bannerAd;
  final bool isBannerAdLoaded;
  
  final VoidCallback onSendMessage;
  final VoidCallback onClearChat;
  final VoidCallback onEnergyTap;
  final VoidCallback onBack;

  const AIChatMobile({
    super.key,
    required this.deck,
    required this.messages,
    required this.isLoading,
    required this.isFetchingHistory,
    required this.messageController,
    required this.scrollController,
    required this.focusNode,
    required this.energyStream,
    required this.currentEnergy,
    required this.bannerAd,
    required this.isBannerAdLoaded,
    required this.onSendMessage,
    required this.onClearChat,
    required this.onEnergyTap,
    required this.onBack,
  });

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
              deck.name,
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
          onPressed: onBack,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, color: isDark ? Colors.white54 : Colors.black54),
            onPressed: onClearChat,
            tooltip: 'Clear Chat',
          ),
          StreamBuilder<int>(
            stream: energyStream,
            initialData: currentEnergy,
            builder: (context, snapshot) {
              final energy = snapshot.data ?? 0;
              return Container(
                margin: const EdgeInsets.only(right: 16),
                child: Material(
                  color: energy > 0 ? const Color(0xFF8B4EFF).withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: onEnergyTap,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Row(
                        children: [
                          Icon(Icons.bolt, color: energy > 0 ? const Color(0xFF8B4EFF) : Colors.red, size: 18),
                          const SizedBox(width: 4),
                          Text("$energy", style: TextStyle(color: energy > 0 ? const Color(0xFF8B4EFF) : Colors.red, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }
          ),
        ],
      ),
      body: Column(
        children: [
          if (!kIsWeb && !ProService().isPro)
            SizedBox(
              height: 50,
              width: double.infinity,
              child: (isBannerAdLoaded && bannerAd != null) ? AdWidget(ad: bannerAd!) : const SizedBox.shrink(),
            ),
            
          Expanded(
            child: isFetchingHistory
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF8B4EFF)))
                : messages.isEmpty 
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const AnimatedMascot(state: MascotState.happy, size: 150),
                            const SizedBox(height: 24),
                            Text("Ready to study?", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
                            const SizedBox(height: 8),
                            Text("Ask me anything about ${deck.name}!", style: TextStyle(fontSize: 15, color: isDark ? Colors.white54 : Colors.grey.shade600)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        itemCount: messages.length,
                        itemBuilder: (context, index) => ChatMessageBubble(message: messages[index], isDark: isDark),
                      ),
          ),

          if (isLoading)
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
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20), bottomRight: Radius.circular(20), bottomLeft: Radius.circular(4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF8B4EFF))),
                        const SizedBox(width: 8),
                        Text("Thinking...", style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade600, fontStyle: FontStyle.italic, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          Container(
            padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom > 0 ? MediaQuery.of(context).padding.bottom : 16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04), offset: const Offset(0, -4), blurRadius: 16)],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    focusNode: focusNode,
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
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  margin: const EdgeInsets.only(bottom: 2),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFF8B4EFF), Color(0xFFE841A1)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(icon: const Icon(Icons.send_rounded, color: Colors.white, size: 22), onPressed: isLoading ? null : onSendMessage),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}