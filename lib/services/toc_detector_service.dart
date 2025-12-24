import 'package:pdfrx/pdfrx.dart';
import 'dart:math';

class Chapter {
  final String title;
  final int pageNumber; // 1-based
  final int level; // 0 = root, 1 = subsection, etc.

  Chapter({required this.title, required this.pageNumber, this.level = 0});
}

class TOCDetectorService {
  /// Scans the first [scanLimit] pages of the document to find a potential
  /// Table of Contents page.
  ///
  /// Returns a list of [Chapter]s if found, otherwise empty list.
  /// Scans for TOC and supports multi-page TOCs.
  Future<List<Chapter>> scanForTOC(
    PdfDocument doc, {
    int scanLimit = 15,
  }) async {
    // 1. Identify the *start* of the TOC.
    // We look for the first page with a significant number of internal links.

    // Threshold to consider a page as part of TOC
    const int minLinksForTOC = 1; // [RELAXED] Was 3

    // We scan pages 1 to min(pages.length, scanLimit)
    int limit = min(doc.pages.length, scanLimit);

    List<int> linkCounts = [];
    print('TOC Detector: Scanning first $limit pages...');

    for (int i = 0; i < limit; i++) {
      try {
        final page = doc.pages[i];
        final links = await page.loadLinks();
        // Count ONLY links with valid page numbers in destination,
        // because sometimes links point to URLs or null.
        final internalLinks = links
            .where((l) => l.dest?.pageNumber != null)
            .length;
        linkCounts.add(internalLinks);
        print('TOC Detector: Page ${i + 1} has $internalLinks internal links');
      } catch (e) {
        print('TOC Detector: Error scanning page ${i + 1}: $e');
        linkCounts.add(0);
      }
    }

    // Find the page with the maximum links
    int bestPageIdx = -1;
    int maxCount = 0;
    for (int i = 0; i < linkCounts.length; i++) {
      if (linkCounts[i] >= maxCount) {
        // prefer later pages if equal? no, usually prefer earlier.
        if (linkCounts[i] > maxCount) {
          maxCount = linkCounts[i];
          bestPageIdx = i;
        }
      }
    }

    if (bestPageIdx == -1 || maxCount < minLinksForTOC) {
      return [];
    }

    // Now try to expand the range around the best page.
    // Usually TOC is contiguous.
    // Check previous pages: if they have significant links and are close to best page.
    int firstTocPage = bestPageIdx;
    while (firstTocPage > 0) {
      if (linkCounts[firstTocPage - 1] > maxCount * 0.3 &&
          linkCounts[firstTocPage - 1] >= minLinksForTOC) {
        firstTocPage--;
      } else {
        break;
      }
    }

    // Check next pages
    int lastTocPage = bestPageIdx;
    while (lastTocPage < limit - 1) {
      if (linkCounts[lastTocPage + 1] > maxCount * 0.3 &&
          linkCounts[lastTocPage + 1] >= minLinksForTOC) {
        lastTocPage++;
      } else {
        break;
      }
    }

    // Extract raw items from all identified TOC pages
    List<_RawTocItem> allItems = [];
    for (int i = firstTocPage; i <= lastTocPage; i++) {
      final items = await _extractRawItems(doc.pages[i]);
      allItems.addAll(items);
    }

    if (allItems.isEmpty) return [];

    // Analyze hierarchy based on X-coordinates
    return _buildHierarchy(allItems);
  }

  /// Extracts chapters from specific page (convenience method).
  Future<List<Chapter>> extractChapters(PdfPage page) async {
    final items = await _extractRawItems(page);
    return _buildHierarchy(items);
  }

