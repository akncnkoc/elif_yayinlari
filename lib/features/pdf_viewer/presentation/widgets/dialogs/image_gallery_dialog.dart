import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import '../../../../../models/crop_data.dart';

/// Swipeable image gallery dialog for viewing question images
class ImageGalleryDialog extends StatefulWidget {
  final List<MapEntry<String, Uint8List>> imageList;
  final int initialIndex;
  final CropData cropData;
  final List<CropItem> cropsForPage;
  final PdfController pdfController;

  const ImageGalleryDialog({
    super.key,
    required this.imageList,
    required this.initialIndex,
    required this.cropData,
    required this.cropsForPage,
    required this.pdfController,
  });

  @override
  State<ImageGalleryDialog> createState() => _ImageGalleryDialogState();
}

class _ImageGalleryDialogState extends State<ImageGalleryDialog> {
  late PageController _pageController;
  late int _currentIndex;
  late List<CropItem> _sortedCrops;

  @override
  void initState() {
    super.initState();

    // Sort crops by question number
    _sortedCrops = List.from(widget.cropsForPage);
    _sortedCrops.sort((a, b) {
      if (a.questionNumber == null && b.questionNumber == null) return 0;
      if (a.questionNumber == null) return 1;
      if (b.questionNumber == null) return -1;
      return a.questionNumber!.compareTo(b.questionNumber!);
    });

    // Find initial index in sorted list
    final initialImageFile = widget.imageList[widget.initialIndex].key;
    _currentIndex = _sortedCrops.indexWhere(
      (crop) => crop.imageFile == initialImageFile,
    );
    if (_currentIndex == -1) _currentIndex = 0;

    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Dialog(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(scheme),

            // Image Gallery
            Expanded(
              child: _buildImageGallery(),
            ),

            // Navigation Footer
            if (_sortedCrops.length > 1) _buildNavigationFooter(scheme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.image, color: scheme.onPrimaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _sortedCrops[_currentIndex].questionNumber != null
                  ? 'Soru ${_sortedCrops[_currentIndex].questionNumber}'
                  : _sortedCrops[_currentIndex].imageFile.split('/').last,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: scheme.onPrimaryContainer,
              ),
            ),
          ),
          // Page indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${_currentIndex + 1}/${_sortedCrops.length}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
            color: scheme.onPrimaryContainer,
          ),
        ],
      ),
    );
  }

  Widget _buildImageGallery() {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      itemCount: _sortedCrops.length,
      itemBuilder: (context, index) {
        final crop = _sortedCrops[index];
        final imageEntry = widget.imageList.firstWhere(
          (entry) => entry.key == crop.imageFile,
        );

        return InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Center(
            child: Image.memory(
              imageEntry.value,
              fit: BoxFit.contain,
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavigationFooter(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: _currentIndex > 0
                ? () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                : null,
          ),
          const SizedBox(width: 24),
          Text(
            'Soru numarasına göre sıralı',
            style: TextStyle(
              fontSize: 12,
              color: scheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(width: 24),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios),
            onPressed: _currentIndex < _sortedCrops.length - 1
                ? () {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
