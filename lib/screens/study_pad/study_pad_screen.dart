import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

import '../../models/note_model.dart';
import '../../services/note_storage_service.dart';
import '../../services/digital_ink_service.dart';
import '../../services/ai_service.dart';
import '../../widgets/create_deck_ai_dialog.dart';
import 'study_pad_mobile.dart';
import 'study_pad_web.dart';
import 'widgets/drawing_overlay.dart';

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
  
  Timer? _debounceTimer;
  bool _isDrawingMode = false;
  String _saveStatus = "Saved";
  late String _noteId;

  // Drawing State
  List<DrawingStroke> _strokes = [];
  DrawingStroke? _currentStroke;
  final ValueNotifier<int> _drawingNotifier = ValueNotifier(0);
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
    _controller.document.changes.listen((_) => _triggerAutoSave());
    _titleController.addListener(_triggerAutoSave);
  }

  void _triggerAutoSave() {
    if (!mounted) return;
    setState(() => _saveStatus = "Saving...");
    
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), _saveNote);
  }

  Future<void> _saveNote() async {
    if (!mounted) return;
    try {
      final contentJson = jsonEncode(_controller.document.toDelta().toJson());
      final drawingJson = jsonEncode(_strokes.map((s) => s.toJson()).toList());
      final note = Note(
        id: _noteId,
        title: _titleController.text.trim().isEmpty ? "Untitled Note" : _titleController.text.trim(),
        content: contentJson,
        drawingData: drawingJson,
        updatedAt: DateTime.now(),
      );

      await _noteService.saveNote(note);
      if (mounted) setState(() => _saveStatus = "Saved");
    } catch (e) {
      if (mounted) setState(() => _saveStatus = "Error Saving");
    }
  }

  void _toggleDrawingMode() {
    HapticFeedback.lightImpact();
    setState(() {
      _isDrawingMode = !_isDrawingMode;
      _controller.readOnly = _isDrawingMode; // Lock/Unlock text editing directly via controller

      if (_isDrawingMode) {
        // FIX 2: Explicitly drop keyboard to maximize drawing canvas
        _focusNode.unfocus(); 
      }
    });
  }

  void _clearDrawing() {
    HapticFeedback.mediumImpact();
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

  // --- Drawing Handlers ---
  void _onStrokeStart(Offset localPosition) {
    _currentStroke = DrawingStroke(
      points: [localPosition],
      color: Theme.of(context).brightness == Brightness.dark ? Colors.yellowAccent : const Color(0xFF8B4EFF),
    );
    _strokes.add(_currentStroke!);
    _drawingNotifier.value++;
  }

  void _onStrokeUpdate(Offset localPosition) {
    _currentStroke?.points.add(localPosition);
    _drawingNotifier.value++;
  }

  void _onStrokeEnd() {
    _currentStroke = null;
    _triggerAutoSave();
  }

  @override
  void dispose() {
    // FIX 3: Prevent memory leaks and background crashes
    _debounceTimer?.cancel(); 
    _controller.dispose();
    _inkService.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _titleController.dispose();
    _drawingNotifier.dispose();
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
            saveStatus: _saveStatus,
            strokes: _strokes,
            drawingNotifier: _drawingNotifier,
            onToggleDrawing: _toggleDrawingMode,
            onClearDrawing: _clearDrawing,
            onStrokeStart: _onStrokeStart,
            onStrokeUpdate: _onStrokeUpdate,
            onStrokeEnd: _onStrokeEnd,
            isRecognizing: _isRecognizing,
            onRecognizeText: _recognizeHandwriting,
            onGenerateWithAI: _generateDeckWithAI,
            onBack: () => Navigator.pop(context),
          );
        } else {
          return StudyPadMobile(
            controller: _controller,
            focusNode: _focusNode,
            scrollController: _scrollController,
            titleController: _titleController,
            isDrawingMode: _isDrawingMode,
            saveStatus: _saveStatus,
            strokes: _strokes,
            drawingNotifier: _drawingNotifier,
            onToggleDrawing: _toggleDrawingMode,
            onClearDrawing: _clearDrawing,
            onStrokeStart: _onStrokeStart,
            onStrokeUpdate: _onStrokeUpdate,
            onStrokeEnd: _onStrokeEnd,
            isRecognizing: _isRecognizing,
            onRecognizeText: _recognizeHandwriting,
            onGenerateWithAI: _generateDeckWithAI,
            onBack: () => Navigator.pop(context),
          );
        }
      },
    );
  }
}