import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../../models/note_model.dart';
import '../../../../../services/note_storage_service.dart';

class SavedNotesSheet extends StatefulWidget {
  // 🛡️ FIX: Added optional callback to allow the Web Sidebar to talk to the main screen
  final Function(Note)? onNoteSelected;

  const SavedNotesSheet({super.key, this.onNoteSelected});

  @override
  State<SavedNotesSheet> createState() => _SavedNotesSheetState();
}

class _SavedNotesSheetState extends State<SavedNotesSheet> {
  final NoteStorageService _noteStorage = NoteStorageService();
  List<Note> _notes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final notes = await _noteStorage.getNotes();
    if (mounted) {
      setState(() {
        _notes = notes;
        _isLoading = false;
      });
    }
  }

  void _deleteNote(String id) async {
    setState(() => _notes.removeWhere((n) => n.id == id));
    await _noteStorage.deleteNote(id);
  }

  void _confirmDelete(BuildContext context, String id, String title) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Delete Note?",
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color, 
            fontWeight: FontWeight.bold
          ),
        ),
        content: Text(
          "Are you sure you want to delete \"$title\"? This action cannot be undone.",
          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _deleteNote(id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Delete", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: Container(
            height: widget.onNoteSelected != null ? double.infinity : MediaQuery.of(context).size.height * 0.8,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: widget.onNoteSelected != null 
                  ? BorderRadius.zero 
                  : const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: ClipRRect(
              borderRadius: widget.onNoteSelected != null 
                  ? BorderRadius.zero 
                  : const BorderRadius.vertical(top: Radius.circular(32)),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  if (widget.onNoteSelected == null)
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 16, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B4EFF).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.folder_copy_rounded, color: Color(0xFF8B4EFF), size: 22),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "My Notes",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            Navigator.pop(context);
                          },
                          icon: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(color: isDark ? Colors.white12 : Colors.grey.shade100, shape: BoxShape.circle),
                            child: Icon(Icons.close_rounded, color: isDark ? Colors.white54 : Colors.black54, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  if (!_isLoading) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Storage Quota", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white54 : Colors.grey.shade600)),
                              Text("${_notes.length} / 50 Notes", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _notes.length >= 45 ? Colors.redAccent : const Color(0xFF8B4EFF))),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (_notes.length / 50.0).clamp(0.0, 1.0),
                              minHeight: 6,
                              backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(_notes.length >= 45 ? Colors.redAccent : const Color(0xFF8B4EFF)),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ],
                  
                  Divider(height: 1, color: isDark ? Colors.white12 : Colors.grey.shade200),
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator(color: Color(0xFF8B4EFF)))
                        : _notes.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.edit_note_rounded, size: 64, color: isDark ? Colors.white24 : Colors.grey.shade300),
                                    const SizedBox(height: 16),
                                    Text("No notes yet", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
                                    const SizedBox(height: 8),
                                    Text("Your saved study pad notes will appear here.", style: TextStyle(color: isDark ? Colors.white54 : Colors.grey.shade600)),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(24),
                                physics: const BouncingScrollPhysics(),
                                itemCount: _notes.length,
                                itemBuilder: (context, index) {
                                  final note = _notes[index];
                                  final noteTitle = note.title.isEmpty ? "Untitled Note" : note.title;
                                  
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).cardColor,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
                                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02), blurRadius: 10, offset: const Offset(0, 4))],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(16),
                                      clipBehavior: Clip.antiAlias,
                                      child: InkWell(
                                        onTap: () {
                                          HapticFeedback.lightImpact();
                                          if (widget.onNoteSelected != null) {
                                            widget.onNoteSelected!(note);
                                          } else {
                                            Navigator.pop(context, note);
                                          }
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(12),
                                                decoration: BoxDecoration(color: const Color(0xFF8B4EFF).withValues(alpha: 0.1), shape: BoxShape.circle),
                                                child: const Icon(Icons.edit_document, color: Color(0xFF8B4EFF)),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      noteTitle,
                                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      DateFormat('MMM d, y • h:mm a').format(note.updatedAt),
                                                      style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : Colors.grey.shade600),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                                                onPressed: () => _confirmDelete(context, note.id, noteTitle),
                                                tooltip: "Delete Note",
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
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