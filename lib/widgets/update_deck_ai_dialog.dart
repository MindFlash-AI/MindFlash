import 'package:flutter/material.dart';
import '../models/deck_model.dart';

class UpdateDeckAIDialog extends StatefulWidget {
  final List<Deck> decks;
  final Future<String> Function(Deck deck, String topic) onGenerate;

  const UpdateDeckAIDialog({
    super.key,
    required this.decks,
    required this.onGenerate,
  });

  @override
  State<UpdateDeckAIDialog> createState() => _UpdateDeckAIDialogState();
}

class _UpdateDeckAIDialogState extends State<UpdateDeckAIDialog> {
  final _formKey = GlobalKey<FormState>();
  Deck? _selectedDeck;
  final TextEditingController _topicController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.decks.isNotEmpty) {
      _selectedDeck = widget.decks.first;
    }
    _topicController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  void _submitUpdate() async {
    if (_formKey.currentState!.validate() && _selectedDeck != null) {
      setState(() {
        _isSubmitting = true;
      });

      final topic = _topicController.text.trim();

      try {
        final successMessage = await widget.onGenerate(_selectedDeck!, topic);
        if (mounted) {
          Navigator.of(context).pop(successMessage);
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.decks.isEmpty) {
      return SafeArea(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.layers_clear, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                "No Decks Available",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Please create a deck first before generating AI cards.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  "Close",
                  style: TextStyle(color: Color(0xFFE940A3)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          top: false, // Ensures background color reaches the absolute bottom
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE940A3).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.auto_awesome,
                                  color: Color(0xFFE940A3),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Flexible(
                                child: Text(
                                  "Update with AI",
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            if (!_isSubmitting) Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.close, color: Colors.grey),
                          tooltip: 'Close',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Select an existing deck and tell MindFlash what new flashcards you want to add to it.",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
        
                    const Text(
                      "SELECT DECK",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6B7280),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<Deck>(
                      value: _selectedDeck,
                      isExpanded: true, // Prevents overflow if deck name is incredibly long
                      items: widget.decks.map((deck) {
                        return DropdownMenuItem<Deck>(
                          value: deck,
                          child: Text(deck.name, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: _isSubmitting
                          ? null
                          : (Deck? newValue) {
                              setState(() {
                                _selectedDeck = newValue;
                              });
                            },
                      validator: (value) =>
                          value == null ? 'Please select a deck' : null,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF5F5F5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE940A3),
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.grey,
                      ),
                    ),
        
                    const SizedBox(height: 20),
        
                    const Text(
                      "WHAT SHOULD WE ADD?",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6B7280),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _topicController,
                      autofocus: true,
                      textInputAction: TextInputAction.send,
                      enabled: !_isSubmitting,
                      onFieldSubmitted: (_) => _submitUpdate(),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a topic to add';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: "e.g., More about widgets...",
                        hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                        filled: true,
                        fillColor: const Color(0xFFF5F5F5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE940A3),
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.red, width: 1),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.red, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        suffixIcon:
                            _topicController.text.isNotEmpty && !_isSubmitting
                            ? IconButton(
                                icon: const Icon(
                                  Icons.cancel,
                                  color: Colors.grey,
                                  size: 20,
                                ),
                                onPressed: () => _topicController.clear(),
                              )
                            : null,
                      ),
                      maxLines: 2,
                      minLines: 1,
                    ),
        
                    const SizedBox(height: 30),
        
                    Container(
                      width: double.infinity,
                      height: 55,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _isSubmitting
                              ? [Colors.grey.shade400, Colors.grey.shade400]
                              : [const Color(0xFFE940A3), const Color(0xFFFF5DAD)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: _isSubmitting
                            ? null
                            : [
                                BoxShadow(
                                  color: const Color(0xFFE940A3).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _isSubmitting ? null : _submitUpdate,
                          borderRadius: BorderRadius.circular(16),
                          child: Center(
                            child: _isSubmitting
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Flexible(
                                        child: Text(
                                          "Crafting cards...",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  )
                                : const Text(
                                    "Generate New Cards",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}