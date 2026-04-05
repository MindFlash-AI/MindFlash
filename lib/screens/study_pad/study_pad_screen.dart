import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

import '../../models/note_model.dart';
import '../../services/note_storage_service.dart';
import '../../services/digital_ink_service.dart';
import '../../services/ai_service.dart';
import '../../widgets/create_deck_ai_dialog.dart';
import 'study_pad_mobile.dart';
import 'study_pad_web.dart';
import 'widgets/drawing_overlay.dart';
import '../dashboard/dashboard_screen.dart';
import '../web_landing/web_landing_screen.dart';
import 'widgets/saved_notes_sheet.dart';

class StudyPadScreen extends StatefulWidget {
  final Note? initialNote;
  const StudyPadScreen({super.key, this.initialNote});

  @override
  State<StudyPadScreen> createState() => _StudyPadScreenState();
}

class _StudyPadScreenState extends State<StudyPadScreen> {
  late quill.QuillController _controller;
  final FocusNode _focusNode = FocusNode();
  
  // FIX 1: Shared Scroll Controller to synchronize Text and Drawing layers
  final ScrollController _scrollController = ScrollController(); 
  final TextEditingController _titleController = TextEditingController();
  final NoteStorageService _noteService = NoteStorageService();
  
  StreamSubscription? _docChangeSubscription;
  Timer? _debounceTimer;
  bool _isDrawingMode = false;
  bool _isSidebarVisible = true; // 🛡️ Sidebar minimization state
  bool _isEraserMode = false;
  bool _isHighlighterMode = false;
  final ValueNotifier<String> _saveNotifier = ValueNotifier("Saved");
  Color _selectedColor = const Color(0xFF8B4EFF);
  double _selectedWidth = 4.0;
  late String _noteId;

  // Drawing State
  List<DrawingStroke> _strokes = [];
  DrawingStroke? _currentStroke;
  final ValueNotifier<int> _drawingNotifier = ValueNotifier(0);
  final ValueNotifier<Offset?> _hoverNotifier = ValueNotifier(null);
  List<List<DrawingStroke>> _undoHistory = [];
  List<List<DrawingStroke>> _redoHistory = [];
  final DigitalInkService _inkService = DigitalInkService();
  bool _isRecognizing = false;

  @override
  void initState() {
    super.initState();
    _noteId = widget.initialNote?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    _titleController.text = widget.initialNote?.title ?? "Untitled Note";

    // Safely load Quill Document
    if (widget.initialNote != null && widget.initialNote!.content.isNotEmpty) {
      try {
        final doc = quill.Document.fromJson(jsonDecode(widget.initialNote!.content));
        _controller = quill.QuillController(document: doc, selection: const TextSelection.collapsed(offset: 0));
      } catch (e) {
        _controller = quill.QuillController.basic();
      }
    } else {
      _controller = quill.QuillController.basic();
    }
    
    // Safely load Drawings
    if (widget.initialNote != null && widget.initialNote!.drawingData.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(widget.initialNote!.drawingData);
        _strokes = decoded.map((s) => DrawingStroke.fromJson(Map<String, dynamic>.from(s))).toList();
      } catch (e) {
        _strokes = [];
      }
    }

