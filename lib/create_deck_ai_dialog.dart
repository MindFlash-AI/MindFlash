import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CreateDeckAIDialog extends StatefulWidget {
  // Changed to return a Future
  final Future<void> Function(String topic) onGenerate;

  const CreateDeckAIDialog({super.key, required this.onGenerate});

  @override
  State<CreateDeckAIDialog> createState() => _CreateDeckAIDialogState();
}

class _CreateDeckAIDialogState extends State<CreateDeckAIDialog> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _deckNameController = TextEditingController();
  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _promptController = TextEditingController();

  final FocusNode _nameFocus = FocusNode();
  final FocusNode _topicFocus = FocusNode();
  final FocusNode _promptFocus = FocusNode();

  double _numCards = 10;
  bool _isSubmitting = false;

  final LinearGradient _brandGradient = const LinearGradient(
    colors: [Color(0xFF8B4EFF), Color(0xFFE841A1)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nameFocus.requestFocus();
    });

    _deckNameController.addListener(() => setState(() {}));
    _topicController.addListener(() => setState(() {}));
    _promptController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _deckNameController.dispose();
    _topicController.dispose();
    _promptController.dispose();
    _nameFocus.dispose();
    _topicFocus.dispose();
    _promptFocus.dispose();
    super.dispose();
  }

  void _submitTopic() async {
    if (_formKey.currentState!.validate()) {
      HapticFeedback.lightImpact();

      final deckName = _deckNameController.text.trim();
      final topic = _topicController.text.trim();
      final prompt = _promptController.text.trim();
      final numCards = _numCards.toInt();

      String engineeredPrompt =
          "Create a flashcard deck named '$deckName'. "
          "Topic: $topic. "
          "Generate exactly $numCards cards.";

      if (prompt.isNotEmpty) {
        engineeredPrompt += " Additional instructions: $prompt.";
      }

      setState(() {
        _isSubmitting = true;
      });

      try {
        await widget.onGenerate(engineeredPrompt);
        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        // If it fails, stop loading so they can edit and try again
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    } else {
      HapticFeedback.heavyImpact();
    }
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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B4EFF).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.auto_awesome_rounded,
                              color: Color(0xFF8B4EFF),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            "AI Generation",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.black87,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () {
                          if (!_isSubmitting) {
                            HapticFeedback.selectionClick();
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
                  const SizedBox(height: 12),
                  Text(
                    "Let MindFlash build a complete flashcard deck for you in seconds. Just tell us what you want to learn.",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),

                  _buildInputLabel("Deck Name", Icons.style_rounded),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _deckNameController,
                    focusNode: _nameFocus,
                    enabled: !_isSubmitting,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) =>
                        FocusScope.of(context).requestFocus(_topicFocus),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a deck name';
                      }
                      return null;
                    },
                    decoration: _buildInputDecoration(
                      "e.g., CMSC 156",
                      _deckNameController,
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildInputLabel("Topic", Icons.bookmark_border_rounded),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _topicController,
                    focusNode: _topicFocus,
                    enabled: !_isSubmitting,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) =>
                        FocusScope.of(context).requestFocus(_promptFocus),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a topic';
                      }
                      return null;
                    },
                    decoration: _buildInputDecoration(
                      "e.g., Core Flutter Skills, Firebase Integration...",
                      _topicController,
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildInputLabel(
                    "Specific Instructions (Optional)",
                    Icons.tune_rounded,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _promptController,
                    focusNode: _promptFocus,
                    enabled: !_isSubmitting,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submitTopic(),
                    decoration: _buildInputDecoration(
                      "e.g., Focus on API integration, make it about code organization ...",
                      _promptController,
                    ),
                    maxLines: 2,
                    minLines: 1,
                  ),
                  const SizedBox(height: 28),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInputLabel("Number of Cards", Icons.layers_rounded),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B4EFF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "${_numCards.toInt()} Cards",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF8B4EFF),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 6.0,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 12.0,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 24.0,
                      ),
                      activeTickMarkColor: Colors.transparent,
                      inactiveTickMarkColor: Colors.transparent,
                    ),
                    child: Slider(
                      value: _numCards,
                      min: 5,
                      max: 50,
                      divisions: 9,
                      activeColor: const Color(0xFF8B4EFF),
                      inactiveColor: const Color(0xFF8B4EFF).withOpacity(0.2),
                      onChanged: _isSubmitting ? null : (value) {
                        if (value != _numCards) {
                          HapticFeedback.selectionClick();
                        }
                        setState(() {
                          _numCards = value;
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 32),

                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: _isSubmitting 
                        ? LinearGradient(colors: [Colors.grey.shade400, Colors.grey.shade400])
                        : _brandGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: _isSubmitting ? null : [
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
                        onTap: _isSubmitting ? null : _submitTopic,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: _isSubmitting
                              ? const [
                                  SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    "Generating...",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ]
                              : const [
                                  Icon(
                                    Icons.auto_awesome_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "Start Generating",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
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

  InputDecoration _buildInputDecoration(
    String hint,
    TextEditingController controller,
  ) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
      filled: true,
      fillColor: const Color(0xFFF8F9FA),
      suffixIcon: controller.text.isNotEmpty && !_isSubmitting
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    );
  }
}