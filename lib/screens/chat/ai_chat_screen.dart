import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/ai_service.dart';
import '../../models/deck_model.dart';
import '../../models/card_model.dart';
import '../deck_view/deck_view.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final Deck? generatedDeck;
  final Deck? editedDeck;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.generatedDeck,
    this.editedDeck,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      if (generatedDeck != null)
        'generatedDeck': {
          'id': generatedDeck!.id,
          'name': generatedDeck!.name,
          'subject': generatedDeck!.subject,
          'cardCount': generatedDeck!.cardCount,
        },
      if (editedDeck != null)
        'editedDeck': {
          'id': editedDeck!.id,
          'name': editedDeck!.name,
          'subject': editedDeck!.subject,
          'cardCount': editedDeck!.cardCount,
        },
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'],
      isUser: json['isUser'],
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      generatedDeck: json['generatedDeck'] != null
          ? Deck(
              id: json['generatedDeck']['id'],
              name: json['generatedDeck']['name'],
              subject: json['generatedDeck']['subject'],
              cardCount: json['generatedDeck']['cardCount'],
            )
          : null,
      editedDeck: json['editedDeck'] != null
          ? Deck(
              id: json['editedDeck']['id'],
              name: json['editedDeck']['name'],
              subject: json['editedDeck']['subject'],
              cardCount: json['editedDeck']['cardCount'],
            )
          : null,
    );
  }
}

class AIChatScreen extends StatefulWidget {
  final Deck deck;
  final List<Flashcard> cards;

  const AIChatScreen({super.key, required this.deck, required this.cards});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final AIService _aiService;

  List<ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _aiService = AIService();

