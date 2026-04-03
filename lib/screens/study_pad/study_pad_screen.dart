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

enum SaveStatus { saved, saving, unsaved }

class StudyPadScreen extends StatefulWidget {
  final Function() onDeckCreated;

  const StudyPadScreen({super.key, required this.onDeckCreated});

  @override
  State<StudyPadScreen> createState() => _StudyPadScreenState();
}

class _StudyPadScreenState extends State<StudyPadScreen> {
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
  int _charCount = 0;

  // 🛡️ UX: Read-Only Mode State
  bool _isReadOnly = false;

  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  int get _minCards => _wordCount == 0 ? 0 : (_wordCount / 30).ceil().clamp(1, 999);
  int get _maxCards => _wordCount == 0 ? 0 : (_wordCount / 15).ceil().clamp(1, 999);

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
    _titleController.removeListener(_onContentChanged);
    _titleController.dispose();
    _quillController.dispose();
    _contentFocusNode.dispose();
    _scrollController.dispose(); 
    _bannerAd?.dispose();
    super.dispose();
  }

  void _loadBannerAd() {
    final adUnitId = AdHelper.bannerAdUnitId;
    if (adUnitId.isEmpty) return;

    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => setState(() => _isAdLoaded = true),
        onAdFailedToLoad: (ad, error) {
          debugPrint('BannerAd failed to load: $error');
          ad.dispose();
        },
      ),
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
        _charCount = text.replaceAll('\n', '').length;
        _wordCount = text.isEmpty ? 0 : text.split(RegExp(r'\s+')).length;
      });
    }

    if (!_hasUnsavedChanges && mounted) {
      setState(() {
        _hasUnsavedChanges = true;
        _saveStatus = SaveStatus.unsaved;
      });
    }

    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), () {
      if (_hasUnsavedChanges) {
        _saveNote(isAutoSave: true);
      }
    });
  }

  Future<void> _saveNote({bool isAutoSave = false}) async {
    if (_ignoreChanges || _isReadOnly) return;
    final plainText = _quillController.document.toPlainText().trim();
    String title = _titleController.text.trim();
    
    if (plainText.isEmpty && title.isEmpty) return;

    if (title.isEmpty && plainText.isNotEmpty) {
      title = plainText.split(RegExp(r'\s+')).take(4).join(' ');
      title = title.replaceAll(RegExp(r'[^\w\s]+$'), ''); 
      if (title.isEmpty) title = "Untitled Note";
      
      _ignoreChanges = true;
      _titleController.text = title;
      _ignoreChanges = false;
    } else if (title.isEmpty) {
      title = "Untitled Note";
    }

    setState(() => _saveStatus = SaveStatus.saving);
    
    _currentNoteId ??= DateTime.now().millisecondsSinceEpoch.toString();
    
    final noteContent = jsonEncode(_quillController.document.toDelta().toJson());
    
    final note = Note(
      id: _currentNoteId!,
      title: title,
      content: noteContent,
      updatedAt: DateTime.now(),
    );

    await _noteStorage.saveNote(note);
    
    if (mounted) {
      setState(() {
        _hasUnsavedChanges = false;
        _saveStatus = SaveStatus.saved;
      });
      
      if (!isAutoSave) {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Note saved successfully!"),
            backgroundColor: const Color(0xFF00C853),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<bool?> _showDiscardDialog() {
    HapticFeedback.mediumImpact();
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Unsaved Changes", style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold)),
        content: Text("You have unsaved changes. Are you sure you want to discard them?", style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), 
            child: const Text("Keep Editing", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true), 
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, elevation: 0),
            child: const Text("Discard", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _openSavedNotes() async {
    _contentFocusNode.unfocus();
    
    final selectedNote = await showModalBottomSheet<Note>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SavedNotesSheet(),
    );

    if (selectedNote != null) {
      _ignoreChanges = true;
      setState(() {
        _currentNoteId = selectedNote.id;
        _titleController.text = selectedNote.title == "Untitled Note" ? "" : selectedNote.title;
        
        try {
          final List<dynamic> decoded = jsonDecode(selectedNote.content);
          _quillController = QuillController(
            document: Document.fromJson(decoded),
            selection: const TextSelection.collapsed(offset: 0),
          );
        } catch (e) {
          final doc = Document()..insert(0, selectedNote.content);
          _quillController = QuillController(
            document: doc,
            selection: const TextSelection.collapsed(offset: 0),
          );
        }
        
        // 🛡️ UX: Lock into Read-Only Mode upon opening an old note
        _isReadOnly = true;
        _contentFocusNode.canRequestFocus = false; 
        _contentFocusNode.unfocus();
        
        _hasUnsavedChanges = false;
        _saveStatus = SaveStatus.saved;
        
        final loadedText = _quillController.document.toPlainText().trim();
        _charCount = loadedText.replaceAll('\n', '').length;
        _wordCount = loadedText.isEmpty ? 0 : loadedText.split(RegExp(r'\s+')).length;
      });
      _setupListeners(); 
      _ignoreChanges = false;
    }
  }

  void _startNewNote() async {
    if (_hasUnsavedChanges) {
      final bool shouldDiscard = await _showDiscardDialog() ?? false;
      if (!shouldDiscard) return; 
    }

    HapticFeedback.lightImpact();
    _ignoreChanges = true;
    setState(() {
      _quillController = QuillController.basic(); 
      _titleController.clear();
      _currentNoteId = null; 
      _hasUnsavedChanges = false;
      _saveStatus = SaveStatus.saved;
      _wordCount = 0;
      _charCount = 0;
      
      // 🛡️ UX: Ensure we are not in Read-Only Mode for a new note
      _isReadOnly = false;
      _contentFocusNode.canRequestFocus = true;
    });
    _setupListeners();
    _ignoreChanges = false;
    
    FocusScope.of(context).requestFocus(_contentFocusNode); 
  }

  // 🛡️ UX: Smooth unlock transition
  void _unlockNoteForEditing() {
    HapticFeedback.lightImpact();
    setState(() {
      _isReadOnly = false;
      _contentFocusNode.canRequestFocus = true;
    });
    // Gently focus the editor after a short delay to allow the toolbar to animate in
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) FocusScope.of(context).requestFocus(_contentFocusNode);
    });
  }

  void _handleGenerate() {
    if (_quillController.document.toPlainText().trim().isEmpty) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please write some notes first!"),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    // Only save if we aren't in read-only mode
    if (!_isReadOnly) _saveNote(); 
    HapticFeedback.lightImpact();
    _contentFocusNode.unfocus();

    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => CreateDeckAIDialog(
        onGenerate: (topic, _, __) => _processNotesToDeck(modalContext, topic),
      ),
    ).then((successMessage) {
      if (successMessage != null && mounted) {
        widget.onDeckCreated(); 
        Navigator.pop(context); 
      }
    });
  }

  Future<String> _processNotesToDeck(BuildContext context, String topic) async {
    try {
      final aiService = AIService();
      final response = await aiService.processInput(
        text: topic,
        fileText: _quillController.document.toPlainText().trim(), 
        fileName: _titleController.text.trim().isEmpty ? "StudyPad Notes" : _titleController.text.trim(),
      );
      return response.message;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isWeb = kIsWeb;
    const double maxContentWidth = 900; 

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final bool shouldPop = await _showDiscardDialog() ?? false;
        if (shouldPop) {
          _hasUnsavedChanges = false; 
          if (mounted) Navigator.pop(context);
        }
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            centerTitle: false,
            iconTheme: IconThemeData(color: Theme.of(context).textTheme.bodyLarge?.color),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.edit_note_rounded, color: Color(0xFF8B4EFF)),
                const SizedBox(width: 8),
                Text(
                  "Study Pad",
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            actions: [
              // 🛡️ UX: Smartly swap between the "Edit" button and the "Save" indicator
              if (_isReadOnly)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilledButton.icon(
                    onPressed: _unlockNoteForEditing,
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    label: const Text("Edit Note", style: TextStyle(fontWeight: FontWeight.bold)),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF8B4EFF).withOpacity(0.15),
                      foregroundColor: const Color(0xFF8B4EFF),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                )
              else ...[
                Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      _saveStatus == SaveStatus.saving
                          ? "Saving..."
                          : _saveStatus == SaveStatus.saved
                              ? "Saved ☁️"
                              : "Unsaved",
                      key: ValueKey(_saveStatus),
                      style: TextStyle(
                        color: _saveStatus == SaveStatus.saved
                            ? const Color(0xFF00C853)
                            : isDark
                                ? Colors.white54
                                : Colors.black54,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _startNewNote,
                  tooltip: "New Note",
                  icon: Icon(Icons.add_rounded, color: Theme.of(context).textTheme.bodyLarge?.color, size: 26),
                ),
                IconButton(
                  onPressed: _saveStatus == SaveStatus.saving ? null : () => _saveNote(isAutoSave: false),
                  tooltip: "Save Note",
                  icon: _saveStatus == SaveStatus.saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF8B4EFF)))
                      : const Icon(Icons.save_rounded, color: Color(0xFF8B4EFF)),
                ),
              ],
              IconButton(
                onPressed: _openSavedNotes,
                tooltip: "Open Saved Notes",
                icon: Icon(Icons.folder_open_rounded, color: Theme.of(context).textTheme.bodyLarge?.color),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: maxContentWidth),
              child: Column(
                children: [
                  if (_isAdLoaded && _bannerAd != null && !isWeb)
                    Container(
                      width: _bannerAd!.size.width.toDouble(),
                      height: _bannerAd!.size.height.toDouble(),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: AdWidget(ad: _bannerAd!),
                    ),

                  Expanded(
                    child: Container(
                      width: double.infinity,
                      margin: isWeb ? const EdgeInsets.fromLTRB(24, 12, 24, 24) : EdgeInsets.zero,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF151023) : const Color(0xFFFDFBFF),
                        borderRadius: isWeb 
                            ? BorderRadius.circular(24) 
                            : const BorderRadius.vertical(top: Radius.circular(32)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                            blurRadius: 20,
                            offset: const Offset(0, -5),
                          )
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: isWeb 
                            ? BorderRadius.circular(24) 
                            : const BorderRadius.vertical(top: Radius.circular(32)),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                              child: TextField(
                                controller: _titleController,
                                readOnly: _isReadOnly, // 🛡️ Lock title in Read-Only Mode
                                textCapitalization: TextCapitalization.words,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                  letterSpacing: -0.5,
                                ),
                                decoration: InputDecoration(
                                  hintText: "Note Title...",
                                  hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.black26),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                            
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Divider(color: isDark ? Colors.white12 : Colors.grey.shade200, height: 1),
                            ),
                            
                            Expanded(
                              child: Column(
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                                      child: QuillEditor.basic(
                                        controller: _quillController,
                                        focusNode: _contentFocusNode,
                                        scrollController: _scrollController,
                                        config: const QuillEditorConfig(
                                          placeholder: "Start typing your lecture notes, paste an article, or jot down concepts here... MindFlash AI will convert everything you write into a perfect study deck.",
                                          padding: EdgeInsets.only(bottom: 24),
                                          scrollable: true,
                                          autoFocus: false,
                                          expands: true,
                                        ),
                                      ),
                                    ),
                                  ),
                                  
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            _wordCount == 0 
                                              ? "0 words"
                                              : "$_wordCount words  •  ≈ $_minCards-$_maxCards cards",
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: isDark ? Colors.white60 : Colors.black54,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // 🛡️ UX: Hide the formatting toolbar gracefully in Read-Only Mode
                                  AnimatedSize(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                    child: _isReadOnly 
                                      ? const SizedBox.shrink()
                                      : Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: isDark ? const Color(0xFF1A1128) : const Color(0xFFF4F5F7),
                                            border: Border(
                                              top: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200, width: 1),
                                            ),
                                          ),
                                          child: QuillSimpleToolbar(
                                            controller: _quillController,
                                            config: const QuillSimpleToolbarConfig(
                                              showFontFamily: false,
                                              showFontSize: false,
                                              showSearchButton: false,
                                              // 🛡️ UX: Enabled the highlighter/color pickers!
                                              showColorButton: true,
                                              showBackgroundColorButton: true,
                                              showInlineCode: false,
                                              showCodeBlock: false,
                                              showListCheck: false,
                                              showIndent: false,
                                              showAlignmentButtons: false,
                                              showSmallButton: false,
                                              showStrikeThrough: false,
                                              showSubscript: false,
                                              showSuperscript: false,
                                              showLink: false,
                                              showDirection: false,
                                              showLineHeightButton: false,
                                              multiRowsDisplay: true, 
                                              showClearFormat: true,
                                            ),
                                          ),
                                        ),
                                  ),
                                ],
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
          
          bottomNavigationBar: SafeArea(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF151023) : const Color(0xFFFDFBFF),
                border: Border(
                  top: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: maxContentWidth),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8B4EFF), Color(0xFFE841A1)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF8B4EFF).withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: _handleGenerate,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.auto_awesome_rounded, color: Colors.white),
                                  const SizedBox(width: 8),
                                  const Text(
                                    "Generate Flashcards",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      "⚡ 3 Energy",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
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
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}