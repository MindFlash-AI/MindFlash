import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'widgets/drawing_overlay.dart';
import '../../widgets/universal_sidebar.dart';

class StudyPadWeb extends StatelessWidget {
  final quill.QuillController controller;
  final FocusNode focusNode;
  final ScrollController scrollController;
  final TextEditingController titleController;
  final bool isDrawingMode;
  final bool isSidebarVisible;
  final VoidCallback onToggleSidebar;
  final VoidCallback onDashboardTap;
  final VoidCallback onWebsiteTap;
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
  final VoidCallback onBack;
  final VoidCallback? onDeleteNote;

  const StudyPadWeb({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.scrollController,
    required this.titleController,
    required this.isDrawingMode,
    required this.isSidebarVisible,
    required this.onToggleSidebar,
    required this.onDashboardTap,
    required this.onWebsiteTap,
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
    required this.onBack,
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

    final mainContent = Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leadingWidth: isSidebarVisible ? 56 : 100, 
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isSidebarVisible)
              IconButton(
                icon: Icon(Icons.menu_rounded, color: Theme.of(context).textTheme.bodyLarge?.color),
                onPressed: onToggleSidebar,
                tooltip: "Open Sidebar",
              ),
            IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: Theme.of(context).textTheme.bodyLarge?.color),
              onPressed: onBack,
              tooltip: "Back",
            ),
          ],
        ),
        title: TextField(
          controller: titleController,
          decoration: const InputDecoration(border: InputBorder.none, hintText: "Note Title..."),
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        actions: [
          Center(
            child: ValueListenableBuilder<String>(
              valueListenable: saveNotifier,
              builder: (context, status, _) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: status == "Saved" ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: status == "Saved" ? Colors.green : Colors.orange),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 16),
          if (onDeleteNote != null) ...[
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              onPressed: onDeleteNote,
              tooltip: "Move to Trash",
            ),
            const SizedBox(width: 8),
          ],
          TextButton.icon(
            icon: const Icon(Icons.folder_copy_rounded, size: 18),
            label: const Text("My Notes", style: TextStyle(fontWeight: FontWeight.bold)),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF8B4EFF)),
            onPressed: onOpenNotes,
          ),
          const SizedBox(width: 12),
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
                child: isDrawingMode
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(icon: Icon(Icons.undo_rounded, color: canUndo ? (isDark ? Colors.white : Colors.black) : Colors.grey), onPressed: canUndo ? onUndo : null, tooltip: "Undo"),
                              IconButton(icon: Icon(Icons.redo_rounded, color: canRedo ? (isDark ? Colors.white : Colors.black) : Colors.grey), onPressed: canRedo ? onRedo : null, tooltip: "Redo"),
                              Container(width: 1, height: 24, color: Colors.grey.withValues(alpha: 0.3), margin: const EdgeInsets.symmetric(horizontal: 12)),
                              
                              // 🛡️ HCI: Desktop Grouped Tool Selectors
                              GestureDetector(
                                onTap: () {
                                  if (isEraserMode) onToggleEraser();
                                  else if (isHighlighterMode) onToggleHighlighter();
                                },
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(color: (!isEraserMode && !isHighlighterMode) ? selectedColor.withValues(alpha: 0.15) : Colors.transparent, borderRadius: BorderRadius.circular(8)),
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit_rounded, size: 18, color: (!isEraserMode && !isHighlighterMode) ? selectedColor : Colors.grey),
                                        const SizedBox(width: 6),
                                        Text("Pen", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: (!isEraserMode && !isHighlighterMode) ? selectedColor : Colors.grey)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () { if (!isHighlighterMode) onToggleHighlighter(); },
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(color: isHighlighterMode ? Colors.amber.withValues(alpha: 0.15) : Colors.transparent, borderRadius: BorderRadius.circular(8)),
                                    child: Row(
                                      children: [
                                        Icon(Icons.border_color_rounded, size: 18, color: isHighlighterMode ? Colors.amber : Colors.grey),
                                        const SizedBox(width: 6),
                                        Text("Highlight", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isHighlighterMode ? Colors.amber : Colors.grey)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () { if (!isEraserMode) onToggleEraser(); },
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(color: isEraserMode ? const Color(0xFFE841A1).withValues(alpha: 0.15) : Colors.transparent, borderRadius: BorderRadius.circular(8)),
                                    child: Row(
                                      children: [
                                        Icon(Icons.backspace_rounded, size: 18, color: isEraserMode ? const Color(0xFFE841A1) : Colors.grey),
                                        const SizedBox(width: 6),
                                        Text("Erase", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isEraserMode ? const Color(0xFFE841A1) : Colors.grey)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
  
                              // 🛡️ HCI: Hide irrelevant controls
                              if (!isEraserMode) ...[
                                Container(width: 1, height: 24, color: Colors.grey.withValues(alpha: 0.3), margin: const EdgeInsets.symmetric(horizontal: 16)),
                                ..._drawingColors.map((color) => GestureDetector(
                                  onTap: () => onColorSelected(color),
                                  child: MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 6),
                                      width: 28, height: 28,
                                      decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: selectedColor == color ? (isDark ? Colors.white : Colors.black) : Colors.grey.withValues(alpha: 0.5), width: selectedColor == color ? 3 : 1)),
                                    ),
                                  ),
                                )),
                                const SizedBox(width: 12),
                                Container(width: 1, height: 24, color: Colors.grey.withValues(alpha: 0.3)),
                                const SizedBox(width: 16),
                                Icon(Icons.line_weight_rounded, size: 20, color: isDark ? Colors.white54 : Colors.black54),
                                SizedBox(width: 120, child: Slider(value: selectedWidth, min: 1.0, max: 20.0, activeColor: selectedColor, inactiveColor: selectedColor.withValues(alpha: 0.3), onChanged: onWidthSelected)),
                              ],
  
                              // 🛡️ HCI: Add actions to desktop toolbar instead of floating buttons
                              Container(width: 1, height: 24, color: Colors.grey.withValues(alpha: 0.3), margin: const EdgeInsets.symmetric(horizontal: 16)),
                              TextButton.icon(icon: isRecognizing ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.text_fields_rounded), label: Text(isRecognizing ? "Recognizing..." : "To Text", style: const TextStyle(fontWeight: FontWeight.bold)), style: TextButton.styleFrom(foregroundColor: Colors.blueAccent), onPressed: isRecognizing ? null : onRecognizeText),
                              const SizedBox(width: 8),
                              TextButton.icon(icon: const Icon(Icons.delete_sweep_rounded), label: const Text("Clear", style: TextStyle(fontWeight: FontWeight.bold)), style: TextButton.styleFrom(foregroundColor: Colors.redAccent), onPressed: onClearDrawing),
                            ],
                          ),
                        ),
                      )
                    : quill.QuillSimpleToolbar(
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
                    // 1. Drawing Layer
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
                              cursor: SystemMouseCursors.none,
                              onHover: (e) => onHoverUpdate(e.localPosition),
                              onExit: (_) => onHoverExit(),
                              child: GestureDetector(
                                onPanStart: (details) => onStrokeStart(details.localPosition),
                                onPanUpdate: (details) => onStrokeUpdate(details.localPosition),
                                onPanEnd: (_) => onStrokeEnd(),
                                child: Container(
                                  color: Colors.transparent,
                                  width: double.infinity,
                                  height: 8000, 
                                  child: Stack(
                                    children: [
                                      AnimatedBuilder(
                                        animation: drawingNotifier,
                                        builder: (context, _) => RepaintBoundary(
                                          child: CustomPaint(painter: DrawingPainter(strokes: strokes), size: Size.infinite),
                                        )
                                      ),
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
                              height: 8000, 
                              child: AnimatedBuilder(
                                animation: drawingNotifier,
                                builder: (context, _) => RepaintBoundary(
                                  child: CustomPaint(painter: DrawingPainter(strokes: strokes), size: Size.infinite),
                                )
                              ),
                            ),
                    ),

                    // 2. Editor
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

    return Scaffold(
      body: Row(
        children: [
          // 🚀 Smoothly sliding sidebar using AnimatedContainer and OverflowBox protection
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            width: isSidebarVisible ? 280 : 0,
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.topLeft,
                maxWidth: 280,
                minWidth: 280,
                child: UniversalSidebar(
                  activeItem: SidebarActiveItem.studyPad,
                  showMinimizeButton: true,
                  onMinimizeTap: onToggleSidebar,
                  onDashboardTap: onDashboardTap,
                  onWebsiteTap: onWebsiteTap,
                ),
              ),
            ),
          ),
          Expanded(child: mainContent),
        ],
      ),
    );
  }
}