import 'package:flutter/gestures.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;
import '../core/extensions/pdf_viewer_controller_extensions.dart';
import 'pdf_viewer_with_drawing.dart';
import 'widgets/vertical_tool_sidebar.dart';
import '../soru_cozucu_service.dart';
import 'calculator_widget.dart';
import 'scratchpad_widget.dart';
import '../models/crop_data.dart';
import 'page_time_tracker.dart';
import '../models/page_content.dart'; // [NEW]
import 'package:url_launcher/url_launcher_string.dart';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

// Components
import 'components/pdf_viewer_top_bar.dart';
import 'components/right_thumbnail_sidebar.dart';
import 'components/floating_tool_menu.dart';
import 'components/analysis_result_dialog.dart';
import 'components/video_player_dialog.dart'; // [NEW]

// Services
import 'services/image_capture_service.dart';
import '../services/toc_detector_service.dart'; // [NEW]

import 'package:techatlas/viewer/drawing_provider.dart';
import 'package:provider/provider.dart';

import 'components/chapter_drawer.dart'; // [NEW]

class PdfDrawingViewerPage extends StatefulWidget {
  final String pdfPath;
  final VoidCallback? onBack;
  final CropData? cropData;
  final String? zipFilePath;
  final Uint8List? pdfBytes; // Web platformu için PDF bytes
  final Uint8List? zipBytes; // Web platformu için ZIP bytes
  final PageContent? pageContent; // [NEW]

  const PdfDrawingViewerPage({
    super.key,
    required this.pdfPath,
    this.onBack,
    this.cropData,
    this.zipFilePath,
    this.pdfBytes,
    this.zipBytes,
    this.pageContent,
  });

  @override
  State<PdfDrawingViewerPage> createState() => _PdfDrawingViewerPageState();
}

class _PdfDrawingViewerPageState extends State<PdfDrawingViewerPage> {
  late PdfViewerController _pdfController;
  late Future<PdfDocument> _pdfDocument;
  final GlobalKey<PdfViewerWithDrawingState> _drawingKey = GlobalKey();
  final GlobalKey _canvasKey = GlobalKey();

  // Soru Çözücü Service
  final SoruCozucuService _service = SoruCozucuService();

  // DrawingProvider - initState'te oluşturulacak
  late DrawingProvider _drawingProvider;

  bool _isAnalyzing = false;
  bool _serverHealthy = false;
  bool _showThumbnails = false;
  bool _isToolMenuVisible = false;
  bool _showCalculator = false;
  bool _showScratchpad = false;
  bool _isPdfLoading = true;

  // Sidebar Position State
  Offset _sidebarPosition = const Offset(16, 10);

  // TOC State
  List<Chapter> _chapters = [];
  bool _isTOCLoading = false;
  final TOCDetectorService _tocDetector = TOCDetectorService();

  @override
  void initState() {
    super.initState();

    // DrawingProvider'ı oluştur
    _drawingProvider = DrawingProvider();

    // pdfrx: Separate document loading from controller
    _pdfController = PdfViewerController();
    _pdfDocument = widget.pdfBytes != null
        ? PdfDocument.openData(widget.pdfBytes!)
        : PdfDocument.openFile(widget.pdfPath);

    _loadPdf();
    _checkServerHealth();
  }

  Future<void> _loadPdf() async {
    try {
      await _pdfDocument;
      await Future.delayed(const Duration(milliseconds: 100));

      _pdfController.addListener(() {
        if (mounted && _pdfController.isReady) {
          setState(() {});
        }
      });

      if (mounted) {
        setState(() => _isPdfLoading = false);
      }

      // Start TOC detection
      _detectTOC();
    } catch (e) {
      print('❌ Error loading PDF: $e');
      if (mounted) {
        setState(() => _isPdfLoading = false);
      }
    }
  }

