import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shimmer/shimmer.dart';
import '../../../models/note_model.dart';
import '../../../services/note_storage_service.dart';
import '../../../services/secure_cache_service.dart';
import '../study_pad_screen.dart';
import '../trash_bin_screen.dart';

class SavedNotesSheet extends StatefulWidget {
  const SavedNotesSheet({super.key});

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
    // 🚀 PERFORMANCE: Load instantly from local cache while fetching fresh data
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final cachedData = prefs.getString('study_pad_notes_cache_$uid');
        if (cachedData != null && _notes.isEmpty) {
          final decryptedData = SecureCacheService.decrypt(cachedData, uid);
          if (decryptedData.isNotEmpty) {
            final List<dynamic> decoded = jsonDecode(decryptedData);
            final cachedNotes = decoded.map((e) => Note(
              id: e['id']?.toString() ?? '',
              title: e['title']?.toString() ?? 'Untitled Note',
              content: e['content']?.toString() ?? '',
              drawingData: e['drawingData']?.toString() ?? '',
              updatedAt: e['updatedAt'] != null ? DateTime.parse(e['updatedAt']) : DateTime.now(),
              isTrashed: e['isTrashed'] == true,
            )).toList();
            
            // 🛡️ Safely filter out any trashed notes from the local cache
            cachedNotes.removeWhere((n) => n.isTrashed == true);

            if (mounted) {
              setState(() {
                _notes = cachedNotes;
                _isLoading = false; // Display cached UI immediately
              });
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Error loading cached notes: $e");
    }

    final notes = await _noteStorage.getNotes();
    
    // 🛡️ Safely filter out trashed notes from the server response
    final activeNotes = notes.where((note) => note.isTrashed != true).toList();
    if (mounted) {
      setState(() {
        _notes = activeNotes;
        _isLoading = false;
      });
    }

    // 🚀 Update cache silently in the background with fresh data
    await _updateCacheSilently();
  }

  Future<void> _updateCacheSilently() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final String encoded = jsonEncode(_notes.map((n) => {
          'id': n.id,
          'title': n.title,
          'content': n.content,
          'drawingData': n.drawingData,
          'updatedAt': n.updatedAt.toIso8601String(),
          'isTrashed': n.isTrashed,
        }).toList());
        final encryptedData = SecureCacheService.encrypt(encoded, uid);
        await prefs.setString('study_pad_notes_cache_$uid', encryptedData);
      }
    } catch (e) {
      debugPrint("Error saving cached notes: $e");
    }
  }

  void _deleteNote(String id) async {
    setState(() => _notes.removeWhere((n) => n.id == id));
    await _noteStorage.moveToTrash(id);
    _updateCacheSilently(); // 🚀 OPTIMIZATION: Keep cache in sync so deleted notes don't reappear
  }

  void _createNewNote() async {
    HapticFeedback.selectionClick();
    if (_notes.length >= 50) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Storage Limit Reached", style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text("You have reached the generous limit of 50 Study Pad notes. Please delete some older notes to create new ones! 🛑"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx), 
              child: const Text("OK", style: TextStyle(color: Color(0xFF8B4EFF)))
            ),
          ],
        )
      );
      return;
    }
    
    // Slide into the Study Pad and wait for return
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const StudyPadScreen()));
    _loadNotes(); // Refresh notes list instantly to show the newly created item
  }

  void _confirmDelete(BuildContext context, String id, String title) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Move to Trash?",
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color, 
            fontWeight: FontWeight.bold
          ),
        ),
        content: Text(
          "Are you sure you want to move \"$title\" to the trash bin?",
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
            child: const Text("Move to Trash", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesListSkeleton(bool isDark) {
    final baseColor = isDark ? Colors.white10 : Colors.grey.shade300;
    final highlightColor = isDark ? Colors.white24 : Colors.grey.shade100;

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 220,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          childAspectRatio: 0.8,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return Shimmer.fromColors(
              baseColor: baseColor,
              highlightColor: highlightColor,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            );
          },
          childCount: 6,
        ),
      ),
    );
  }

  Widget _buildNoteCard(Note note, bool isDark) {
    final noteTitle = note.title.isEmpty ? "Untitled Note" : note.title;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () async {
          HapticFeedback.lightImpact();
          await Navigator.push(context, MaterialPageRoute(builder: (_) => StudyPadScreen(initialNote: note)));
          _loadNotes(); // Refresh upon returning to catch any auto-saves
        },
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
              // Preview area (Top 65%)
              Expanded(
                flex: 65,
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1533) : const Color(0xFFF8F9FA),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                  ),
                  child: Center(
                    child: Icon(Icons.article_outlined, size: 48, color: isDark ? Colors.white24 : Colors.grey.shade400),
                  ),
                ),
              ),
              Divider(height: 1, color: isDark ? Colors.white12 : Colors.grey.shade200),
              // Details area (Bottom 35%)
              Expanded(
                flex: 35,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        noteTitle,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Theme.of(context).textTheme.bodyLarge?.color),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              DateFormat('MMM d, y').format(note.updatedAt),
                              style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey.shade600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert_rounded, size: 18, color: isDark ? Colors.white54 : Colors.grey.shade600),
                            padding: EdgeInsets.zero,
                            color: Theme.of(context).cardColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            onSelected: (value) {
                              if (value == 'delete') _confirmDelete(context, note.id, noteTitle);
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 20),
                                    SizedBox(width: 12),
                                    Text("Move to Trash", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ],
                          ),
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
              decoration: BoxDecoration(
                color: const Color(0xFF8B4EFF).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.edit_note_rounded, color: Color(0xFF8B4EFF), size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              "Study Pad",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).textTheme.bodyLarge?.color),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
            tooltip: "Trash Bin",
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const TrashBinScreen()));
              _loadNotes(); // Refresh active list upon return in case items were restored!
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewNote,
        backgroundColor: const Color(0xFF8B4EFF),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("New Note", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. "Start a new note" Banner
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              color: isDark ? Colors.white.withValues(alpha: 0.02) : const Color(0xFFF8F9FA),
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Start a new note",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyMedium?.color),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: _createNewNote,
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: Container(
                              width: 150,
                              height: 200,
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200, width: 2),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF8B4EFF).withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.add, size: 36, color: Color(0xFF8B4EFF)),
                                  ),
                                  const SizedBox(height: 16),
                                  Text("Blank Note", style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
                                ],
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
          ),
          
          // 2. "Recent Notes" Header
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Recent Notes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
                      if (!_isLoading)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _notes.length >= 45 ? Colors.redAccent.withValues(alpha: 0.1) : const Color(0xFF8B4EFF).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "${_notes.length} / 50 Storage Used", 
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _notes.length >= 45 ? Colors.redAccent : const Color(0xFF8B4EFF)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 3. Dynamic Grid of Notes
          if (_isLoading)
            _buildNotesListSkeleton(isDark)
          else if (_notes.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.edit_document, size: 64, color: isDark ? Colors.white24 : Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text("No recent notes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
                    const SizedBox(height: 8),
                    Text("Create a new note to start organizing your thoughts.", style: TextStyle(color: isDark ? Colors.white54 : Colors.grey.shade600)),
                  ],
                ),
              ),
            )
          else
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 220,
                        mainAxisSpacing: 20,
                        crossAxisSpacing: 20,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: _notes.length,
                      itemBuilder: (context, index) {
                        return _buildNoteCard(_notes[index], isDark);
                      },
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}