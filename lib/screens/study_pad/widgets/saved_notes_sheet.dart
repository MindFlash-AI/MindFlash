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

    return Container(
      // 🛡️ UX: When used as an endDrawer on Web, we remove the fixed height constraint
      height: widget.onNoteSelected != null ? double.infinity : MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: widget.onNoteSelected != null 
            ? BorderRadius.zero 
            : const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Only show the "grabber" handle if it's a bottom sheet (Mobile)
          if (widget.onNoteSelected == null)
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Saved Notes",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: isDark ? Colors.white54 : Colors.black54),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF8B4EFF)))
                : _notes.isEmpty
                    ? Center(
                        child: Text(
                          "No saved notes yet.",
                          style: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        physics: const BouncingScrollPhysics(),
                        itemCount: _notes.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final note = _notes[index];
                          final noteTitle = note.title.isEmpty ? "Untitled Note" : note.title;
                          
                          return Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              title: Text(
                                noteTitle,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                DateFormat('MMM d, y • h:mm a').format(note.updatedAt),
                                style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                                onPressed: () => _confirmDelete(context, note.id, noteTitle),
                              ),
                              onTap: () {
                                HapticFeedback.lightImpact();
                                // 🛡️ FIX: If a callback is provided (Web), use it. 
                                // Otherwise, pop the result (Mobile).
                                if (widget.onNoteSelected != null) {
                                  widget.onNoteSelected!(note);
                                } else {
                                  Navigator.pop(context, note);
                                }
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}