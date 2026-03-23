import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:shimmer/shimmer.dart';

// Assuming these imports exist in your project
import 'ai_service.dart';
import 'deck_model.dart';
import 'deck_view.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final bool isFile;
  final Deck? generatedDeck;
  final Deck? editedDeck;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.isFile = false,
    this.generatedDeck,
    this.editedDeck,
  }) : timestamp = DateTime.now();
}

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

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
    _initAI();
  }

  Future<void> _initAI() async {
    try {
      await _aiService.processInput();
      setState(() {
        _messages.add(
          ChatMessage(
            text: "Hi! I'm **MindFlash AI**. I've synced with your library.\n\n"
                "* Ask about your current decks\n"
                "* Request a new deck on any topic\n"
                "* Upload a PDF to generate flashcards",
            isUser: false,
          ),
        );
        _isInitializing = false;
      });
    } catch (e) {
      _showError("Error initializing AI: $e");
      setState(() => _isInitializing = false);
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
    _scrollToBottom();

    try {
      AIResponse aiResponse = await _aiService.processInput(text: text);
      setState(() {
        _isTyping = false;
        _messages.add(
          ChatMessage(
            text: aiResponse.message,
            isUser: false,
            generatedDeck: aiResponse.generatedDeck,
            editedDeck: aiResponse.editedDeck,
          ),
        );
      });
      _scrollToBottom();
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _handleFileUpload() async {
    if (_isInitializing) return;

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt'],
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        String fileName = result.files.single.name;
        String extension = result.files.single.extension?.toLowerCase() ?? '';

        setState(() {
          _messages.add(ChatMessage(text: fileName, isUser: true, isFile: true));
          _isTyping = true;
        });
        _scrollToBottom();

        String extractedText = '';
        if (extension == 'pdf') {
          final PdfDocument document = PdfDocument(inputBytes: await file.readAsBytes());
          extractedText = PdfTextExtractor(document).extractText();
          document.dispose();
        } else {
          extractedText = await file.readAsString();
        }

        if (extractedText.trim().isEmpty) throw Exception("File is empty.");

        AIResponse aiResponse = await _aiService.processInput(
          fileText: extractedText.length > 50000 ? extractedText.substring(0, 50000) : extractedText,
          fileName: fileName,
        );

        setState(() {
          _isTyping = false;
          _messages.add(ChatMessage(
            text: aiResponse.message,
            isUser: false,
            generatedDeck: aiResponse.generatedDeck,
            editedDeck: aiResponse.editedDeck,
          ));
        });
        _scrollToBottom();
      }
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showError(String error) {
    setState(() {
      _isTyping = false;
      _messages.add(ChatMessage(
        text: "⚠️ **Error:** ${error.replaceAll('Exception: ', '')}",
        isUser: false,
      ));
    });
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
      ),
      body: SafeArea(
        top: false, 
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: _isInitializing
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF7A40F2)))
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 100, 16, 140), 
                          itemCount: _messages.length + (_isTyping ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _messages.length) return _buildShimmerLoading();
                            
                            bool isLastInGroup = true;
                            if (index < _messages.length - 1) {
                              isLastInGroup = _messages[index].isUser != _messages[index + 1].isUser;
                            }
  
                            return _buildMessageBubble(_messages[index], isLastInGroup);
                          },
                        ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: _buildInputArea(),
            ),
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
            gradient: const LinearGradient(colors: [Color(0xFF5B4FE6), Color(0xFFE940A3)]),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 10),
        const Text("MindFlash AI", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
      ],
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isLastInGroup) {
    bool isAi = !message.isUser;

    return Padding(
      padding: EdgeInsets.only(bottom: isLastInGroup ? 16.0 : 4.0),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isAi)
            SizedBox(
              width: 32,
              child: isLastInGroup
                  ? Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 24, height: 24,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [Color(0xFF5B4FE6), Color(0xFFE940A3)]),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.auto_awesome, color: Colors.white, size: 12),
                    )
                  : const SizedBox.shrink(),
            ),
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: message.isUser ? const Color(0xFF7A40F2) : Colors.white,
                    borderRadius: BorderRadius.circular(18).copyWith(
                      bottomRight: (message.isUser && isLastInGroup) ? const Radius.circular(4) : null,
                      bottomLeft: (isAi && isLastInGroup) ? const Radius.circular(4) : null,
                    ),
                    boxShadow: [if (isAi) BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: message.isFile
                      ? _buildFileIndicator(message)
                      : MarkdownBody(
                          data: message.text,
                          styleSheet: MarkdownStyleSheet(
                            p: TextStyle(color: message.isUser ? Colors.white : Colors.black87, fontSize: 15, height: 1.4),
                            strong: const TextStyle(fontWeight: FontWeight.bold),
                            listBullet: TextStyle(color: message.isUser ? Colors.white : Colors.black87),
                          ),
                        ),
                ),
                if (message.generatedDeck != null) _buildDeckCard(message.generatedDeck!, "New Deck"),
                if (message.editedDeck != null) _buildDeckCard(message.editedDeck!, "Updated Deck"),
              ],
            ),
          ),
          if (message.isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildFileIndicator(ChatMessage message) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.description, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text(message.text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ],
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
            Container(width: 200, height: 40, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))),
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
                const Icon(Icons.layers, color: Color(0xFF7A40F2)),
                const SizedBox(width: 10),
                Expanded(child: Text(deck.name, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
              ],
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DeckView(deck: deck))),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7A40F2),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                minimumSize: const Size(double.infinity, 36),
              ),
              child: Text("View $label"),
            )
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
            border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.2))),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_messages.length < 3) _buildSuggestionChips(),
              Row(
                children: [
                  IconButton(onPressed: _handleFileUpload, icon: const Icon(Icons.add_circle_outline, color: Color(0xFF7A40F2))),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(24)),
                      child: TextField(
                        controller: _textController,
                        decoration: const InputDecoration(hintText: "Type something...", border: InputBorder.none),
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
    final suggestions = ["Create Biology deck", "Summarize last PDF", "Study tips"];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: suggestions.map((s) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ActionChip(
            label: Text(s, style: const TextStyle(fontSize: 12, color: Color(0xFF7A40F2))),
            backgroundColor: const Color(0xFFF3E8FF),
            shape: const StadiumBorder(side: BorderSide(color: Colors.transparent)),
            onPressed: () => _handleTextSubmit(s),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildSendButton() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF5B4FE6), Color(0xFFE940A3)]),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: () => _handleTextSubmit(_textController.text),
        icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
      ),
    );
  }
}