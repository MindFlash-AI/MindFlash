import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/note_model.dart';
import '../../services/note_storage_service.dart';

class TrashBinScreen extends StatefulWidget {
  const TrashBinScreen({super.key});

  @override
  State<TrashBinScreen> createState() => _TrashBinScreenState();
}

class _TrashBinScreenState extends State<TrashBinScreen> {
  final NoteStorageService _noteStorage = NoteStorageService();
  final GlobalKey<SliverAnimatedGridState> _gridKey = GlobalKey<SliverAnimatedGridState>();
  List<Note> _notes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrashedNotes();
  }

  Future<void> _loadTrashedNotes() async {
    setState(() => _isLoading = true);

    // 🧹 Fire-and-forget background cleanup of old notes in Firestore
    _noteStorage.cleanupOldTrashedNotes();

    try {
      final notes = await _noteStorage.getNotes();
      final now = DateTime.now();
      
      // 🛡️ Filter to ONLY show trashed notes that are < 30 days old
      final trashedNotes = notes.where((note) {
        return note.isTrashed == true && now.difference(note.updatedAt).inDays < 30;
      }).toList();

      if (mounted) {
        setState(() {
          _notes = trashedNotes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _restoreNote(Note note) async {
    HapticFeedback.lightImpact();
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index >= 0) {
      final removedNote = _notes.removeAt(index);
      _gridKey.currentState?.removeItem(
        index,
        (context, animation) => _buildNoteCard(context, removedNote, animation),
        duration: const Duration(milliseconds: 350),
      );
      setState(() {}); // Trigger empty state UI if needed
    }
    await _noteStorage.restoreNote(note.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Restored "${note.title.isEmpty ? "Untitled Note" : note.title}"'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _confirmPermanentDelete(Note note) {
    HapticFeedback.mediumImpact();
    final title = note.title.isEmpty ? "Untitled Note" : note.title;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text("Delete Permanently?", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          "Are you sure you want to permanently delete \"$title\"? This action cannot be undone.",
          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, height: 1.5),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final index = _notes.indexWhere((n) => n.id == note.id);
              if (index >= 0) {
                final removedNote = _notes.removeAt(index);
                _gridKey.currentState?.removeItem(
                  index,
                  (context, animation) => _buildNoteCard(context, removedNote, animation),
                  duration: const Duration(milliseconds: 350),
                );
                setState(() {});
              }
              await _noteStorage.deleteNote(note.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text("Delete", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmEmptyTrash() {
    if (_notes.isEmpty) return;
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Empty Trash?", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: Text(
          "Are you sure you want to permanently delete all items in the trash? This action cannot be undone.",
          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, height: 1.5),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final notesToDelete = List<Note>.from(_notes);
              
              for (int i = _notes.length - 1; i >= 0; i--) {
                final removedNote = _notes[i];
                _gridKey.currentState?.removeItem(
                  i,
                  (context, animation) => _buildNoteCard(context, removedNote, animation),
                  duration: const Duration(milliseconds: 350),
                );
              }
              setState(() => _notes.clear());
              
              // 🚀 Delete all currently trashed items concurrently
              await Future.wait(notesToDelete.map((note) => _noteStorage.deleteNote(note.id)));
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Trash emptied successfully.')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text("Empty Trash", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(BuildContext context, Note note, Animation<double> animation) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final noteTitle = note.title.isEmpty ? "Untitled Note" : note.title;
    final int daysPassed = DateTime.now().difference(note.updatedAt).inDays;
    final int daysLeft = (30 - daysPassed).clamp(0, 30);
    final String daysLeftText = daysLeft == 0 ? "Expires today" : "$daysLeft days left";

    return ScaleTransition(
      scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
      child: FadeTransition(
        opacity: animation,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200, width: 2),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 50,
                child: Container(
                  decoration: BoxDecoration(color: isDark ? const Color(0xFF1E1533) : const Color(0xFFF8F9FA), borderRadius: const BorderRadius.vertical(top: Radius.circular(14))),
                  child: Center(child: Icon(Icons.article_outlined, size: 48, color: isDark ? Colors.white24 : Colors.grey.shade400)),
                ),
              ),
              Divider(height: 1, color: isDark ? Colors.white12 : Colors.grey.shade200),
              Expanded(
                flex: 50,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(noteTitle, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Theme.of(context).textTheme.bodyLarge?.color), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(child: Text(DateFormat('MMM d, y').format(note.updatedAt), style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                            child: Text(daysLeftText, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _restoreNote(note),
                              style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF8B4EFF), side: BorderSide(color: const Color(0xFF8B4EFF).withValues(alpha: 0.5)), padding: const EdgeInsets.symmetric(horizontal: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                              child: const Text("Restore", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: IconButton(icon: const Icon(Icons.delete_forever_rounded, size: 18, color: Colors.redAccent), constraints: const BoxConstraints(minWidth: 36, minHeight: 36), padding: EdgeInsets.zero, onPressed: () => _confirmPermanentDelete(note), tooltip: "Delete Permanently")),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Theme.of(context).textTheme.bodyLarge?.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 20),
            ),
            const SizedBox(width: 12),
            Text("Trash Bin", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).textTheme.bodyLarge?.color)),
          ],
        ),
        actions: [
          if (_notes.isNotEmpty)
            TextButton.icon(
              icon: const Icon(Icons.delete_forever_rounded, size: 18),
              label: const Text("Empty Trash", style: TextStyle(fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              onPressed: _confirmEmptyTrash,
            ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF8B4EFF)))
          : Stack(
              children: [
                AnimatedOpacity(
                  opacity: _notes.isEmpty ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 400),
                  child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.delete_outline_rounded, size: 64, color: isDark ? Colors.white24 : Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text("Trash is empty", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
                                const SizedBox(height: 8),
                                Text(
                                  "Deleted notes will appear here.\nNotes are permanently deleted after 30 days.", 
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: isDark ? Colors.white54 : Colors.grey.shade600, height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ), // 🛡️ BUG FIX: Added the missing closing parenthesis here!
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                          sliver: SliverAnimatedGrid(
                            key: _gridKey,
                            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 220,
                              mainAxisSpacing: 20,
                              crossAxisSpacing: 20,
                              childAspectRatio: 0.72, // Made slightly taller to fit 2 buttons
                            ),
                            initialItemCount: _notes.length,
                            itemBuilder: (context, index, animation) {
                              return _buildNoteCard(context, _notes[index], animation);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}