    _loadChatHistory().then((_) {
      if (_messages.isEmpty) {
        _initAIContext();
      } else {
        _restoreAIContext();
      }
    });
  }

  Future<void> _loadChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? historyJson = prefs.getString(
        'chat_history_${widget.deck.id}',
      );
      if (historyJson != null) {
        final List<dynamic> decoded = jsonDecode(historyJson);
        setState(() {
          _messages = decoded.map((e) => ChatMessage.fromJson(e)).toList();
        });
      }
    } catch (e) {
      debugPrint("Failed to load chat history: $e");
    }
  }

  Future<void> _saveChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String historyJson = jsonEncode(
        _messages.map((m) => m.toJson()).toList(),
      );
      await prefs.setString('chat_history_${widget.deck.id}', historyJson);
    } catch (e) {
      debugPrint("Failed to save chat history: $e");
    }
  }

  void _clearChatHistory() async {
    HapticFeedback.mediumImpact();
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Clear Chat?",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "This will permanently delete your conversation history with the AI Tutor for this deck.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Clear",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('chat_history_${widget.deck.id}');
      setState(() {
        _messages.clear();
        _isInitializing = true;
      });
      _initAIContext();
    }
  }

  Future<void> _initAIContext() async {
    try {
      String cardContext = widget.cards
          .map((c) => "Q: ${c.question} A: ${c.answer}")
          .join("\n");

      String initPrompt =
          "System Initialization: The user is studying a flashcard deck named '${widget.deck.name}'. The subject is '${widget.deck.subject}'. Here are the exact flashcards in their deck:\n\n$cardContext\n\nAct as a highly encouraging, expert personal tutor exclusively for this deck. You can quiz them, explain hard concepts simply, or provide mnemonics. Keep your responses concise and formatted cleanly. Reply ONLY with the exact word 'ACKNOWLEDGED' to confirm you understand.";

      await _aiService.processInput(text: initPrompt);

      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              text:
                  "Hi! I'm your AI Tutor for **${widget.deck.name}**.\n\n"
                  "I have fully memorized all ${widget.cards.length} cards in this deck. How can I help you study today?\n\n"
                  "* Ask me to explain a confusing concept\n"
                  "* Tell me to quiz you\n"
                  "* Ask for a summary or memory tricks",
              isUser: false,
            ),
          );
          _isInitializing = false;
        });
        _saveChatHistory();
      }
    } catch (e) {
      _showError("Failed to sync deck context with AI: $e");
      if (mounted) setState(() => _isInitializing = false);
    }
  }

  Future<void> _restoreAIContext() async {
    try {
      String cardContext = widget.cards
          .map((c) => "Q: ${c.question} A: ${c.answer}")
          .join("\n");

      String initPrompt =
          "System Initialization: The user is returning to their flashcard deck named '${widget.deck.name}'. The subject is '${widget.deck.subject}'. Here are the exact flashcards:\n\n$cardContext\n\nAct as a highly encouraging, expert personal tutor. Reply ONLY with the exact word 'ACKNOWLEDGED' to confirm.";

      await _aiService.processInput(text: initPrompt);

      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      _showError("Failed to sync deck context with AI: $e");
      if (mounted) setState(() => _isInitializing = false);
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _handleTextSubmit(String text) async {
    if (text.trim().isEmpty || _isInitializing) return;

    _textController.clear();
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isTyping = true;
    });
    _saveChatHistory();
    _scrollToBottom();

    try {
      AIResponse aiResponse = await _aiService.processInput(text: text);

      String reply = aiResponse.message == 'ACKNOWLEDGED'
          ? "I'm ready! What would you like to know?"
          : aiResponse.message;

      setState(() {
        _isTyping = false;
        _messages.add(
          ChatMessage(
            text: reply,
            isUser: false,
            generatedDeck: aiResponse.generatedDeck,
            editedDeck: aiResponse.editedDeck,
          ),
        );
      });
      _saveChatHistory();
      _scrollToBottom();
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showError(String error) {
    setState(() {
      _isTyping = false;
      _messages.add(
        ChatMessage(
          text: "⚠️ **Error:** ${error.replaceAll('Exception: ', '')}",
          isUser: false,
        ),
      );
    });
    _saveChatHistory();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFFFDF9FF),
      appBar: AppBar(
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.white.withOpacity(0.8)),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black87),
        title: _buildAppBarTitle(),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded, color: Colors.black54),
            onPressed: _clearChatHistory,
            tooltip: "Clear Chat",
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: _isInitializing
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF8B4EFF),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 100, 16, 140),
                          itemCount: _messages.length + (_isTyping ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _messages.length)
                              return _buildShimmerLoading();

                            bool isLastInGroup = true;
                            if (index < _messages.length - 1) {
                              isLastInGroup =
                                  _messages[index].isUser !=
                                  _messages[index + 1].isUser;
                            }

                            return _buildMessageBubble(
                              _messages[index],
                              isLastInGroup,
                            );
                          },
                        ),
                ),
              ],
            ),
            Align(alignment: Alignment.bottomCenter, child: _buildInputArea()),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBarTitle() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF8B4EFF), Color(0xFFE841A1)],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Deck Tutor",
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                widget.deck.name,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isLastInGroup) {
    bool isAi = !message.isUser;

    return Padding(
      padding: EdgeInsets.only(bottom: isLastInGroup ? 16.0 : 4.0),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isAi)
            SizedBox(
              width: 32,
              child: isLastInGroup
                  ? Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF8B4EFF), Color(0xFFE841A1)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 12,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: message.isUser
                        ? const Color(0xFF8B4EFF)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(18).copyWith(
                      bottomRight: (message.isUser && isLastInGroup)
                          ? const Radius.circular(4)
                          : null,
                      bottomLeft: (isAi && isLastInGroup)
                          ? const Radius.circular(4)
                          : null,
                    ),
                    boxShadow: [
                      if (isAi)
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                    ],
                  ),
                  child: MarkdownBody(
                    data: message.text,
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(
                        color: message.isUser ? Colors.white : Colors.black87,
                        fontSize: 15,
                        height: 1.4,
                      ),
                      strong: const TextStyle(fontWeight: FontWeight.bold),
                      listBullet: TextStyle(
                        color: message.isUser ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ),
                if (message.generatedDeck != null)
                  _buildDeckCard(message.generatedDeck!, "New Deck"),
                if (message.editedDeck != null)
                  _buildDeckCard(message.editedDeck!, "Updated Deck"),
              ],
            ),
          ),
          if (message.isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Row(
          children: [
            const CircleAvatar(radius: 12, backgroundColor: Colors.white),
            const SizedBox(width: 10),
            Container(
              width: 200,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeckCard(Deck deck, String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEBC1FF)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.layers, color: Color(0xFF8B4EFF)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    deck.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DeckView(deck: deck)),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B4EFF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                minimumSize: const Size(double.infinity, 36),
              ),
              child: Text("View $label"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            border: Border(
              top: BorderSide(color: Colors.grey.withOpacity(0.2)),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_messages.length < 3) _buildSuggestionChips(),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _textController,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: "Ask your tutor...",
                          border: InputBorder.none,
                          hintStyle: TextStyle(color: Colors.black38),
                        ),
                        onSubmitted: _handleTextSubmit,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildSendButton(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionChips() {
    final suggestions = [
      "Quiz me on this",
      "Explain the hardest card",
      "Summarize key points",
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: suggestions
            .map(
              (s) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  label: Text(
                    s,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8B4EFF),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: const Color(0xFF8B4EFF).withOpacity(0.1),
                  shape: const StadiumBorder(
                    side: BorderSide(color: Colors.transparent),
                  ),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    _handleTextSubmit(s);
                  },
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildSendButton() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF8B4EFF), Color(0xFFE841A1)],
        ),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: () {
          HapticFeedback.selectionClick();
          _handleTextSubmit(_textController.text);
        },
        icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
      ),
    );
  }
}
