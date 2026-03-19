import 'package:flutter/material.dart';

class CreateDeckAIDialog extends StatefulWidget {
  final Function(String topic) onGenerate;

  const CreateDeckAIDialog({super.key, required this.onGenerate});

  @override
  State<CreateDeckAIDialog> createState() => _CreateDeckAIDialogState();
}

class _CreateDeckAIDialogState extends State<CreateDeckAIDialog> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for our text fields
  final TextEditingController _deckNameController = TextEditingController();
  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _promptController = TextEditingController();

  // State for the slider
  double _numCards = 10;

  @override
  void dispose() {
    _deckNameController.dispose();
    _topicController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Handles the keyboard sliding up nicely
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 32.0,
            ),
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
                          Icon(
                            Icons.auto_awesome,
                            color: Color(0xFF9E55E6),
                            size: 28,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Generate with AI",
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
                    "Let MindFlash build a complete flashcard deck for you in seconds. Just tell us what you want to learn.",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- DECK NAME ---
                  const Text(
                    "Deck Name",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _deckNameController,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a deck name';
                      }
                      return null;
                    },
                    decoration: _buildInputDecoration("e.g., Biology 101"),
                  ),
                  const SizedBox(height: 16),

                  // --- TOPIC ---
                  const Text(
                    "Topic",
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
                        return 'Please enter a topic';
                      }
                      return null;
                    },
                    decoration: _buildInputDecoration(
                      "e.g., The Solar System, Basic French...",
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- PROMPT / INSTRUCTIONS (Optional) ---
                  const Text(
                    "Specific Instructions (Optional)",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _promptController,
                    decoration: _buildInputDecoration(
                      "e.g., Focus on dates, make it multiple choice...",
                    ),
                    maxLines: 2,
                    minLines: 1,
                  ),
                  const SizedBox(height: 16),

                  // --- NUMBER OF CARDS (Max 50) ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Number of Cards",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        "${_numCards.toInt()} Cards",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5B4FE6),
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _numCards,
                    min: 1,
                    max: 50, // Updated to 50 maximum
                    divisions: 49, // Allows stepping exactly by 1
                    activeColor: const Color(0xFF5B4FE6),
                    inactiveColor: const Color(0xFF5B4FE6).withOpacity(0.2),
                    onChanged: (value) {
                      setState(() {
                        _numCards = value;
                      });
                    },
                  ),

                  const SizedBox(height: 30),

                  // --- AI GENERATE BUTTON ---
                  Container(
                    width: double.infinity,
                    height: 55,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2C1A8A), Color(0xFF5B4FE6)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2C1A8A).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _submitTopic,
                        borderRadius: BorderRadius.circular(16),
                        child: const Center(
                          child: Text(
                            "Start Generating",
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
    );
  }

  // Helper method to keep text fields clean and consistent
  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
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
    );
  }

  void _submitTopic() {
    if (_formKey.currentState!.validate()) {
      final deckName = _deckNameController.text.trim();
      final topic = _topicController.text.trim();
      final prompt = _promptController.text.trim();
      final numCards = _numCards.toInt();

      // Combine all inputs into one highly specific prompt for the AI
      String engineeredPrompt =
          "Create a flashcard deck named '$deckName'. "
          "Topic: $topic. "
          "Generate exactly $numCards cards.";

      // Append optional instructions if the user provided any
      if (prompt.isNotEmpty) {
        engineeredPrompt += " Additional instructions: $prompt.";
      }

      widget.onGenerate(engineeredPrompt);
      Navigator.of(context).pop();
    }
  }
}
