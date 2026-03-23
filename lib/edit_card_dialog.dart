import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'card_model.dart';

class EditCardDialog extends StatefulWidget {
  final Flashcard card;
  final Function(Flashcard) onCardUpdated;

  const EditCardDialog({
    super.key,
    required this.card,
    required this.onCardUpdated,
  });

  @override
  State<EditCardDialog> createState() => _EditCardDialogState();
}

class _EditCardDialogState extends State<EditCardDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _questionController;
  late TextEditingController _answerController;

  final FocusNode _questionFocus = FocusNode();
  final FocusNode _answerFocus = FocusNode();

  final LinearGradient _brandGradient = const LinearGradient(
    colors: [Color(0xFF8B4EFF), Color(0xFFE841A1)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  @override
  void initState() {
    super.initState();
    _questionController = TextEditingController(text: widget.card.question)
      ..selection = TextSelection.fromPosition(
        TextPosition(offset: widget.card.question.length),
      );

    _answerController = TextEditingController(text: widget.card.answer)
      ..selection = TextSelection.fromPosition(
        TextPosition(offset: widget.card.answer.length),
      );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _questionFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
    _questionFocus.dispose();
    _answerFocus.dispose();
    super.dispose();
  }

  bool get _hasUnsavedChanges {
    return _questionController.text.trim() != widget.card.question ||
        _answerController.text.trim() != widget.card.answer;
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    _questionFocus.unfocus();
    _answerFocus.unfocus();

    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Discard Changes?",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "You have unsaved edits. Are you sure you want to discard them?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              "Keep Editing",
              style: TextStyle(color: Colors.grey),
            ),
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
              "Discard",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    return shouldDiscard ?? false;
  }

  void _updateCard() {
    if (_formKey.currentState!.validate()) {
      HapticFeedback.lightImpact();

      final updatedCard = Flashcard(
        id: widget.card.id,
        deckId: widget.card.deckId,
        question: _questionController.text.trim(),
        answer: _answerController.text.trim(),
      );

      widget.onCardUpdated(updatedCard);
      Navigator.of(context).pop();
    } else {
      HapticFeedback.heavyImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        elevation: 24,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
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
                        "Edit Card",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                          letterSpacing: -0.5,
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          HapticFeedback.selectionClick();
                          final shouldPop = await _onWillPop();
                          if (shouldPop && context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                        icon: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.black54,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  _buildInputLabel(
                    "Question (Front)",
                    Icons.help_outline_rounded,
                  ),
                  const SizedBox(height: 10),
                  _buildTextFormField(
                    controller: _questionController,
                    focusNode: _questionFocus,
                    hint: "e.g., Enter the question or term...",
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) =>
                        FocusScope.of(context).requestFocus(_answerFocus),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Question is required'
                        : null,
                  ),

                  const SizedBox(height: 24),

                  _buildInputLabel("Answer (Back)", Icons.edit_note_rounded),
                  const SizedBox(height: 10),
                  _buildTextFormField(
                    controller: _answerController,
                    focusNode: _answerFocus,
                    hint: "e.g., Enter the answer or definition...",
                    maxLines: 4,
                    textInputAction: TextInputAction.done,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Answer is required'
                        : null,
                  ),

                  const SizedBox(height: 36),

                  Container(
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: _brandGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B4EFF).withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _updateCard,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        "Save Changes",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
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
    );
  }

  Widget _buildInputLabel(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF8B4EFF)),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    int maxLines = 1,
    TextInputAction? textInputAction,
    Function(String)? onFieldSubmitted,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      validator: validator,
      maxLines: maxLines,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      style: const TextStyle(fontSize: 16, color: Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.grey.shade400,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF8B4EFF), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.red.shade300, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
      ),
    );
  }
}
