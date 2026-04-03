import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class StudyPadMobile extends StatelessWidget {
  final TextEditingController titleController;
  final QuillController quillController;
  final ScrollController scrollController;
  final FocusNode contentFocusNode;
  final Widget saveStatusWidget;
  final Widget wordCountWidget;
  final VoidCallback onNewNote;
  final VoidCallback onOpenNotes;
  final VoidCallback onGenerate;
  final bool isReadOnly;
  final Widget? adWidget;

  const StudyPadMobile({
    super.key,
    required this.titleController,
    required this.quillController,
    required this.scrollController,
    required this.contentFocusNode,
    required this.saveStatusWidget,
    required this.wordCountWidget,
    required this.onNewNote,
    required this.onOpenNotes,
    required this.onGenerate,
    required this.isReadOnly,
    this.adWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: const Text("Study Pad", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          saveStatusWidget,
          IconButton(onPressed: onNewNote, icon: const Icon(Icons.add_rounded)),
          IconButton(onPressed: onOpenNotes, icon: const Icon(Icons.folder_open_rounded)),
        ],
      ),
      body: Column(
        children: [
          if (adWidget != null) adWidget!,
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: TextField(
                      controller: titleController,
                      readOnly: isReadOnly,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(hintText: "Title...", border: InputBorder.none),
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: QuillEditor.basic(
                        controller: quillController,
                        focusNode: contentFocusNode,
                        scrollController: scrollController,
                        config: const QuillEditorConfig(
                          expands: true,
                          // 🛡️ SECURITY FIX: Strip capabilities
                          enableInteractiveSelection: true,
                        ),
                      ),
                    ),
                  ),
                  if (!isReadOnly)
                    QuillSimpleToolbar(
                      controller: quillController,
                      config: const QuillSimpleToolbarConfig(
                        multiRowsDisplay: false,
                        // 🛡️ SECURITY FIX
                        showLink: false,
                        showQuote: false, 
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: onGenerate,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B4EFF),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text("Generate Flashcards", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ),
    );
  }
}