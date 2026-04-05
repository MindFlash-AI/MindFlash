import 'package:flutter/material.dart';

import '../../models/deck_model.dart';
import '../../widgets/animated_mascot.dart';
import '../../widgets/universal_sidebar.dart';
import 'ai_chat_screen.dart'; // For ChatMessage model
import 'widgets/chat_message_bubble.dart';

class AIChatWeb extends StatelessWidget {
  final Deck deck;
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isFetchingHistory;
  final TextEditingController messageController;
  final ScrollController scrollController;
  final FocusNode focusNode;
  final Stream<int> energyStream;
  final int currentEnergy;
  
  final VoidCallback onSendMessage;
  final VoidCallback onClearChat;
  final VoidCallback onEnergyTap;
  final VoidCallback onBack;
  
  final bool isSidebarVisible;
  final VoidCallback onToggleSidebar;
  final VoidCallback onDashboardTap;
  final VoidCallback onWebsiteTap;

  const AIChatWeb({
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
    required this.onSendMessage,
    required this.onClearChat,
    required this.onEnergyTap,
    required this.onBack,
    required this.isSidebarVisible,
    required this.onToggleSidebar,
    required this.onDashboardTap,
    required this.onWebsiteTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final mainContent = Scaffold(
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
        leadingWidth: isSidebarVisible ? 56 : 100,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isSidebarVisible)
              IconButton(
                icon: Icon(Icons.menu_rounded, color: Theme.of(context).textTheme.bodyLarge?.color),
                onPressed: onToggleSidebar,
                tooltip: "Open Sidebar",
              ),
            IconButton(
              icon: Icon(Icons.arrow_back_ios_new, color: Theme.of(context).appBarTheme.foregroundColor),
              onPressed: onBack,
              tooltip: "Back to Deck",
            ),
          ],
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
                margin: const EdgeInsets.only(right: 24),
                child: Material(
                  color: energy > 0 ? const Color(0xFF8B4EFF).withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: onEnergyTap,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Row(
                        children: [
                          Icon(Icons.bolt, color: energy > 0 ? const Color(0xFF8B4EFF) : Colors.red, size: 18),
                          const SizedBox(width: 6),
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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: Column(
            children: [
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
                            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                            itemCount: messages.length,
                            itemBuilder: (context, index) => ChatMessageBubble(message: messages[index], isDark: isDark, isDesktop: true),
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
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                color: Theme.of(context).scaffoldBackgroundColor,
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
                        // 🛡️ HCI: Enable sending simply by pressing the physical 'Enter' key on Desktop Web
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) { if (!isLoading) onSendMessage(); },
                        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                        decoration: InputDecoration(
                          hintText: "Ask a question... (Press Enter to send)",
                          hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade400),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF1E1533) : const Color(0xFFF8F9FA),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      margin: const EdgeInsets.only(bottom: 2),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [Color(0xFF8B4EFF), Color(0xFFE841A1)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send_rounded, color: Colors.white, size: 22), 
                        onPressed: isLoading ? null : onSendMessage,
                        tooltip: "Send Message",
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Scaffold(
      body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            width: isSidebarVisible ? 280 : 0,
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.topLeft,
                maxWidth: 280,
                minWidth: 280,
                child: UniversalSidebar(
                  activeItem: SidebarActiveItem.none, // Chat sits slightly outside dashboard
                  showMinimizeButton: true,
                  onMinimizeTap: onToggleSidebar,
                  onDashboardTap: onDashboardTap,
                  onWebsiteTap: onWebsiteTap,
                ),
              ),
            ),
          ),
          Expanded(child: mainContent),
        ],
      ),
    );
  }
}