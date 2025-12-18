import 'package:flutter/material.dart';
import '../../services/toc_detector_service.dart';

class ChapterDrawer extends StatelessWidget {
  final List<Chapter> chapters;
  final Function(int pageNumber) onChapterSelected;
  final int currentPage;

  const ChapterDrawer({
    super.key,
    required this.chapters,
    required this.onChapterSelected,
    required this.currentPage,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 320,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
            decoration: BoxDecoration(
              color: const Color(0xFF252525),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.format_list_bulleted_rounded,
                    color: Theme.of(context).primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'İçindekiler',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: chapters.length,
              separatorBuilder: (context, index) => Divider(
                color: Colors.white.withValues(alpha: 0.05),
                height: 1,
                indent: 20,
                endIndent: 20,
              ),
              itemBuilder: (context, index) {
                final chapter = chapters[index];
                final isSelected = _isPageInChapter(chapter, index);

                return Material(
                  color: Colors.transparent,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    onTap: () {
                      Navigator.of(context).pop(); // Close drawer
                      onChapterSelected(chapter.pageNumber);
                    },
                    leading: Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white54,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    title: Text(
                      chapter.title,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                    trailing: Text(
                      'Sf. ${chapter.pageNumber}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 12,
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    tileColor: isSelected
                        ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  bool _isPageInChapter(Chapter chapter, int index) {
    // Current page logic:
    // If current page >= chapter.page AND (not last chapter AND current page < nextChapter.page)
    // OR (last chapter AND current page >= chapter.page)

    // For simplicity, just exact match? No, chapters cover ranges.
    if (currentPage < chapter.pageNumber) return false;

    if (index < chapters.length - 1) {
      final nextChapter = chapters[index + 1];
      return currentPage >= chapter.pageNumber &&
          currentPage < nextChapter.pageNumber;
    } else {
      // Last chapter checks if we are past it
      return currentPage >= chapter.pageNumber;
    }
  }
}