  Future<void> _detectTOC() async {
    if (!mounted) return;
    // Don't show loading on UI for this background task

    try {
      final doc = await _pdfDocument;
      // Scan for TOC
      final chapters = await _tocDetector.scanForTOC(doc);

      if (mounted && chapters.isNotEmpty) {
        setState(() {
          _chapters = chapters;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✨ ${chapters.length} bölümlü içindekiler bulundu!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Göster',
              textColor: Colors.white,
              onPressed: _openChapterDrawer,
            ),
          ),
        );
      }
    } catch (e) {
      print('TOC Detection error: $e');
    }
  }

  void _openChapterDrawer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'İçindekiler',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  controller: controller,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: _chapters.length,
                  separatorBuilder: (_, __) =>
                      const Divider(color: Colors.white10),
                  itemBuilder: (context, index) {
                    final chapter = _chapters[index];
                    return ListTile(
                      title: Text(
                        chapter.title,
                        style: const TextStyle(color: Colors.white),
                      ),
                      trailing: Text(
                        '${chapter.pageNumber}',
                        style: const TextStyle(color: Colors.white54),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _pdfController.jumpToPage(chapter.pageNumber);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _drawingProvider.dispose();
    super.dispose();
  }

  /// Python sunucusunun çalışıp çalışmadığını kontrol et
  Future<void> _checkServerHealth() async {
    final isHealthy = await _service.checkHealth();

    if (!mounted) return;

    setState(() {
      _serverHealthy = isHealthy;
    });

    // if (!isHealthy) {
    //   _showServerHealthWarning();
    // }
  }

  /// Seçili alanı capture et
  Future<Uint8List?> _captureSelectedArea() async {
    final state = _drawingKey.currentState;
    if (state == null || state.selectedAreaNotifier.value == null) {
      print('❌ Seçili alan yok');
      return null;
    }

    return ImageCaptureService.captureSelectedArea(
      canvasKey: _canvasKey,
      selectedRect: state.selectedAreaNotifier.value!,
    );
  }

  /// Soru çözme işlemini başlat
  Future<void> _solveProblem() async {
    if (_isAnalyzing) return;

    final state = _drawingKey.currentState;
    if (state == null || state.selectedAreaNotifier.value == null) {
      _showSnackBar('⚠️ Lütfen önce bir alan seçin!', Colors.orange);
      return;
    }

    // Sunucu kontrolü
    if (!_serverHealthy) {
      _showSnackBar(
        'Python sunucusu çalışmıyor!',
        Colors.red,
        action: SnackBarAction(
          label: 'Test Et',
          textColor: Colors.white,
          onPressed: _checkServerHealth,
        ),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
    });

    _showAnalyzingDialog();

    try {
      print('📸 Seçili alan capture ediliyor...');
      final imageBytes = await _captureSelectedArea();

      if (imageBytes == null) {
        throw Exception('Görsel alınamadı');
      }

      print('✅ Seçili alan alındı: ${imageBytes.length} bytes');

      print('🔍 API\'ye gönderiliyor...');
      final result = await _service.analyzeImage(imageBytes, returnImage: true);

      if (!mounted) return;
      Navigator.of(context).pop(); // Progress dialog'u kapat

      if (result == null || !result.success) {
        throw Exception(result?.error ?? 'Analiz başarısız');
      }

      print('✅ Analiz tamamlandı: ${result.soruSayisi} soru bulundu');

      state.clearSelection();

      _showResultDialog(result);
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();

      _showSnackBar('❌ Hata: $e', Colors.red);
      print('❌ Soru çözme hatası: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  void _showAnalyzingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  '🤖 Seçili alan analiz ediliyor...',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showResultDialog(AnalysisResult result) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.transparent,
        pageBuilder: (context, animation, secondaryAnimation) {
          return AnalysisResultDialog(result: result);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _showSnackBar(
    String message,
    Color backgroundColor, {
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 4),
        action: action,
      ),
    );
  }

  void _toggleToolMenu() {
    setState(() {
      _isToolMenuVisible = !_isToolMenuVisible;
    });
  }

  void _openCalculator() {
    setState(() {
      _showCalculator = true;
    });
  }

  void _closeCalculator() {
    setState(() {
      _showCalculator = false;
    });
  }

  void _openScratchpad() {
    setState(() {
      _showScratchpad = true;
    });
  }

  void _closeScratchpad() {
    setState(() {
      _showScratchpad = false;
    });
  }

  void _toggleThumbnails() {
    setState(() {
      _showThumbnails = !_showThumbnails;
    });
  }

  /// Sayfaya git dialog'unu göster
  void _showGoToPageDialog() {
    final pageController = TextEditingController();
    final totalPages = _pdfController.pagesCount ?? 0;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sayfaya Git'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Toplam $totalPages sayfa',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: pageController,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Sayfa Numarası',
                  hintText: '1-$totalPages arası',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.tag),
                ),
                onSubmitted: (value) {
                  _goToPage(pageController.text, totalPages);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () {
                _goToPage(pageController.text, totalPages);
                Navigator.of(context).pop();
              },
              child: const Text('Git'),
            ),
          ],
        );
      },
    );
  }

  /// Belirtilen sayfaya git
  void _goToPage(String pageText, int totalPages) {
    final pageNumber = int.tryParse(pageText);

    if (pageNumber == null) {
      _showSnackBar('⚠️ Geçerli bir sayı girin!', Colors.orange);
      return;
    }

    if (pageNumber < 1 || pageNumber > totalPages) {
      _showSnackBar(
        '⚠️ Sayfa numarası 1-$totalPages arasında olmalı!',
        Colors.orange,
      );
      return;
    }

    _pdfController.jumpToPage(pageNumber);
    _showSnackBar('📄 Sayfa $pageNumber\'e gidildi', Colors.green);
  }

  void _showPageContentDialog(List<PageItem> items) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.amber.shade700),
                const SizedBox(width: 12),
                const Text(
                  'Faydalı İçerikler',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...items.map((item) {
              if (item is LinkItem) {
                return ListTile(
                  leading: const Icon(Icons.link, color: Colors.blue),
                  title: Text(item.title),
                  subtitle: Text(item.url),
                  onTap: () {
                    Navigator.pop(context);
                    _launchUrl(item.url);
                  },
                );
              } else if (item is VideoItem) {
                return ListTile(
                  leading: const Icon(
                    Icons.play_circle_fill,
                    color: Colors.red,
                  ),
                  title: Text(item.filename),
                  subtitle: const Text('Video'),
                  onTap: () {
                    Navigator.pop(context);
                    _playVideo(item);
                  },
                );
              }
              return const SizedBox.shrink();
            }).toList(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    try {
      await launchUrlString(url);
    } catch (e) {
      _showSnackBar('Link açılamadı: $e', Colors.red);
    }
  }

  Future<void> _playVideo(VideoItem item) async {
    // Determine video path
    String? localPath;

    if (widget.zipFilePath != null) {
      // Need to extract video from zip if not already extracted or accessible
      // Since we don't have random access to zip entries easily without extracting,
      // we should extract this specific file to temp
      try {
        _showAnalyzingDialog(); // Loading...

        final tempDir = await getTemporaryDirectory();
        final videoName = item.filename;
        final targetPath = '${tempDir.path}/$videoName';
        final targetFile = File(targetPath);

        if (await targetFile.exists()) {
          // Already extracted
          localPath = targetPath;
        } else {
          // Extract from zip
          // We need to read the zip again... this is inefficient if zip is large.
          // Better optimization: keep zip archive open or cache.
          // For now, valid implementation:
          final bytes = await File(widget.zipFilePath!).readAsBytes();
          final archive = ZipDecoder().decodeBytes(bytes);
          final videoFile =
              archive.findFile(item.path) ??
              archive.findFile(
                'videos/${item.filename}',
              ); // Try both exact path and assumed path

          if (videoFile != null) {
            final data = videoFile.content as List<int>;
            await targetFile.writeAsBytes(data);
            localPath = targetPath;
          }
        }

        if (mounted) Navigator.pop(context); // Close loading

        if (localPath != null) {
          // Open video player
          _showVideoPlayer(localPath);
        } else {
          _showSnackBar('Video dosyası zip içinde bulunamadı', Colors.red);
        }
      } catch (e) {
        if (mounted) Navigator.pop(context);
        _showSnackBar('Video hazırlama hatası: $e', Colors.red);
      }
    } else {
      _showSnackBar(
        'Web veya byte-stream video oynatma henüz desteklenmiyor',
        Colors.orange,
      );
    }
  }

  void _showVideoPlayer(String path) {
    if (kIsWeb ||
        (!Platform.isWindows && !Platform.isAndroid && !Platform.isIOS)) {
      _showSnackBar('Bu platformda video oynatılamıyor', Colors.orange);
      return;
    }

    // Basit dosya adı çıkarma
    String filename = path.split(Platform.pathSeparator).last;
    if (filename.length > 30) {
      filename = '${filename.substring(0, 30)}...';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => VideoPlayerDialog(videoPath: path, title: filename),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _drawingProvider,
      child: Scaffold(
        body: Stack(
          children: [
            Column(
              children: [
                Consumer<DrawingProvider>(
                  builder: (context, drawingProvider, child) {
                    if (_isPdfLoading) {
                      return const SizedBox.shrink();
                    }

                    final state = _drawingKey.currentState;
                    final items =
                        widget.pageContent?.pages[drawingProvider.currentPage];
                    final hasContent = items != null && items.isNotEmpty;

                    if (state == null) {
                      return PdfViewerTopBar(
                        pdfPath: widget.pdfPath,
                        pdfController: _pdfController,
                        currentPage: drawingProvider.currentPage,
                        showThumbnails: _showThumbnails,
                        onToggleThumbnails: _toggleThumbnails,
                        zoomLevel: drawingProvider.zoomLevel,
                        timeTracker: PageTimeTracker(onUpdate: () {}),
                        currentPageTime: '0sn',
                        onBack: widget.onBack,
                        onGoToPage: _showGoToPageDialog,
                        onShowPageContent: widget.pageContent != null
                            ? () => _showPageContentDialog(items ?? [])
                            : null,
                        hasPageContent: hasContent,
                        hasChapters: _chapters.isNotEmpty,
                        onShowChapters: _chapters.isNotEmpty
                            ? _openChapterDrawer
                            : null,
                      );
                    }

                    return ValueListenableBuilder<String>(
                      valueListenable: state.currentPageTimeNotifier,
                      builder: (context, pageTime, _) {
                        return AnimatedBuilder(
                          animation: state.transformationController,
                          builder: (context, _) {
                            // Re-calculate for this builder scope if needed, or rely on outer calc
                            // But we need to update hasContent here too if checking dynamically
                            final items = widget
                                .pageContent
                                ?.pages[drawingProvider.currentPage];
                            final hasContent =
                                items != null && items.isNotEmpty;

                            return PdfViewerTopBar(
                              pdfPath: widget.pdfPath,
                              pdfController: _pdfController,
                              currentPage: drawingProvider.currentPage,
                              showThumbnails: _showThumbnails,
                              onToggleThumbnails: _toggleThumbnails,
                              zoomLevel: drawingProvider.zoomLevel,
                              timeTracker: state.timeTracker,
                              currentPageTime: pageTime,
                              onBack: widget.onBack,
                              onGoToPage: _showGoToPageDialog,
                              onShowPageContent: widget.pageContent != null
                                  ? () => _showPageContentDialog(items ?? [])
                                  : null,
                              hasPageContent: hasContent,
                              hasChapters: _chapters.isNotEmpty,
                              onShowChapters: _chapters.isNotEmpty
                                  ? _openChapterDrawer
                                  : null,
                            );
                          },
                        );
                      },
                    );
                  },
                ),

                // PDF Viewer + Floating Panel
                Expanded(
                  child: Stack(
                    children: [
                      // PDF Viewer (Full screen)
                      RepaintBoundary(
                        key: _canvasKey,
                        child: Listener(
                          onPointerSignal: (event) {
                            if (event is PointerScrollEvent) {
                              final controller = _pdfController;
                              if (controller.isReady) {
                                final matrix = controller.value.clone();
                                final dy = -event.scrollDelta.dy;
                                matrix.translateByVector3(
                                  Vector3(0.0, dy, 0.0),
                                );
                                controller.value = matrix;
                              }
                            }
                          },
                          onPointerPanZoomUpdate: (event) {
                            // print('PanZoom event: ${event.panDelta}');
                            final controller = _pdfController;
                            if (controller.isReady) {
                              final matrix = controller.value.clone();
                              final dy = event.panDelta.dy;
                              matrix.translateByVector3(Vector3(0, dy, 0));
                              controller.value = matrix;
                            }
                          },
                          child: PdfViewerWithDrawing(
                            key: _drawingKey,
                            controller: _pdfController,
                            documentRef: _pdfDocument,
                            cropData: widget.cropData,
                            zipFilePath: widget.zipFilePath,
                            zipBytes: widget.zipBytes,
                          ),
                        ),
                      ),

                      // Floating Panel (Overlay)
                      // Vertical Tool Sidebar (Draggable)
                      if (_drawingKey.currentState != null)
                        Positioned(
                          left: _sidebarPosition.dx,
                          top: _sidebarPosition.dy,
                          child: VerticalToolSidebar(
                            drawingProvider: _drawingProvider,
                            toolNotifier:
                                _drawingKey.currentState!.toolNotifier,
                            canUndoNotifier:
                                _drawingKey.currentState!.canUndoNotifier,
                            canRedoNotifier:
                                _drawingKey.currentState!.canRedoNotifier,
                            onSolve: _serverHealthy ? _solveProblem : null,
                            onRotateLeft: () =>
                                _drawingKey.currentState!.rotateLeft(),
                            onRotateRight: () =>
                                _drawingKey.currentState!.rotateRight(),
                            onFirstPage: () => _pdfController.jumpToPage(1),
                            onPreviousPage: () => _pdfController.previousPage(),
                            onNextPage: () => _pdfController.nextPage(),
                            onLastPage: () => _pdfController.jumpToPage(
                              _pdfController.pagesCount ?? 1,
                            ),
                            onUndo: () => _drawingKey.currentState!.undo(),
                            onRedo: () => _drawingKey.currentState!.redo(),
                            onClear: () =>
                                _drawingKey.currentState!.clearCurrentPage(),
                            onDragUpdate: (details) {
                              setState(() {
                                _sidebarPosition += details.delta;
                              });
                            },
                            onToggleThumbnails: () {
                              setState(() {
                                _showThumbnails = !_showThumbnails;
                              });
                            },
                          ),
                        ),

                      // Floating Tool Menu (Sağ alt köşe)
                      if (_isToolMenuVisible)
                        FloatingToolMenu(
                          onOpenCalculator: _openCalculator,
                          onOpenScratchpad: _openScratchpad,
                        ),

                      // Calculator Widget (Overlay)
                      if (_showCalculator)
                        CalculatorWidget(onClose: _closeCalculator),

                      // Scratchpad Widget (Overlay)
                      if (_showScratchpad)
                        ScratchpadWidget(onClose: _closeScratchpad),

                      // Right Thumbnail Sidebar
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        right: _showThumbnails ? 0 : -160, // Hide off-screen
                        top: 0,
                        bottom: 0,
                        child: RightThumbnailSidebar(
                          pdfController: _pdfController,
                          pdfDocument: _pdfDocument,
                          currentPage: _drawingProvider.currentPage,
                          onClose: () {
                            setState(() {
                              _showThumbnails = false;
                            });
                          },
                        ),
                      ),

                      // [REMOVED] Page Content Indicator (Moved to TopBar)
                    ],
                  ),
                ),
              ],
            ),
            if (_isPdfLoading)
              Positioned.fill(
                child: Container(
                  color: Theme.of(
                    context,
                  ).colorScheme.surface.withValues(alpha: 0.95),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Loading animation
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: CircularProgressIndicator(
                            strokeWidth: 6,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Loading text
                        Text(
                          'PDF Yükleniyor...',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 12),

                        Text(
                          'Lütfen bekleyin',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Progress indicator dots
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(3, (index) {
                            return TweenAnimationBuilder<double>(
                              key: ValueKey('$_isPdfLoading-$index'),
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: Duration(
                                milliseconds: 600 + (index * 200),
                              ),
                              curve: Curves.easeInOut,
                              builder: (context, value, child) {
                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Theme.of(context).colorScheme.primary
                                        .withValues(alpha: 0.2 + (value * 0.8)),
                                  ),
                                );
                              },
                              onEnd: () {
                                // Repeat animation
                                if (mounted && _isPdfLoading) {
                                  setState(() {});
                                }
                              },
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _toggleToolMenu,
          tooltip: 'Araçlar',
          child: Icon(_isToolMenuVisible ? Icons.close : Icons.widgets),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }
}