  /// Internal struct for raw extraction
  Future<List<_RawTocItem>> _extractRawItems(PdfPage page) async {
    List<_RawTocItem> items = [];
    try {
      final links = await page.loadLinks();
      final text = await page.loadText();

      final internalLinks = links.where((l) => l.dest != null).toList();

      // Sort by Y position
      internalLinks.sort((a, b) {
        if (a.rects.isEmpty) return 1;
        if (b.rects.isEmpty) return -1;
        return a.rects.first.top.compareTo(b.rects.first.top);
      });

      for (final link in internalLinks) {
        if (link.rects.isEmpty) continue;
        final linkRect = link.rects.first;

        // Find text on same line
        const double verticalTolerance = 12.0;

        // Filter fragments that are on the same line
        var rowFragments = text.fragments.where((f) {
          final textCenterY = f.bounds.center.y;
          final linkCenterY = linkRect.center.y;
          return (textCenterY - linkCenterY).abs() < verticalTolerance;
        }).toList();

        // [NOISE FILTER]
        // 1. If link rect is wide (covers text), only keep fragments that overlap horizontally.
        // This helps avoid left-margin text (like vertical "MATEMATI...")
        if (linkRect.width > 100) {
          rowFragments = rowFragments.where((f) {
            // Check if fragment overlaps with linkRect horizontally (with some tolerance)
            // or is strictly inside?
            // Let's allow a small gap but generally, if link covers title, text should be inside.
            final overlap = max(
              0.0,
              min(f.bounds.right, linkRect.right) -
                  max(f.bounds.left, linkRect.left),
            );
            return overlap > 0 ||
                (f.bounds.right + 20 >= linkRect.left &&
                    f.bounds.left - 20 <= linkRect.right);
          }).toList();
        }

        // 2. Remove isolated single characters (often artifacts or vertical text like "T", "M")
        // Unless it's a digit (page number or "1.")
        rowFragments.removeWhere((f) {
          final txt = f.text.trim();
          // Remove if length is 1 AND it's not a digit
          // This kills "T" from margin.
          return txt.length == 1 && !RegExp(r'[0-9]').hasMatch(txt);
        });

        // Sort horizontally
        rowFragments.sort((a, b) => a.bounds.left.compareTo(b.bounds.left));

        String title = rowFragments.map((f) => f.text).join(' ').trim();

        // Use the leftmost fragment's X as the indentation indicator
        // If no text found (maybe link is just on the number), use link's left.
        double indentX = linkRect.left;
        if (rowFragments.isNotEmpty) {
          indentX = rowFragments.first.bounds.left;
        }

        if (title.isEmpty) {
          // Fallback: look for text overlapping vertically
          final sameLineFragments = text.fragments.where((f) {
            final verticalOverlap =
                (min(f.bounds.bottom, linkRect.bottom) -
                max(f.bounds.top, linkRect.top));
            return verticalOverlap > 2.0; // slight overlap
          }).toList();

          sameLineFragments.sort(
            (a, b) => a.bounds.left.compareTo(b.bounds.left),
          );
          title = sameLineFragments.map((f) => f.text).join(' ').trim();
          if (sameLineFragments.isNotEmpty) {
            indentX = sameLineFragments.first.bounds.left;
          }
        }

        if (title.isNotEmpty && link.dest?.pageNumber != null) {
          items.add(
            _RawTocItem(
              title: _cleanTitle(title),
              pageNumber: link.dest!.pageNumber!,
              indentX: indentX,
            ),
          );
        } else if (link.dest?.pageNumber != null) {
          items.add(
            _RawTocItem(
              title: "Bölüm (Sf ${link.dest!.pageNumber})",
              pageNumber: link.dest!.pageNumber!,
              indentX: indentX,
            ),
          );
        }
      }
    } catch (e) {
      // ignore
    }
    return items;
  }

  List<Chapter> _buildHierarchy(List<_RawTocItem> items) {
    if (items.isEmpty) return [];

    // 1. Identify unique X coordinates (indentation levels)
    // Round them to nearest N pixels to group slightly misaligned items
    const double bucketSize = 10.0;

    // Get all X values associated with item indentation
    // Note: We need to filter out outliers or handle them?
    // Usually TOC structure is strict.

    // Map approximate X to exact X representative
    // actually we can just use clustering.

    // Histogram of X values
    final Map<int, int> xCounts = {};
    for (var item in items) {
      int bucket = (item.indentX / bucketSize).round();
      xCounts[bucket] = (xCounts[bucket] ?? 0) + 1;
    }

    // Sort buckets by X value
    final sortedBuckets = xCounts.keys.toList()..sort();

    // Assign levels: 0, 1, 2...
    final Map<int, int> bucketToLevel = {};
    for (int i = 0; i < sortedBuckets.length; i++) {
      bucketToLevel[sortedBuckets[i]] = i;
    }

    return items.map((item) {
      int bucket = (item.indentX / bucketSize).round();
      int level = bucketToLevel[bucket] ?? 0;

      // Heuristic: if indentation is very large, restrict max level?
      // Sometimes right-aligned page numbers might be confused for text?
      // No, we took text.rect.left.

      return Chapter(
        title: item.title,
        pageNumber: item.pageNumber,
        level: level,
      );
    }).toList();
  }

  String _cleanTitle(String raw) {
    // Remove typical TOC fillers like "......", " . . . "
    // Regex: Match 2 or more dots/spaces sequence at the end or middle
    String cleaned = raw.replaceAll(RegExp(r'(\s*\.\s*){2,}'), '');

    // Remove trailing numbers (often the page number itself is in the text)
    // e.g. "Introduction .... 1" -> "Introduction"
    cleaned = cleaned.replaceAll(RegExp(r'\s+\d+$'), '');

    // Also remove leading numbers if they look like "1. Title" ?
    // Usually we want to keep them for context (Chapter 1), but maybe clean strict numbering?
    // Let's keep leading numbers for now as they are often part of the title.

    return cleaned.trim();
  }
}

class _RawTocItem {
  final String title;
  final int pageNumber;
  final double indentX;

  _RawTocItem({
    required this.title,
    required this.pageNumber,
    required this.indentX,
  });
}
