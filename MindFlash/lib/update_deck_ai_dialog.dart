import 'package:flutter/material.dart';
import 'deck_model.dart';

class UpdateDeckAIDialog extends StatefulWidget {
  final List<Deck> decks;
  final Function(Deck deck, String topic) onGenerate;

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

  @override
  void initState() {
    super.initState();
    if (widget.decks.isNotEmpty) {
      _selectedDeck = widget.decks.first;
    }
  }

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
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
                    Row(
                      children: const [
                        Icon(Icons.update, color: Color(0xFFE940A3), size: 28),
                        SizedBox(width: 8),
                        Text(
                          "Update with AI",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.grey),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  "Select an existing deck and tell MindFlash what new flashcards you want to add to it.",
                  style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.4),
                ),
                const SizedBox(height: 24),

                const Text(
                  "Select Deck",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<Deck>(
                  value: _selectedDeck,
                  items: widget.decks.map((deck) {
                    return DropdownMenuItem<Deck>(
                      value: deck,
                      child: Text(deck.name),
                    );
                  }).toList(),
                  onChanged: (Deck? newValue) {
                    setState(() {
                      _selectedDeck = newValue;
                    });
                  },
                  validator: (value) => value == null ? 'Please select a deck' : null,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                ),

                const SizedBox(height: 20),

                const Text(
                  "What should we add?",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _topicController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a topic to add';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: "e.g., More irregular verbs, Advanced math formulas...",
                    hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red, width: 1),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red, width: 1),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  maxLines: 2,
                  minLines: 1,
                ),

                const SizedBox(height: 30),

                Container(
                  width: double.infinity,
                  height: 55,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFE940A3),
                        Color(0xFFFF5DAD),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
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
                      onTap: _submitUpdate,
                      borderRadius: BorderRadius.circular(16),
                      child: const Center(
                        child: Text(
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
    );
  }

  void _submitUpdate() {
    if (_formKey.currentState!.validate() && _selectedDeck != null) {
      final topic = _topicController.text.trim();
      widget.onGenerate(_selectedDeck!, topic);
      Navigator.of(context).pop();
    }
  }
}