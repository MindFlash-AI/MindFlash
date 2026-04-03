import 'dart:convert';
import 'dart:async'; 
import 'package:flutter/foundation.dart' show kIsWeb; 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_quill/flutter_quill.dart'; 

import '../../constants.dart';
import '../../widgets/create_deck_ai_dialog.dart';
import '../../services/ai_service.dart';
import '../../services/ad_helper.dart'; 
import '../../services/note_storage_service.dart'; 
import '../../models/note_model.dart';
import 'widgets/saved_notes_sheet.dart';

import 'study_pad_web.dart';
import 'study_pad_mobile.dart';

enum SaveStatus { saved, saving, unsaved }

class StudyPadScreen extends StatefulWidget {
  final Function() onDeckCreated;

  const StudyPadScreen({super.key, required this.onDeckCreated});

  @override
  State<StudyPadScreen> createState() => _StudyPadScreenState();
}

class _StudyPadScreenState extends State<StudyPadScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _titleController = TextEditingController();
  QuillController _quillController = QuillController.basic();
  final FocusNode _contentFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController(); 
  
  final NoteStorageService _noteStorage = NoteStorageService();
  String? _currentNoteId; 
  
  Timer? _debounceTimer;
  StreamSubscription? _docSubscription;
  bool _hasUnsavedChanges = false;
  bool _ignoreChanges = false; 
  SaveStatus _saveStatus = SaveStatus.saved;

  int _wordCount = 0;
  bool _isReadOnly = false;

  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
    _setupListeners();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && !_isReadOnly) _contentFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _docSubscription?.cancel();
    _titleController.dispose();
    _quillController.dispose();
    _contentFocusNode.dispose();
    _scrollController.dispose(); 
    _bannerAd?.dispose();
    super.dispose();
  }

  void _loadBannerAd() {
    if (kIsWeb) return;
    _bannerAd = BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(onAdLoaded: (ad) => setState(() => _isAdLoaded = true)),
    )..load();
  }

  void _setupListeners() {
    _titleController.addListener(_onContentChanged);
    _docSubscription?.cancel();
    _docSubscription = _quillController.document.changes.listen((_) => _onContentChanged());
  }

  void _onContentChanged() {
    if (_ignoreChanges || _isReadOnly) return;
    final text = _quillController.document.toPlainText().trim();
    if (mounted) {
      setState(() {
        _wordCount = text.isEmpty ? 0 : text.split(RegExp(r'\s+')).length;
        _hasUnsavedChanges = true;
        _saveStatus = SaveStatus.unsaved;
      });
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), () {
      if (_hasUnsavedChanges) _saveNote(isAutoSave: true);
    });
  }

  Future<void> _saveNote({bool isAutoSave = false}) async {
    if (_ignoreChanges || _isReadOnly) return;
    final plainText = _quillController.document.toPlainText().trim();
    String title = _titleController.text.trim();
    if (plainText.isEmpty && title.isEmpty) return;

    if (title.isEmpty) title = "Untitled Note";

    setState(() => _saveStatus = SaveStatus.saving);
    _currentNoteId ??= DateTime.now().millisecondsSinceEpoch.toString();
    
    final note = Note(
      id: _currentNoteId!,
      title: title,
      content: jsonEncode(_quillController.document.toDelta().toJson()),
      updatedAt: DateTime.now(),
    );

    await _noteStorage.saveNote(note);
    if (mounted) {
      setState(() {
        _hasUnsavedChanges = false;
        _saveStatus = SaveStatus.saved;
      });
    }
  }

  void _openSavedNotes() async {
    if (kIsWeb) {
      _scaffoldKey.currentState?.openEndDrawer();
    } else {
      final selectedNote = await showModalBottomSheet<Note>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const SavedNotesSheet(),
      );
      if (selectedNote != null) _loadNote(selectedNote);
    }
  }

  void _loadNote(Note note) {
    _ignoreChanges = true;
    setState(() {
      _currentNoteId = note.id;
      _titleController.text = note.title == "Untitled Note" ? "" : note.title;
      _isReadOnly = true;
      try {
        _quillController = QuillController(document: Document.fromJson(jsonDecode(note.content)), selection: const TextSelection.collapsed(offset: 0));
      } catch (_) {
        _quillController = QuillController(document: Document()..insert(0, note.content), selection: const TextSelection.collapsed(offset: 0));
      }
    });
    _setupListeners();
    _ignoreChanges = false;
  }

  void _startNewNote() {
    setState(() {
      _quillController = QuillController.basic();
      _titleController.clear();
      _currentNoteId = null;
      _isReadOnly = false;
    });
    _setupListeners();
  }

  Future<void> _handleGenerate() async {
    if (!_isReadOnly) await _saveNote();
    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateDeckAIDialog(
        onGenerate: (topic, _, __) => AIService().processInput(
          text: topic,
          fileText: _quillController.document.toPlainText(),
          fileName: _titleController.text,
        ).then((res) => res.message),
      ),
    ).then((success) {
      if (success != null) {
        widget.onDeckCreated();
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(builder: (context, constraints) {
      final isDesktop = constraints.maxWidth >= 900;

      final saveStatusWidget = AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Text(
          _saveStatus == SaveStatus.saving ? "Saving..." : _saveStatus == SaveStatus.saved ? "Saved ☁️" : "Unsaved",
          key: ValueKey(_saveStatus),
          style: TextStyle(color: _saveStatus == SaveStatus.saved ? Colors.green : Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      );

      final wordCountWidget = Text("$_wordCount words", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey));

      if (isDesktop) {
        return StudyPadWeb(
          scaffoldKey: _scaffoldKey,
          titleController: _titleController,
          quillController: _quillController,
          scrollController: _scrollController,
          contentFocusNode: _contentFocusNode,
          saveStatusWidget: saveStatusWidget,
          wordCountWidget: wordCountWidget,
          savedNotesSidebar: SavedNotesSheet(onNoteSelected: (note) {
            _loadNote(note);
            Navigator.pop(context);
          }),
          onNewNote: _startNewNote,
          onSave: _saveNote,
          onOpenNotes: _openSavedNotes,
          onGenerate: _handleGenerate,
          isReadOnly: _isReadOnly,
        );
      } else {
        return StudyPadMobile(
          titleController: _titleController,
          quillController: _quillController,
          scrollController: _scrollController,
          contentFocusNode: _contentFocusNode,
          saveStatusWidget: saveStatusWidget,
          wordCountWidget: wordCountWidget,
          onNewNote: _startNewNote,
          onOpenNotes: _openSavedNotes,
          onGenerate: _handleGenerate,
          isReadOnly: _isReadOnly,
          adWidget: _isAdLoaded ? AdWidget(ad: _bannerAd!) : null,
        );
      }
    });
  }
}