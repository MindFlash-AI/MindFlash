import 'package:flutter/material.dart';
import '../../../models/card_model.dart';

class FlashcardListItem extends StatelessWidget {
  final Flashcard card;
  final int index;
  final bool isSelectionMode;
  final bool isSelected;
  final Function(Flashcard) onEdit;
  final Function(String) onDelete;
  final VoidCallback onToggleSelection;
  final VoidCallback onSelect;

  const FlashcardListItem({
    super.key,
    required this.card,
    required this.index,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleSelection,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onLongPress: () {
        if (!isSelectionMode) {
          onToggleSelection();
          onSelect();
        }
      },
      onTap: () {
        if (isSelectionMode) onSelect();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? Colors.blue.withValues(alpha: 0.15) : Colors.blue.shade50)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(color: Colors.blueAccent, width: 2)
              : (isDark
                  ? Border.all(
                      color: Colors.white.withValues(alpha: 0.05), width: 1)
                  : null),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                blurRadius: 15,
                offset: const Offset(0, 5))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (card.isFlagged)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.red.withValues(alpha: 0.15)
                                  : Colors.red.shade50,
                              shape: BoxShape.circle),
                          child: Icon(Icons.flag_rounded,
                              color: isDark
                                  ? Colors.redAccent.shade200
                                  : Colors.redAccent,
                              size: 14),
                        )
                      else if (card.isMastered)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.green.withValues(alpha: 0.15)
                                  : Colors.green.shade50,
                              shape: BoxShape.circle),
                          child: Icon(Icons.check_rounded,
                              color: isDark
                                  ? Colors.greenAccent.shade400
                                  : Colors.green,
                              size: 14),
                        ),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF8B4EFF).withValues(alpha: 0.1)
                                  : const Color(0xFFF4F6FF),
                              borderRadius: BorderRadius.circular(12)),
                          child: Text(
                            "#${index + 1}",
                            style: TextStyle(
                                color: isDark
                                    ? const Color(0xFFB48AFF)
                                    : const Color(0xFF5A6DFF),
                                fontSize: 11,
                                fontWeight: FontWeight.w900),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelectionMode)
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: isSelected,
                          onChanged: (_) => onSelect(),
                          activeColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4)),
                        ),
                      )
                    else ...[
                      IconButton(
                        onPressed: () => onEdit(card),
                        icon: Icon(Icons.edit_rounded,
                            color: isDark ? Colors.white54 : Colors.black45,
                            size: 20),
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        onPressed: () => onDelete(card.id),
                        icon: Icon(Icons.delete_rounded,
                            color: isDark
                                ? Colors.redAccent.shade200
                                : Colors.redAccent,
                            size: 20),
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 4),
                      ReorderableDragStartListener(
                        index: index,
                        child: Icon(Icons.drag_handle_rounded,
                            color: isDark ? Colors.white38 : Colors.black38,
                            size: 20),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text("FRONT",
                style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.grey,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0)),
            const SizedBox(height: 4),
            Text(card.question,
                style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Divider(
                  height: 1,
                  thickness: 1,
                  color: isDark ? Colors.white12 : const Color(0xFFF0F0F0)),
            ),
            Text("BACK",
                style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.grey,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0)),
            const SizedBox(height: 4),
            Text(card.answer,
                style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontSize: 15)),
          ],
        ),
      ),
    );
  }
}