    // Attach Debounced Auto-Save Listeners
    _docChangeSubscription = _controller.document.changes.listen((_) => _triggerAutoSave());
    _titleController.addListener(_triggerAutoSave);
  }

  void _triggerAutoSave() {
    if (!mounted) return;
    _saveNotifier.value = "Saving...";
    
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), _saveNote);
  }

  Future<void> _saveNote() async {
    if (!mounted) return;
    try {
      // 🚀 PERFORMANCE FIX: Offload expensive JSON serialization to a background isolate
      // This prevents the UI thread from freezing (jank) when auto-saving massive notes
      final deltaList = _controller.document.toDelta().toJson();
      final strokeList = _strokes.map((s) => s.toJson()).toList();
      final contentJson = await compute(jsonEncode, deltaList);
      final drawingJson = await compute(jsonEncode, strokeList);

      final note = Note(
        id: _noteId,
        title: _titleController.text.trim().isEmpty ? "Untitled Note" : _titleController.text.trim(),
        content: contentJson,
        drawingData: drawingJson,
        updatedAt: DateTime.now(),
      );

      await _noteService.saveNote(note);
      if (mounted) _saveNotifier.value = "Saved";
    } catch (e) {
      if (mounted) _saveNotifier.value = "Error Saving";
    }
  }

  void _toggleDrawingMode() {
    HapticFeedback.lightImpact();
    setState(() {
      _isDrawingMode = !_isDrawingMode;
      _controller.readOnly = _isDrawingMode; // Lock/Unlock text editing directly via controller
      if (!_isDrawingMode) {
        _isEraserMode = false; // Turn off tools if drawing mode closed
        _isHighlighterMode = false;
      }

      if (_isDrawingMode) {
        // FIX 2: Explicitly drop keyboard to maximize drawing canvas
        _focusNode.unfocus(); 
      }
    });
  }

  void _toggleSidebar() {
    HapticFeedback.lightImpact();
    setState(() => _isSidebarVisible = !_isSidebarVisible);
  }

  void _navigateToDashboard() {
    Navigator.pushAndRemoveUntil(
      context, MaterialPageRoute(builder: (context) => const DashboardScreen()), (route) => false,
    );
  }

  void _navigateToWebsite() {
    Navigator.pushAndRemoveUntil(
      context, MaterialPageRoute(builder: (context) => const WebLandingScreen()), (route) => false,
    );
  }

  void _openSavedNotes() async {
    HapticFeedback.lightImpact();
    _triggerAutoSave(); // Ensure current progress is saved before switching
    
    final selectedNote = await showModalBottomSheet<Note>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SavedNotesSheet(),
    );

    if (selectedNote != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => StudyPadScreen(initialNote: selectedNote)),
      );
    }
  }

  void _toggleEraserMode() {
    HapticFeedback.lightImpact();
    setState(() {
      _isEraserMode = !_isEraserMode;
      if (_isEraserMode) _isHighlighterMode = false;
    });
  }

  void _toggleHighlighterMode() {
    HapticFeedback.lightImpact();
    setState(() {
      _isHighlighterMode = !_isHighlighterMode;
      if (_isHighlighterMode) _isEraserMode = false;
    });
  }

  void _clearDrawing() {
    if (_strokes.isEmpty) return; // Prevent useless undo states
    HapticFeedback.mediumImpact();
    _saveUndoState();
    setState(() {
      _strokes.clear();
      _currentStroke = null;
    });
    _drawingNotifier.value++;
    _triggerAutoSave();
  }

  Future<void> _recognizeHandwriting() async {
    if (_strokes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Draw something first!')));
      return;
    }

    setState(() => _isRecognizing = true);
    
    try {
      final text = await _inkService.recognizeText(
        _strokes,
        onDownloading: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Downloading handwriting recognition model (first time only)...')),
          );
        },
      );
      
      if (text.isNotEmpty) {
        // Append the recognized text to the end of the document
        final index = _controller.document.length - 1;
        _controller.document.insert(index, '\n$text\n');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Handwriting converted!')));
          _clearDrawing(); // Clean canvas once converted
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No text could be recognized. Try writing clearer.')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString().replaceAll('Exception:', '').trim()}')));
    } finally {
      if (mounted) setState(() => _isRecognizing = false);
    }
  }

  // --- Seamless Background AI Generation ---
  Future<void> _generateDeckWithAI() async {
    if (_controller.document.toPlainText().trim().isEmpty && _strokes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Write or draw something first!')));
      return;
    }

    setState(() => _isRecognizing = true);
    
    try {
      // 1. Extract Typed Text
      String documentText = _controller.document.toPlainText().trim();

      // 2. Silently Background Convert Handwritten Strokes
      String handwrittenText = "";
      if (_strokes.isNotEmpty) {
        handwrittenText = await _inkService.recognizeText(
          _strokes,
          onDownloading: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Downloading ML model... Please wait.')),
          ),
        );
      }

      // 3. Combine Typed and Handwritten Text together
      String combinedText = documentText;
      if (handwrittenText.isNotEmpty) {
        combinedText += "\n\n--- Handwritten Notes ---\n$handwrittenText";
      }

      if (!mounted) return;
      setState(() => _isRecognizing = false);

      // 4. Open AI Dialog and Pipeline the Combined Text directly to Gemini
      final successMessage = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (modalContext) => CreateDeckAIDialog(
          onGenerate: (topic, dialogFileText, dialogFileName) async {
            String finalCombinedText = combinedText;
            if (dialogFileText != null && dialogFileText.isNotEmpty) {
                finalCombinedText += "\n\n--- Attached Document ---\n$dialogFileText";
            }
            
            final aiService = AIService();
            final response = await aiService.processInput(
              text: topic,
              fileText: finalCombinedText,
              fileName: _titleController.text.trim().isEmpty ? "Study Pad Notes" : _titleController.text.trim(),
            );
            return response.message;
          },
        ),
      );

      if (successMessage != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(successMessage), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRecognizing = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString().replaceAll('Exception:', '').trim()}')));
      }
    }
  }

  // --- Undo & Redo Mechanisms ---
  void _saveUndoState() {
    _undoHistory.add(List.from(_strokes));
    _redoHistory.clear();
  }

  void _undo() {
    if (_undoHistory.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() {
      _redoHistory.add(List.from(_strokes));
      _strokes = _undoHistory.removeLast();
    });
    _drawingNotifier.value++;
    _triggerAutoSave();
  }

  void _redo() {
    if (_redoHistory.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() {
      _undoHistory.add(List.from(_strokes));
      _strokes = _redoHistory.removeLast();
    });
    _drawingNotifier.value++;
    _triggerAutoSave();
  }

  void _eraseAt(Offset position) {
    final double eraserRadius = 25.0; // The radius size of the eraser
    final double eraserRadiusSq = eraserRadius * eraserRadius;
    bool removed = false;
    
    _strokes.removeWhere((stroke) {
      for (final point in stroke.points) {
        // 🚀 PERFORMANCE FIX: Quick bounding box check, and avoid expensive square root math using distanceSquared
        if ((point.dx - position.dx).abs() <= eraserRadius && 
            (point.dy - position.dy).abs() <= eraserRadius) {
          if ((point - position).distanceSquared <= eraserRadiusSq) {
            removed = true;
            return true; // 🗑️ Object Eraser: Delete the entire continuous stroke
          }
        }
      }
      return false;
    });

    if (removed) {
      _drawingNotifier.value++;
    }
  }

  void _onHoverUpdate(Offset position) {
    _hoverNotifier.value = position;
  }

  void _onHoverExit() {
    _hoverNotifier.value = null;
  }

  // --- Drawing Handlers ---
  void _onStrokeStart(Offset localPosition) {
    _saveUndoState(); // Save snapshot before we mutate the canvas
    _hoverNotifier.value = localPosition;
    if (_isEraserMode) {
      _eraseAt(localPosition);
      return;
    }
    _currentStroke = DrawingStroke(
      points: [localPosition],
      color: _selectedColor,
      width: _isHighlighterMode ? _selectedWidth * 2.5 : _selectedWidth, // Make highlight broader automatically
      isHighlighter: _isHighlighterMode,
    );
    _strokes.add(_currentStroke!);
    _drawingNotifier.value++;
  }

  void _onStrokeUpdate(Offset localPosition) {
    _hoverNotifier.value = localPosition;
    if (_isEraserMode) {
      _eraseAt(localPosition);
      return;
    }
    _currentStroke?.points.add(localPosition);
    _drawingNotifier.value++;
  }

  void _onStrokeEnd() {
    if (_isEraserMode) {
      // Check if they dragged the eraser but didn't actually hit anything
      if (_undoHistory.isNotEmpty && _undoHistory.last.length == _strokes.length) {
        _undoHistory.removeLast(); // Discard the useless undo state
      } else {
        setState(() {}); // Update the Undo/Redo button states visually
      }
      _triggerAutoSave();
      return;
    }
    _currentStroke = null;
    setState(() {}); // Update the Undo/Redo button states visually
    _triggerAutoSave();
  }

  @override
  void dispose() {
    // FIX 3: Prevent memory leaks and background crashes
    _docChangeSubscription?.cancel();
    _titleController.removeListener(_triggerAutoSave);
    _debounceTimer?.cancel(); 
    _controller.dispose();
    _inkService.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _titleController.dispose();
    _drawingNotifier.dispose();
    _hoverNotifier.dispose();
    _saveNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 850;
        
        if (isDesktop) {
          return StudyPadWeb(
            controller: _controller,
            focusNode: _focusNode,
            scrollController: _scrollController,
            titleController: _titleController,
            isDrawingMode: _isDrawingMode,
            isSidebarVisible: _isSidebarVisible,
            onToggleSidebar: _toggleSidebar,
            onDashboardTap: _navigateToDashboard,
            onWebsiteTap: _navigateToWebsite,
            saveNotifier: _saveNotifier,
            strokes: _strokes,
            drawingNotifier: _drawingNotifier,
            hoverNotifier: _hoverNotifier,
            onHoverUpdate: _onHoverUpdate,
            onHoverExit: _onHoverExit,
            onToggleDrawing: _toggleDrawingMode,
            isEraserMode: _isEraserMode,
            onToggleEraser: _toggleEraserMode,
            isHighlighterMode: _isHighlighterMode,
            onToggleHighlighter: _toggleHighlighterMode,
            onClearDrawing: _clearDrawing,
            onStrokeStart: _onStrokeStart,
            onStrokeUpdate: _onStrokeUpdate,
            onStrokeEnd: _onStrokeEnd,
            isRecognizing: _isRecognizing,
            onRecognizeText: _recognizeHandwriting,
            onGenerateWithAI: _generateDeckWithAI,
            onOpenNotes: _openSavedNotes,
            selectedColor: _selectedColor,
            onColorSelected: (color) => setState(() => _selectedColor = color),
            selectedWidth: _selectedWidth,
            onWidthSelected: (width) => setState(() => _selectedWidth = width),
            canUndo: _undoHistory.isNotEmpty,
            canRedo: _redoHistory.isNotEmpty,
            onUndo: _undo,
            onRedo: _redo,
            onBack: () => Navigator.pop(context),
          );
        } else {
          return StudyPadMobile(
            controller: _controller,
            focusNode: _focusNode,
            scrollController: _scrollController,
            titleController: _titleController,
            isDrawingMode: _isDrawingMode,
            saveNotifier: _saveNotifier,
            strokes: _strokes,
            drawingNotifier: _drawingNotifier,
            hoverNotifier: _hoverNotifier,
            onHoverUpdate: _onHoverUpdate,
            onHoverExit: _onHoverExit,
            onToggleDrawing: _toggleDrawingMode,
            isEraserMode: _isEraserMode,
            onToggleEraser: _toggleEraserMode,
            isHighlighterMode: _isHighlighterMode,
            onToggleHighlighter: _toggleHighlighterMode,
            onClearDrawing: _clearDrawing,
            onStrokeStart: _onStrokeStart,
            onStrokeUpdate: _onStrokeUpdate,
            onStrokeEnd: _onStrokeEnd,
            isRecognizing: _isRecognizing,
            onRecognizeText: _recognizeHandwriting,
            onGenerateWithAI: _generateDeckWithAI,
            onOpenNotes: _openSavedNotes,
            selectedColor: _selectedColor,
            onColorSelected: (color) => setState(() => _selectedColor = color),
            selectedWidth: _selectedWidth,
            onWidthSelected: (width) => setState(() => _selectedWidth = width),
            canUndo: _undoHistory.isNotEmpty,
            canRedo: _redoHistory.isNotEmpty,
            onUndo: _undo,
            onRedo: _redo,
            onBack: () => Navigator.pop(context),
          );
        }
      },
    );
  }
}