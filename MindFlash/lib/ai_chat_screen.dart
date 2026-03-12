import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'ai_service.dart';
import 'deck_model.dart';
import 'deck_view.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final bool isFile;
  final Deck? generatedDeck;
  final Deck? editedDeck;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.isFile = false,
    this.generatedDeck,
    this.editedDeck,
  });
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
            text: "Hi! I'm MindFlash AI. I've synced with your library. You can ask me about your current decks, request a new deck on a topic, or upload a document!",
            isUser: false,
          )
        );
        _isInitializing = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(text: "Error initializing AI: $e", isUser: false));
        _isInitializing = false;
      });
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
        } else if (extension == 'txt') {
          extractedText = await file.readAsString();
        }

        if (extractedText.trim().isEmpty) {
          throw Exception("Could not find any readable text in this file.");
        }

        if (extractedText.length > 50000) {
          extractedText = extractedText.substring(0, 50000);
        }

        AIResponse aiResponse = await _aiService.processInput(
          fileText: extractedText,
          fileName: fileName,
        );

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
      }
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showError(String error) {
    setState(() {
      _isTyping = false;
      _messages.add(ChatMessage(
        text: "Sorry, an error occurred: ${error.replaceAll('Exception: ', '')}", 
        isUser: false
      ));
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF9FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black87),
        title: Row(
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
        ),
      ),
      body: Column(
        children: [
          if (_isInitializing)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF7A40F2)),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length) return _buildTypingIndicator();
                  return _buildMessageBubble(_messages[index]);
                },
              ),
            ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    bool isAi = !message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isAi)
            Container(
              margin: const EdgeInsets.only(right: 8),
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF5B4FE6), Color(0xFFE940A3)]),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
            ),
          
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: message.isUser ? const Color(0xFF7A40F2) : Colors.white,
                    borderRadius: BorderRadius.circular(20).copyWith(
                      bottomRight: message.isUser ? const Radius.circular(4) : const Radius.circular(20),
                      bottomLeft: isAi ? const Radius.circular(4) : const Radius.circular(20),
                    ),
                    boxShadow: [
                      if (isAi)
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: message.isFile
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.insert_drive_file, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text(message.text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        )
                      : Text(
                          message.text,
                          style: TextStyle(
                            color: message.isUser ? Colors.white : Colors.black87,
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                ),
                
                if (message.generatedDeck != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: _buildDeckCard(message.generatedDeck!, isEdited: false),
                  ),
                  
                if (message.editedDeck != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: _buildDeckCard(message.editedDeck!, isEdited: true),
                  )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeckCard(Deck deck, {bool isEdited = false}) {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBC1FF)),
        boxShadow: [BoxShadow(color: const Color(0xFF7A40F2).withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => DeckView(deck: deck)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFFF3E8FF), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.style, color: Color(0xFF7A40F2), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(deck.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text("${deck.cardCount} cards", style: const TextStyle(color: Color(0xFF7A40F2), fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(color: const Color(0xFF7A40F2), borderRadius: BorderRadius.circular(8)),
                  child: Center(
                    child: Text(
                      isEdited ? "View Updated Deck" : "View Deck", 
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)
                    )
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF5B4FE6), Color(0xFFE940A3)]),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20).copyWith(bottomLeft: const Radius.circular(4)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF7A40F2))),
                SizedBox(width: 10),
                Text("Analyzing & thinking...", style: TextStyle(color: Colors.grey, fontSize: 13, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              onPressed: _handleFileUpload,
              icon: const Icon(Icons.attach_file, color: Colors.grey),
              tooltip: "Upload PDF or TXT",
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _textController,
                  decoration: const InputDecoration(
                    hintText: "Ask a question or request a deck...",
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (text) => _handleTextSubmit(text),
                  enabled: !_isInitializing,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isInitializing ? [Colors.grey, Colors.grey] : [const Color(0xFF5B4FE6), const Color(0xFFE940A3)],
                ),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _isInitializing ? null : () => _handleTextSubmit(_textController.text),
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}