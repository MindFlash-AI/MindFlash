import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'widgets/drawing_overlay.dart';

class StudyPadWeb extends StatelessWidget {
  final quill.QuillController controller;
  final FocusNode focusNode;
  final ScrollController scrollController;
  final TextEditingController titleController;
  final bool isDrawingMode;
  final String saveStatus;
  
  final List<DrawingStroke> strokes;
  final ValueNotifier<int> drawingNotifier;
  final VoidCallback onToggleDrawing;
  final VoidCallback onClearDrawing;
  final Function(Offset) onStrokeStart;
  final Function(Offset) onStrokeUpdate;
  final VoidCallback onStrokeEnd;
  final bool isRecognizing;
  final VoidCallback onRecognizeText;
  final VoidCallback onGenerateWithAI;
  final VoidCallback onBack;

  const StudyPadWeb({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.scrollController,
    required this.titleController,
    required this.isDrawingMode,
    required this.saveStatus,
    required this.strokes,
    required this.drawingNotifier,
    required this.onToggleDrawing,
    required this.onClearDrawing,
    required this.onStrokeStart,
    required this.onStrokeUpdate,
    required this.onStrokeEnd,
    required this.isRecognizing,
    required this.onRecognizeText,
    required this.onGenerateWithAI,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: Theme.of(context).textTheme.bodyLarge?.color),
          onPressed: onBack,
        ),
        title: TextField(
          controller: titleController,
          decoration: const InputDecoration(border: InputBorder.none, hintText: "Note Title..."),
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        actions: [
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: saveStatus == "Saved" ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                saveStatus,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: saveStatus == "Saved" ? Colors.green : Colors.orange),
              ),
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            icon: isRecognizing 
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.auto_awesome, size: 18),
            label: const Text("Generate AI Deck", style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B4EFF),
              foregroundColor: Colors.white,
            ),
            onPressed: isRecognizing ? null : onGenerateWithAI,
          ),
          const SizedBox(width: 24),
        ],
      ),
      body: Column(
        children: [
          // Desktop Toolbar
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: Theme.of(context).cardColor,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 850),
                child: quill.QuillSimpleToolbar(
                  controller: controller,
                  config: const quill.QuillSimpleToolbarConfig(),
                ),
              ),
            ),
          ),
          Divider(height: 1, color: isDark ? Colors.white12 : Colors.black12),

          // Main Editor Constrainted for Ergonomic Reading
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 850),
                child: Stack(
                  children: [
                    IgnorePointer(
                      ignoring: isDrawingMode,
                      child: quill.QuillEditor.basic(
                        controller: controller,
                        config: quill.QuillEditorConfig(
                          padding: const EdgeInsets.all(40),
                          autoFocus: true,
                          expands: true,
                        ),
                        focusNode: focusNode,
                        scrollController: scrollController,
                      ),
                    ),
                    
                    if (isDrawingMode)
                      AnimatedBuilder(
                        animation: scrollController,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, -scrollController.offset),
                            child: child,
                          );
                        },
                        child: GestureDetector(
                          onPanStart: (details) => onStrokeStart(details.localPosition),
                          onPanUpdate: (details) => onStrokeUpdate(details.localPosition),
                          onPanEnd: (_) => onStrokeEnd(),
                          child: Container(
                            color: Colors.transparent,
                            width: double.infinity,
                            height: 8000, 
                            child: AnimatedBuilder(
                              animation: drawingNotifier,
                              builder: (context, _) {
                                return CustomPaint(
                                  painter: DrawingPainter(strokes: strokes),
                                  size: Size.infinite,
                                );
                              }
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (isDrawingMode) ...[
            FloatingActionButton.extended(
              heroTag: "recognize_btn_web",
              backgroundColor: Colors.blueAccent,
              onPressed: isRecognizing ? null : onRecognizeText,
              icon: isRecognizing 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.text_fields_rounded, color: Colors.white),
              label: Text(isRecognizing ? "Recognizing..." : "Convert to Text", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            FloatingActionButton.extended(
              heroTag: "clear_btn_web",
              backgroundColor: Colors.redAccent,
              onPressed: onClearDrawing,
              icon: const Icon(Icons.delete_sweep_rounded, color: Colors.white),
              label: const Text("Clear Drawings", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
          ],
          FloatingActionButton.extended(
            heroTag: "draw_btn_web",
            backgroundColor: isDrawingMode ? const Color(0xFF8B4EFF) : Theme.of(context).cardColor,
            onPressed: onToggleDrawing,
            icon: Icon(
              isDrawingMode ? Icons.edit_off_rounded : Icons.brush_rounded,
              color: isDrawingMode ? Colors.white : const Color(0xFF8B4EFF),
            ),
            label: Text(
              isDrawingMode ? "Exit Drawing Mode" : "Draw over Text",
              style: TextStyle(color: isDrawingMode ? Colors.white : const Color(0xFF8B4EFF), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}