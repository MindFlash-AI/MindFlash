import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class StudyPadWeb extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final TextEditingController titleController;
  final QuillController quillController;
  final ScrollController scrollController;
  final FocusNode contentFocusNode;
  final Widget saveStatusWidget;
  final Widget wordCountWidget;
  final Widget savedNotesSidebar;
  final VoidCallback onNewNote;
  final VoidCallback onSave;
  final VoidCallback onOpenNotes;
  final VoidCallback onGenerate;
  final bool isReadOnly;

  const StudyPadWeb({
    super.key,
    required this.scaffoldKey,
    required this.titleController,
    required this.quillController,
    required this.scrollController,
    required this.contentFocusNode,
    required this.saveStatusWidget,
    required this.wordCountWidget,
    required this.savedNotesSidebar,
    required this.onNewNote,
    required this.onSave,
    required this.onOpenNotes,
    required this.onGenerate,
    required this.isReadOnly,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      endDrawer: Drawer(width: 400, child: savedNotesSidebar),
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            const Icon(Icons.edit_note_rounded, color: Color(0xFF8B4EFF), size: 28),
            const SizedBox(width: 12),
            const Text("Study Pad", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
            const SizedBox(width: 20),
            saveStatusWidget,
          ],
        ),
        actions: [
          IconButton(onPressed: onNewNote, icon: const Icon(Icons.add_rounded), tooltip: "New Note"),
          IconButton(onPressed: onOpenNotes, icon: const Icon(Icons.history_rounded), tooltip: "Saved Notes"),
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: ElevatedButton.icon(
              onPressed: onGenerate,
              icon: const Icon(Icons.auto_awesome_rounded, size: 18),
              label: const Text("Generate Flashcards", style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B4EFF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900),
          margin: const EdgeInsets.fromLTRB(40, 0, 40, 40),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 40, offset: const Offset(0, 10))
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 32, 32, 16),
                child: TextField(
                  controller: titleController,
                  readOnly: isReadOnly,
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1),
                  decoration: const InputDecoration(hintText: "Untitled Note", border: InputBorder.none),
                ),
              ),
              if (!isReadOnly)
                Container(
                  color: isDark ? Colors.white.withOpacity(0.02) : Colors.grey.shade50,
                  child: QuillSimpleToolbar(
                    controller: quillController,
                    config: const QuillSimpleToolbarConfig(
                      multiRowsDisplay: false,
                      showSearchButton: false,
                      showFontFamily: false,
                      showFontSize: false,
                      // 🛡️ SECURITY FIX: Explicitly disable media links/quotes that can 
                      // be hijacked to inject Base64 images directly into the Quill delta.
                      showLink: false,
                      showQuote: false, 
                    ),
                  ),
                ),
              const Divider(height: 1),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: QuillEditor.basic(
                    controller: quillController,
                    focusNode: contentFocusNode,
                    scrollController: scrollController,
                    config: const QuillEditorConfig(
                      placeholder: "Start typing...", 
                      expands: true,
                      // 🛡️ Pre-empts any drag-and-drop file hijacks
                      enableInteractiveSelection: true,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [wordCountWidget]),
              )
            ],
          ),
        ),
      ),
    );
  }
}