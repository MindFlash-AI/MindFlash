import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'card_model.dart';

class CreateCardDialog extends StatefulWidget {
  final String deckId;
  final Function(Flashcard) onCardCreated;

  const CreateCardDialog({
    super.key, 
    required this.deckId, 
    required this.onCardCreated
  });

  @override
  State<CreateCardDialog> createState() => _CreateCardDialogState();
}

class _CreateCardDialogState extends State<CreateCardDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _answerController = TextEditingController();

  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  void _createCard() {
    if (_formKey.currentState!.validate()) {
      final newCard = Flashcard(
        id: const Uuid().v4(),
        deckId: widget.deckId,
        question: _questionController.text.trim(),
        answer: _answerController.text.trim(),
      );

      widget.onCardCreated(newCard);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Add New Card",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.grey),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                _buildInputLabel("Question (Front)"),
                const SizedBox(height: 8),
                _buildTextFormField(
                  controller: _questionController,
                  hint: "e.g., Enter the question or term...",
                  validator: (value) => 
                    value == null || value.trim().isEmpty ? 'Question is required' : null,
                ),

                const SizedBox(height: 20),

                _buildInputLabel("Answer (Back)"),
                const SizedBox(height: 8),
                _buildTextFormField(
                  controller: _answerController,
                  hint: "e.g., Enter the answer or definition...",
                  maxLines: 3,
                  validator: (value) => 
                    value == null || value.trim().isEmpty ? 'Answer is required' : null,
                ),

                const SizedBox(height: 30),

                Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF5B4FE6), Color(0xFF9E55E6)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF5B4FE6).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _createCard,
                      borderRadius: BorderRadius.circular(12),
                      child: const Center(
                        child: Text(
                          "Save Card",
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

  Widget _buildInputLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}