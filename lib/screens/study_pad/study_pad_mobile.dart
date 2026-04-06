import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import '../../services/pro_service.dart';
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
  final ValueNotifier<Offset?> hoverNotifier;
  final Function(Offset) onHoverUpdate;
  final VoidCallback onHoverExit;
  final Color selectedColor;
  final Function(Color) onColorSelected;
  final double selectedWidth;
  final Function(double) onWidthSelected;
  final bool canUndo;
  final bool canRedo;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onToggleDrawing;
  final bool isEraserMode;
  final VoidCallback onToggleEraser;
  final bool isHighlighterMode;
  final VoidCallback onToggleHighlighter;
  final VoidCallback onClearDrawing;
  final Function(Offset) onStrokeStart;
  final Function(Offset) onStrokeUpdate;
  final VoidCallback onStrokeEnd;
  final bool isRecognizing;
  final VoidCallback onRecognizeText;
  final VoidCallback onGenerateWithAI;
  final VoidCallback onOpenNotes;
  final VoidCallback onExportNote;
  final VoidCallback onBack;
  final BannerAd? bannerAd;
  final bool isBannerAdLoaded;
  final VoidCallback? onDeleteNote;

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
    required this.hoverNotifier,
    required this.onHoverUpdate,
    required this.onHoverExit,
    required this.selectedColor,
    required this.onColorSelected,
    required this.selectedWidth,
    required this.onWidthSelected,
    required this.canUndo,
    required this.canRedo,
    required this.onUndo,
    required this.onRedo,
    required this.onToggleDrawing,
    required this.isEraserMode,
    required this.onToggleEraser,
    required this.isHighlighterMode,
    required this.onToggleHighlighter,
    required this.onClearDrawing,
    required this.onStrokeStart,
    required this.onStrokeUpdate,
    required this.onStrokeEnd,
    required this.isRecognizing,
    required this.onRecognizeText,
    required this.onGenerateWithAI,
    required this.onOpenNotes,
    required this.onExportNote,
    required this.onBack,
    required this.bannerAd,
    required this.isBannerAdLoaded,
    this.onDeleteNote,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Color> _drawingColors = const [
      Color(0xFF8B4EFF), // Brand Purple
      Colors.redAccent,
      Colors.blueAccent,
      Colors.green,
      Colors.orange,
      Colors.black,
      Colors.white,
    ];

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
      if (onDeleteNote != null)
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
          onPressed: onDeleteNote,
          tooltip: "Move to Trash",
        ),
          IconButton(
            icon: const Icon(Icons.folder_copy_rounded, color: Color(0xFF8B4EFF)),
            onPressed: onOpenNotes,
            tooltip: "My Notes",
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent),
            onPressed: onExportNote,
            tooltip: "Export to PDF",
          ),
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
          // Toolbar (Swaps to Color Picker in Drawing Mode)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: isDrawingMode
                ? SizedBox(
                    key: const ValueKey('drawing_toolbar'),
                    height: 54,
                    width: double.infinity,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.undo_rounded, color: canUndo ? (isDark ? Colors.white : Colors.black) : Colors.grey),
                            onPressed: canUndo ? onUndo : null,
                            tooltip: "Undo",
                          ),
                          IconButton(
                            icon: Icon(Icons.redo_rounded, color: canRedo ? (isDark ? Colors.white : Colors.black) : Colors.grey),
                            onPressed: canRedo ? onRedo : null,
                            tooltip: "Redo",
                          ),
                          Container(width: 1, height: 24, color: Colors.grey.withValues(alpha: 0.3), margin: const EdgeInsets.symmetric(horizontal: 8)),
                          
                          // 🛡️ HCI: Grouped Tool Selectors with clear visual active states
                          GestureDetector(
                            onTap: () {
                              if (isEraserMode) onToggleEraser();
                              else if (isHighlighterMode) onToggleHighlighter();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: (!isEraserMode && !isHighlighterMode) ? selectedColor.withValues(alpha: 0.15) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.edit_rounded, size: 18, color: (!isEraserMode && !isHighlighterMode) ? selectedColor : Colors.grey),
                                  const SizedBox(width: 4),
                                  Text("Pen", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: (!isEraserMode && !isHighlighterMode) ? selectedColor : Colors.grey)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () { if (!isHighlighterMode) onToggleHighlighter(); },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isHighlighterMode ? Colors.amber.withValues(alpha: 0.15) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.border_color_rounded, size: 18, color: isHighlighterMode ? Colors.amber : Colors.grey),
                                  const SizedBox(width: 4),
                                  Text("Highlight", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isHighlighterMode ? Colors.amber : Colors.grey)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () { if (!isEraserMode) onToggleEraser(); },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isEraserMode ? const Color(0xFFE841A1).withValues(alpha: 0.15) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.backspace_rounded, size: 18, color: isEraserMode ? const Color(0xFFE841A1) : Colors.grey),
                                  const SizedBox(width: 4),
                                  Text("Erase", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isEraserMode ? const Color(0xFFE841A1) : Colors.grey)),
                                ],
                              ),
                            ),
                          ),

                          // 🛡️ HCI: Hide Color & Width sliders when erasing to prevent cognitive overload
                          if (!isEraserMode) ...[
                            Container(width: 1, height: 24, color: Colors.grey.withValues(alpha: 0.3), margin: const EdgeInsets.symmetric(horizontal: 12)),
                            ..._drawingColors.map((color) => GestureDetector(
                              onTap: () => onColorSelected(color),
                              child: Container(
                                margin: const EdgeInsets.only(right: 12),
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: selectedColor == color ? (isDark ? Colors.white : Colors.black) : Colors.grey.withValues(alpha: 0.5),
                                    width: selectedColor == color ? 3 : 1,
                                  ),
                                ),
                              ),
                            )),
                            Container(width: 1, height: 24, color: Colors.grey.withValues(alpha: 0.3), margin: const EdgeInsets.symmetric(horizontal: 8)),
                            Icon(Icons.line_weight_rounded, size: 20, color: isDark ? Colors.white54 : Colors.black54),
                            SizedBox(width: 100, child: Slider(value: selectedWidth, min: 1.0, max: 20.0, activeColor: selectedColor, inactiveColor: selectedColor.withValues(alpha: 0.3), onChanged: onWidthSelected)),
                          ],
                        ],
                      ),
                    ),
                  )
                : Container(
                    key: const ValueKey('text_toolbar'),
                    width: double.infinity,
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
          ),
          Divider(height: 1, color: isDark ? Colors.white12 : Colors.black12),

          // Main Editor + Drawing Stack
          Expanded(
            child: Stack(
              children: [
                // 1. Drawing Layer (Synchronized to Scroll) - Placed UNDER the text editor!
                AnimatedBuilder(
                  animation: scrollController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, scrollController.hasClients ? -scrollController.offset : 0.0),
                      child: child,
                    );
                  },
                  child: isDrawingMode 
                      ? MouseRegion(
                          cursor: SystemMouseCursors.none, // Hide default cursor so our custom brush circle stands out
                          onHover: (e) => onHoverUpdate(e.localPosition),
                          onExit: (_) => onHoverExit(),
                          child: GestureDetector(
                            onPanStart: (details) => onStrokeStart(details.localPosition),
                            onPanUpdate: (details) => onStrokeUpdate(details.localPosition),
                            onPanEnd: (_) => onStrokeEnd(),
                            child: Container(
                              color: Colors.transparent, // Capture gestures
                              width: double.infinity,
                              height: 5000, 
                              child: Stack(
                                children: [
                                  // Layer 1: Cache-bound strokes
                                  AnimatedBuilder(
                                    animation: drawingNotifier,
                                    builder: (context, _) => RepaintBoundary(
                                      child: CustomPaint(painter: DrawingPainter(strokes: strokes), size: Size.infinite),
                                    )
                                  ),
                                  // Layer 2: Fast-updating Hover Cursor (does not trigger redrawing previous strokes)
                                  AnimatedBuilder(
                                    animation: hoverNotifier,
                                    builder: (context, _) => CustomPaint(
                                      painter: HoverCursorPainter(
                                        hoverPosition: hoverNotifier.value, width: selectedWidth, color: selectedColor, isEraser: isEraserMode, isHighlighter: isHighlighterMode,
                                      ),
                                      size: Size.infinite,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : Container(
                          color: Colors.transparent,
                          width: double.infinity,
                          height: 5000, 
                          child: AnimatedBuilder(
                            animation: drawingNotifier,
                            builder: (context, _) => RepaintBoundary(
                              child: CustomPaint(painter: DrawingPainter(strokes: strokes), size: Size.infinite),
                            )
                          ),
                        ),
                ),

                // 2. Text Editor Layer
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
              ],
            ),
          ),
          
          // 🛡️ HCI: The banner ad strictly anchored below the canvas and locked to a 50px height
          if (!kIsWeb && !ProService().isPro)
            SafeArea(
              top: false,
              child: SizedBox(
                height: 50,
                width: double.infinity,
                child: (isBannerAdLoaded && bannerAd != null)
                    ? AdWidget(ad: bannerAd!)
                    : const SizedBox.shrink(),
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