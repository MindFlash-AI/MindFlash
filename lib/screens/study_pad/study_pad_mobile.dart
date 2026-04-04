import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'widgets/drawing_overlay.dart';

class StudyPadMobile extends StatelessWidget {
  final quill.QuillController controller;
  final FocusNode focusNode;
  final ScrollController scrollController;
  final TextEditingController titleController;
  final bool isDrawingMode;
  final ValueNotifier<String> saveNotifier;
  
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

  const StudyPadMobile({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.scrollController,
    required this.titleController,
    required this.isDrawingMode,
    required this.saveNotifier,
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
          icon: Icon(Icons.arrow_back_ios_new, color: Theme.of(context).textTheme.bodyLarge?.color),
          onPressed: onBack,
        ),
        title: TextField(
          controller: titleController,
          decoration: const InputDecoration(border: InputBorder.none, hintText: "Title..."),
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        actions: [
          Center(
            child: ValueListenableBuilder<String>(
              valueListenable: saveNotifier,
              builder: (context, status, _) {
                return Text(
                  status,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: status == "Saved" ? Colors.green : Colors.orange),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: isRecognizing 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF8B4EFF)))
                : const Icon(Icons.auto_awesome, color: Color(0xFF8B4EFF)),
            onPressed: isRecognizing ? null : onGenerateWithAI,
            tooltip: "Generate AI Deck",
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Toolbar (Hidden if drawing to save space)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: isDrawingMode ? 0 : null,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: quill.QuillSimpleToolbar(
                controller: controller,
                config: const quill.QuillSimpleToolbarConfig(
                  showAlignmentButtons: false,
                  showIndent: false,
                ),
              ),
            ),
          ),
          Divider(height: 1, color: isDark ? Colors.white12 : Colors.black12),

          // Main Editor + Drawing Stack
          Expanded(
            child: Stack(
              children: [
                // 1. Text Editor Layer
                IgnorePointer(
                  ignoring: isDrawingMode, // Prevent text cursor from hijacking drawing touches
                  child: quill.QuillEditor.basic(
                    controller: controller,
                    config: quill.QuillEditorConfig(
                      padding: const EdgeInsets.all(24),
                      autoFocus: false,
                      expands: true,
                    ),
                    focusNode: focusNode,
                    scrollController: scrollController,
                  ),
                ),

                // 2. Drawing Layer (Synchronized to Scroll)
                if (isDrawingMode)
                  AnimatedBuilder(
                    animation: scrollController,
                    builder: (context, child) {
                      // Anchor the drawing coordinates to the scroll offset
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
                        color: Colors.transparent, // Capture gestures
                        width: double.infinity,
                        // Make the canvas massive to allow drawing far down the document
                        height: 5000, 
                        child: AnimatedBuilder(
                          animation: drawingNotifier,
                          builder: (context, _) {
                            return RepaintBoundary(
                              child: CustomPaint(
                                painter: DrawingPainter(strokes: strokes),
                                size: Size.infinite,
                              ),
                            );
                          }
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      // Floating Actions for Drawing
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (isDrawingMode) ...[
            FloatingActionButton(
              heroTag: "recognize_btn",
              mini: true,
              backgroundColor: Colors.blueAccent,
              onPressed: isRecognizing ? null : onRecognizeText,
              child: isRecognizing 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.text_fields_rounded, color: Colors.white),
            ),
            const SizedBox(height: 12),
            FloatingActionButton(
              heroTag: "clear_btn",
              mini: true,
              backgroundColor: Colors.redAccent,
              onPressed: onClearDrawing,
              child: const Icon(Icons.delete_sweep_rounded, color: Colors.white),
            ),
            const SizedBox(height: 12),
          ],
          FloatingActionButton(
            heroTag: "draw_btn",
            backgroundColor: isDrawingMode ? const Color(0xFF8B4EFF) : Theme.of(context).cardColor,
            onPressed: onToggleDrawing,
            child: Icon(
              isDrawingMode ? Icons.edit_off_rounded : Icons.brush_rounded,
              color: isDrawingMode ? Colors.white : const Color(0xFF8B4EFF),
            ),
          ),
        ],
      ),
    );
  }
}