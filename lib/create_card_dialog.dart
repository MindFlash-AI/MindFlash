import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import 'card_model.dart';

class CreateCardDialog extends StatefulWidget {
  final String deckId;
  final Function(Flashcard) onCardCreated;

  const CreateCardDialog({
    super.key,
    required this.deckId,
    required this.onCardCreated,
  });

  @override
  State<CreateCardDialog> createState() => _CreateCardDialogState();
}

class _CreateCardDialogState extends State<CreateCardDialog> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _answerController = TextEditingController();

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _questionFocus.requestFocus();
    });

    _questionController.addListener(() => setState(() {}));
    _answerController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
    _questionFocus.dispose();
    _answerFocus.dispose();
    super.dispose();
  }

  void _createCard() {
    if (_formKey.currentState!.validate()) {
      HapticFeedback.lightImpact();

      final newCard = Flashcard(
        id: const Uuid().v4(),
        deckId: widget.deckId,
        question: _questionController.text.trim(),
        answer: _answerController.text.trim(),
      );

      widget.onCardCreated(newCard);
      Navigator.of(context).pop();
    } else {
      HapticFeedback.heavyImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 32.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
      
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Add New Card",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.black87,
                            letterSpacing: -0.5,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            Navigator.of(context).pop();
                          },
                          icon: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.black54,
                              size: 20,
                            ),
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
      
                    _buildInputLabel(
                      "Question (Front)",
                      Icons.flip_to_front_rounded,
                    ),
                    const SizedBox(height: 8),
                    _buildTextFormField(
                      controller: _questionController,
                      focusNode: _questionFocus,
                      hint: "e.g., It is everything visible on the screen",
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) =>
                          FocusScope.of(context).requestFocus(_answerFocus),
                      validator: (value) => value == null || value.trim().isEmpty
                          ? 'Question is required'
                          : null,
                    ),
      
                    const SizedBox(height: 20),
      
                    _buildInputLabel("Answer (Back)", Icons.flip_to_back_rounded),
                    const SizedBox(height: 8),
                    _buildTextFormField(
                      controller: _answerController,
                      focusNode: _answerFocus,
                      hint: "e.g., Widgets",
                      maxLines: 4,
                      minLines: 2,
                      textInputAction: TextInputAction.newline,
                      validator: (value) => value == null || value.trim().isEmpty
                          ? 'Answer is required'
                          : null,
                    ),
      
                    const SizedBox(height: 32),
      
                    Container(
                      width: double.infinity,
                      height: 56,
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
                      child: Material(
                        color: Colors.transparent,
                        clipBehavior: Clip.antiAlias,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          onTap: _createCard,
                          child: const Center(
                            child: Text(
                              "Save Card",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
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
    int? maxLines = 1,
    int? minLines = 1,
    TextInputAction? textInputAction,
    Function(String)? onFieldSubmitted,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      validator: validator,
      maxLines: maxLines,
      minLines: minLines,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      textCapitalization: TextCapitalization.sentences,
      style: const TextStyle(fontSize: 16, color: Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        suffixIcon: controller.text.isNotEmpty && maxLines == 1
            ? IconButton(
                icon: const Icon(Icons.cancel, color: Colors.grey, size: 20),
                onPressed: () {
                  controller.clear();
                  HapticFeedback.selectionClick();
                },
              )
            : null,
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