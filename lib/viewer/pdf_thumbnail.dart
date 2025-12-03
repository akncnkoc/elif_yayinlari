import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:pdfrx/pdfrx.dart';

// Global thumbnail cache - PDF ID ve sayfa numarasına göre cache tutar
class ThumbnailCache {
  static final Map<String, Map<int, ui.Image>> _cache = {};

  static String _getCacheKey(PdfViewerController controller) {
    return controller.hashCode.toString();
  }

  static ui.Image? get(PdfViewerController controller, int pageNumber) {
    final key = _getCacheKey(controller);
    return _cache[key]?[pageNumber];
  }

  static void put(
    PdfViewerController controller,
    int pageNumber,
    ui.Image image,
  ) {
    final key = _getCacheKey(controller);
    _cache[key] ??= {};
    _cache[key]![pageNumber] = image;
  }

  static void clear() {
    _cache.clear();
  }

  static void clearForController(PdfViewerController controller) {
    final key = _getCacheKey(controller);
    _cache.remove(key);
  }
}

class PdfThumbnailList extends StatefulWidget {
  final PdfViewerController pdfController;
  final Future<PdfDocument> pdfDocument;
  final int currentPage;
  final int totalPages;
  final Function(int) onPageSelected;

  const PdfThumbnailList({
    super.key,
    required this.pdfController,
    required this.pdfDocument,
    required this.currentPage,
    required this.totalPages,
    required this.onPageSelected,
  });

  @override
  State<PdfThumbnailList> createState() => _PdfThumbnailListState();
}

class _PdfThumbnailListState extends State<PdfThumbnailList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(PdfThumbnailList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPage != widget.currentPage) {
      _scrollToCurrentPage();
    }
  }

  @override
  void initState() {
    super.initState();
    // İlk açılışta da ortala
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentPage();
    });
  }

  void _scrollToCurrentPage() {
    if (!_scrollController.hasClients) return;

    // Her thumbnail yaklaşık 102 piksel genişliğinde (90 + 6*2 margin)
    const double thumbnailWidth = 102.0;
    final double targetPosition = (widget.currentPage - 1) * thumbnailWidth;

    // Ekran genişliğinin ortasını hesapla
    final double screenCenter = MediaQuery.of(context).size.width / 2;

    // Thumbnail'ı ortaya getirmek için pozisyonu ayarla
    final double centeredPosition =
        targetPosition - screenCenter + (thumbnailWidth / 2);

    // Scroll limitlerini kontrol et
    final double maxScroll = _scrollController.position.maxScrollExtent;
    final double minScroll = _scrollController.position.minScrollExtent;
    final double finalPosition = centeredPosition.clamp(minScroll, maxScroll);

    _scrollController.animateTo(
      finalPosition,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MouseRegion(
      child: Listener(
        onPointerSignal: (event) {
          if (event is PointerScrollEvent) {
            if (_scrollController.hasClients) {
              final offset = _scrollController.offset + event.scrollDelta.dy;
              final maxScroll = _scrollController.position.maxScrollExtent;
              final minScroll = _scrollController.position.minScrollExtent;

              _scrollController.jumpTo(offset.clamp(minScroll, maxScroll));
            }
          }
        },
        child: Container(
          height: 140,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(
              top: BorderSide(color: colorScheme.outlineVariant, width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            itemCount: widget.totalPages,
            itemBuilder: (context, index) {
              final pageNumber = index + 1;
              return PdfThumbnail(
                controller: widget.pdfController,
                pdfDocument: widget.pdfDocument,
                pageNumber: pageNumber,
                isCurrentPage: pageNumber == widget.currentPage,
                onTap: () => widget.onPageSelected(pageNumber),
              );
            },
          ),
        ),
      ),
    );
  }
}

// PdfThumbnail widget'ı buraya eklenecek
class PdfThumbnail extends StatefulWidget {
  final PdfViewerController controller;
  final Future<PdfDocument> pdfDocument;
  final int pageNumber;
  final bool isCurrentPage;
  final VoidCallback onTap;

  const PdfThumbnail({
    super.key,
    required this.controller,
    required this.pdfDocument,
    required this.pageNumber,
    required this.isCurrentPage,
    required this.onTap,
  });

  @override
  State<PdfThumbnail> createState() => _PdfThumbnailState();
}

class _PdfThumbnailState extends State<PdfThumbnail> {
  ui.Image? _cachedImage;
  bool _isLoading = false;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  Future<void> _loadThumbnail() async {
    // Önce global cache'e bak
    final cachedImage = ThumbnailCache.get(
      widget.controller,
      widget.pageNumber,
    );
    if (cachedImage != null) {
      if (mounted) {
        setState(() {
          _cachedImage = cachedImage;
          _isLoading = false;
        });
      }
      return;
    }

    // Eğer cache'te yoksa ve şu an yükleniyorsa tekrar yükleme
    if (_cachedImage != null || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      // pdfrx: Use pdfDocument pages
      final document = await widget.pdfDocument;
      if (widget.pageNumber < 1 || widget.pageNumber > document.pages.length) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }
      final page = document.pages[widget.pageNumber - 1]; // Pages are 0-indexed

      // pdfrx: Render the page to get image
      final pageImage = await page.render(
        width: (page.width * 2.0).round(),
        height: (page.height * 2.0).round(),
        fullWidth: (page.width * 2.0).round().toDouble(),
        fullHeight: (page.height * 2.0).round().toDouble(),
      );

      if (pageImage != null) {
        final image = await pageImage.createImage();
        if (image != null) {
          ThumbnailCache.put(widget.controller, widget.pageNumber, image);

          if (mounted) {
            setState(() {
              _cachedImage = image;
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      print('Error loading thumbnail for page ${widget.pageNumber}: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 90,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border.all(
              color: widget.isCurrentPage
                  ? colorScheme.primary
                  : colorScheme.inversePrimary,
              width: widget.isCurrentPage ? 2.5 : 1.5,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: widget.isCurrentPage || _isHovering
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(11),
                      topRight: Radius.circular(11),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(11),
                      topRight: Radius.circular(11),
                    ),
                    child: _cachedImage != null
                        ? RawImage(image: _cachedImage, fit: BoxFit.cover)
                        : Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(
                                colorScheme.primary,
                              ),
                            ),
                          ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: widget.isCurrentPage
                      ? colorScheme.primary
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(11),
                    bottomRight: Radius.circular(11),
                  ),
                ),
                child: Center(
                  child: Text(
                    '${widget.pageNumber}',
                    style: TextStyle(
                      color: widget.isCurrentPage
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
