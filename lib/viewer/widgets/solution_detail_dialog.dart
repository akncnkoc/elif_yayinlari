import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:archive/archive.dart';
import '../../models/crop_data.dart';
import 'animation_player_widget.dart';
import 'drawable_content_widget.dart';
import '../tool_state.dart';

class SolutionDetailDialog extends StatefulWidget {
  final CropItem crop;
  final String baseDirectory;
  final String? zipFilePath;
  final Uint8List? zipBytes; // Web platformu için
  final Uint8List? cropImage; // Soru resmi (crop'un image'ı)

  const SolutionDetailDialog({
    super.key,
    required this.crop,
    required this.baseDirectory,
    this.zipFilePath,
    this.zipBytes,
    this.cropImage,
  });

  @override
  State<SolutionDetailDialog> createState() => _SolutionDetailDialogState();
}

class _SolutionDetailDialogState extends State<SolutionDetailDialog> {
  final GlobalKey<AnimationPlayerWidgetState> _animationKey =
      GlobalKey<AnimationPlayerWidgetState>();

  // Image viewer state
  bool _showImageViewer = false;
  Uint8List? _loadedCropImage; // Yüklenen crop image
  final GlobalKey<DrawableContentWidgetState> _drawableKey =
      GlobalKey<DrawableContentWidgetState>();

  // Solution images state
  List<Uint8List> _loadedSolutionImages = [];
  int _currentSolutionImageIndex = 0;
  bool _showSolutionImageViewer = false;

  // Drawing state
  bool _isDrawingMode = false;
  final ValueNotifier<ToolState> _toolNotifier = ValueNotifier<ToolState>(
    ToolState(
      mouse: true,
      eraser: false,
      pencil: false,
      highlighter: false,
      grab: false,
      shape: false,
      selection: false,
      magnifier: false,
      selectedShape: ShapeType.rectangle,
      color: Colors.red,
      width: 2.0,
    ),
  );

  @override
  void initState() {
    super.initState();
    _loadCropImage();
    _loadSolutionImages();
  }

  Future<void> _loadCropImage() async {
    try {
      // Önce constructor'dan gelen image'ı kullan
      if (widget.cropImage != null) {
        setState(() {
          _loadedCropImage = widget.cropImage;
        });
        return;
      }

      // Eğer yok ise, file'dan veya zip'ten yükle
      Uint8List? imageBytes;

      if (widget.zipBytes != null || widget.zipFilePath != null) {
        // ZIP'ten yükle
        final zipBytes =
            widget.zipBytes ??
            (widget.zipFilePath != null
                ? await File(widget.zipFilePath!).readAsBytes()
                : null);

        if (zipBytes != null) {
          final archive = ZipDecoder().decodeBytes(zipBytes);
          final imageFileName = widget.crop.imageFile.split('/').last;

          for (final file in archive) {
            if (file.name.endsWith(imageFileName) && file.isFile) {
              imageBytes = file.content as Uint8List;
              break;
            }
          }
        }
      } else {
        // File system'den yükle
        final imagePath = '${widget.baseDirectory}/${widget.crop.imageFile}';
        final imageFile = File(imagePath);

        if (await imageFile.exists()) {
          imageBytes = await imageFile.readAsBytes();
        }
      }

      if (imageBytes != null && mounted) {
        setState(() {
          _loadedCropImage = imageBytes;
        });
      }
    } catch (e) {
      // Ignore
    }
  }

  Future<void> _loadSolutionImages() async {
    final solutionImages = widget.crop.solutionMetadata?.solutionImages;

    if (solutionImages == null || solutionImages.isEmpty) {
      return;
    }

    try {
      final List<Uint8List> loadedImages = [];

      for (final imagePath in solutionImages) {
        Uint8List? imageBytes;

        if (widget.zipBytes != null || widget.zipFilePath != null) {
          // ZIP'ten yükle
          final zipBytes =
              widget.zipBytes ??
              (widget.zipFilePath != null
                  ? await File(widget.zipFilePath!).readAsBytes()
                  : null);

          if (zipBytes != null) {
            final archive = ZipDecoder().decodeBytes(zipBytes);

            // Önce tam path ile dene
            for (final file in archive) {
              if (file.name == imagePath && file.isFile) {
                imageBytes = file.content as Uint8List;
                break;
              }
            }

            // Eğer bulunamadıysa, dosya adı ile dene
            if (imageBytes == null) {
              final imageFileName = imagePath.split('/').last;

              for (final file in archive) {
                if (file.name.endsWith(imageFileName) && file.isFile) {
                  imageBytes = file.content as Uint8List;
                  break;
                }
              }
            }
          }
        } else {
          // File system'den yükle
          final fullPath = '${widget.baseDirectory}/$imagePath';
          final imageFile = File(fullPath);

          if (await imageFile.exists()) {
            imageBytes = await imageFile.readAsBytes();
          }
        }

        if (imageBytes != null) {
          loadedImages.add(imageBytes);
        }
      }

      if (loadedImages.isNotEmpty && mounted) {
        setState(() {
          _loadedSolutionImages = loadedImages;
        });
      }
    } catch (e) {
      // Ignore
    }
  }

  @override
  void dispose() {
    _toolNotifier.dispose();
    super.dispose();
  }

  void _toggleDrawingMode() {
    setState(() {
      _isDrawingMode = !_isDrawingMode;
      if (_isDrawingMode) {
        // Enable pencil by default when entering drawing mode
        _toolNotifier.value = _toolNotifier.value.copyWith(
          pencil: true,
          mouse: false,
        );
      } else {
        // Return to mouse mode
        _toolNotifier.value = _toolNotifier.value.copyWith(
          pencil: false,
          mouse: true,
        );
      }
    });
  }

  void _selectTool(String tool) {
    final currentTool = _toolNotifier.value;
    _toolNotifier.value = currentTool.copyWith(
      pencil: tool == 'pencil',
      eraser: tool == 'eraser',
      highlighter: tool == 'highlighter',
      shape: tool == 'shape',
      mouse: false,
    );
  }

  void _selectShape(ShapeType shape) {
    _toolNotifier.value = _toolNotifier.value.copyWith(selectedShape: shape);
  }

  void _selectColor(Color color) {
    _toolNotifier.value = _toolNotifier.value.copyWith(color: color);
  }

  void _clearDrawing() {
    _drawableKey.currentState?.clearDrawing();
  }

  void _undoDrawing() {
    _drawableKey.currentState?.undo();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(64),
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.85),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.lightbulb_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Soru ${widget.crop.questionNumber ?? "?"} - Çözüm',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    onPressed: () => Navigator.pop(context),
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Content - Horizontal Layout
            Expanded(
              child: Stack(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Side - Animation Player with Drawing
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          child: Stack(
                            children: [
                              // Content with drawing layer
                              widget.crop.userSolution?.hasAnimationData ==
                                          true &&
                                      widget
                                              .crop
                                              .userSolution
                                              ?.drawingDataFile !=
                                          null
                                  ? DrawableContentWidget(
                                      key: _drawableKey,
                                      isDrawingEnabled: _isDrawingMode,
                                      toolNotifier: _toolNotifier,
                                      child: AnimationPlayerWidget(
                                        key: _animationKey,
                                        animationDataPath: widget
                                            .crop
                                            .userSolution!
                                            .drawingDataFile!,
                                        baseDirectory: widget.baseDirectory,
                                        zipFilePath: widget.zipFilePath,
                                        zipBytes: widget.zipBytes,
                                      ),
                                    )
                                  : _loadedSolutionImages.isNotEmpty
                                  ? Stack(
                                      children: [
                                        Center(
                                          child: InteractiveViewer(
                                            minScale: 0.5,
                                            maxScale: 4.0,
                                            child: Image.memory(
                                              _loadedSolutionImages[_currentSolutionImageIndex],
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ),
                                        // Navigasyon butonları (birden fazla resim varsa)
                                        if (_loadedSolutionImages.length >
                                            1) ...[
                                          // Sol ok
                                          if (_currentSolutionImageIndex > 0)
                                            Positioned(
                                              left: 16,
                                              top: 0,
                                              bottom: 0,
                                              child: Center(
                                                child: FloatingActionButton.small(
                                                  onPressed: () {
                                                    setState(() {
                                                      _currentSolutionImageIndex--;
                                                    });
                                                  },
                                                  backgroundColor: Colors.white
                                                      .withValues(alpha: 0.9),
                                                  child: const Icon(
                                                    Icons.chevron_left,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          // Sağ ok
                                          if (_currentSolutionImageIndex <
                                              _loadedSolutionImages.length - 1)
                                            Positioned(
                                              right: 16,
                                              top: 0,
                                              bottom: 0,
                                              child: Center(
                                                child: FloatingActionButton.small(
                                                  onPressed: () {
                                                    setState(() {
                                                      _currentSolutionImageIndex++;
                                                    });
                                                  },
                                                  backgroundColor: Colors.white
                                                      .withValues(alpha: 0.9),
                                                  child: const Icon(
                                                    Icons.chevron_right,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          // Sayaç
                                          Positioned(
                                            bottom: 16,
                                            left: 0,
                                            right: 0,
                                            child: Center(
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.7),
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                                child: Text(
                                                  '${_currentSolutionImageIndex + 1} / ${_loadedSolutionImages.length}',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    )
                                  : const Center(
                                      child: Text('Çözüm verisi bulunamadı'),
                                    ),

                              // Drawing toolbar (top-left)
                              if (_isDrawingMode)
                                Positioned(
                                  top: 8,
                                  left: 8,
                                  child: _buildDrawingToolbar(),
                                ),

                              // Drawing mode toggle button (top-right)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Column(
                                  children: [
                                    // Soru resmini göster butonu
                                    FloatingActionButton.small(
                                      onPressed: _loadedCropImage != null
                                          ? () {
                                              setState(() {
                                                _showImageViewer =
                                                    !_showImageViewer;
                                              });
                                            }
                                          : null,
                                      backgroundColor: _showImageViewer
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                          : _loadedCropImage == null
                                          ? Colors.grey.shade300
                                          : Theme.of(
                                              context,
                                            ).colorScheme.tertiaryContainer,
                                      tooltip: _loadedCropImage == null
                                          ? 'Soru resmi yükleniyor...'
                                          : 'Soru Resmini Göster/Gizle',
                                      child: Icon(
                                        _showImageViewer
                                            ? Icons.image
                                            : Icons.image_outlined,
                                        color: _loadedCropImage == null
                                            ? Colors.grey.shade500
                                            : _showImageViewer
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.onPrimary
                                            : Theme.of(
                                                context,
                                              ).colorScheme.onTertiaryContainer,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    FloatingActionButton.small(
                                      onPressed: _toggleDrawingMode,
                                      backgroundColor: _isDrawingMode
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                          : Theme.of(context)
                                                .colorScheme
                                                .surfaceContainerHighest,
                                      child: Icon(
                                        _isDrawingMode
                                            ? Icons.check
                                            : Icons.edit,
                                        color: _isDrawingMode
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.onPrimary
                                            : Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    if (_isDrawingMode) ...[
                                      const SizedBox(height: 8),
                                      FloatingActionButton.small(
                                        onPressed: _undoDrawing,
                                        backgroundColor: Theme.of(
                                          context,
                                        ).colorScheme.surfaceContainerHighest,
                                        child: Icon(
                                          Icons.undo,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      FloatingActionButton.small(
                                        onPressed: _clearDrawing,
                                        backgroundColor: Theme.of(
                                          context,
                                        ).colorScheme.errorContainer,
                                        child: Icon(
                                          Icons.delete_outline,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onErrorContainer,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              // Soru resmi viewer (en üstte - animation kontrollerin üzerinde)
                              if (_showImageViewer && _loadedCropImage != null)
                                Positioned.fill(
                                  child: GestureDetector(
                                    onTap:
                                        () {}, // Backdrop'a tıklayınca kapanmasın
                                    child: Container(
                                      color: Colors.black.withValues(
                                        alpha: 0.8,
                                      ),
                                      child: Stack(
                                        children: [
                                          // Resim
                                          Center(
                                            child: InteractiveViewer(
                                              minScale: 0.5,
                                              maxScale: 4.0,
                                              child: Image.memory(
                                                _loadedCropImage!,
                                                fit: BoxFit.contain,
                                              ),
                                            ),
                                          ),
                                          // Kapat butonu
                                          Positioned(
                                            top: 16,
                                            right: 16,
                                            child: FloatingActionButton(
                                              onPressed: () {
                                                setState(() {
                                                  _showImageViewer = false;
                                                });
                                              },
                                              backgroundColor: Colors.white,
                                              child: const Icon(
                                                Icons.close,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                          // Bilgi yazısı
                                          Positioned(
                                            bottom: 16,
                                            left: 0,
                                            right: 0,
                                            child: Center(
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 8,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.7),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: const Text(
                                                  '🔍 Yakınlaştırmak için parmakla sürükleyin',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      // Divider
                      VerticalDivider(
                        width: 1,
                        thickness: 1,
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),

                      // Right Side - Controls and Answer
                      Expanded(
                        flex: 1,
                        child: Container(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          child: ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              const SizedBox(height: 16),
                              if (widget.crop.solutionMetadata?.answerChoice !=
                                      null ||
                                  widget.crop.userSolution?.answerChoice !=
                                      null) ...[
                                _buildAnswerCard(
                                  context,
                                  widget.crop.solutionMetadata?.answerChoice ??
                                      widget.crop.userSolution!.answerChoice!,
                                ),
                                const SizedBox(height: 16),
                              ],
                              if (_loadedSolutionImages.isNotEmpty) ...[
                                _buildSolutionImagesCard(context),
                                const SizedBox(height: 16),
                              ],
                              if (widget.crop.solutionMetadata?.aiSolution !=
                                  null) ...[
                                _buildAiSolutionCard(
                                  context,
                                  widget.crop.solutionMetadata!.aiSolution!,
                                ),
                                const SizedBox(height: 16),
                              ],
                              // Animation Controls
                              const Text(
                                'KONTROLLER',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // First step
                                  IconButton(
                                    icon: const Icon(
                                      Icons.first_page,
                                      size: 24,
                                    ),
                                    onPressed: () => _animationKey.currentState
                                        ?.resetAnimation(),
                                    tooltip: 'İlk Adım',
                                    style: IconButton.styleFrom(
                                      backgroundColor: Theme.of(
                                        context,
                                      ).colorScheme.primaryContainer,
                                      foregroundColor: Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Previous step
                                  IconButton(
                                    icon: const Icon(
                                      Icons.chevron_left,
                                      size: 32,
                                    ),
                                    onPressed: () => _animationKey.currentState
                                        ?.previousStep(),
                                    tooltip: 'Geri',
                                    style: IconButton.styleFrom(
                                      backgroundColor: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      foregroundColor: Theme.of(
                                        context,
                                      ).colorScheme.onPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Next step
                                  IconButton(
                                    icon: const Icon(
                                      Icons.chevron_right,
                                      size: 32,
                                    ),
                                    onPressed: () =>
                                        _animationKey.currentState?.nextStep(),
                                    tooltip: 'İleri',
                                    style: IconButton.styleFrom(
                                      backgroundColor: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      foregroundColor: Theme.of(
                                        context,
                                      ).colorScheme.onPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Last step
                                  IconButton(
                                    icon: const Icon(Icons.last_page, size: 24),
                                    onPressed: () => _animationKey.currentState
                                        ?.goToLastStep(),
                                    tooltip: 'Son Adım',
                                    style: IconButton.styleFrom(
                                      backgroundColor: Theme.of(
                                        context,
                                      ).colorScheme.primaryContainer,
                                      foregroundColor: Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Solution image viewer overlay (tam ekran)
                  if (_showSolutionImageViewer &&
                      _loadedSolutionImages.isNotEmpty)
                    Positioned.fill(
                      child: GestureDetector(
                        onTap: () {}, // Backdrop'a tıklayınca kapanmasın
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.9),
                          child: Stack(
                            children: [
                              // Resim
                              Center(
                                child: InteractiveViewer(
                                  minScale: 0.5,
                                  maxScale: 4.0,
                                  child: Image.memory(
                                    _loadedSolutionImages[_currentSolutionImageIndex],
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              // Kapat butonu
                              Positioned(
                                top: 16,
                                right: 16,
                                child: FloatingActionButton(
                                  onPressed: () {
                                    setState(() {
                                      _showSolutionImageViewer = false;
                                    });
                                  },
                                  backgroundColor: Colors.white,
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              // Navigasyon ok tuşları (birden fazla resim varsa)
                              if (_loadedSolutionImages.length > 1) ...[
                                // Sol ok
                                if (_currentSolutionImageIndex > 0)
                                  Positioned(
                                    left: 16,
                                    top: 0,
                                    bottom: 0,
                                    child: Center(
                                      child: FloatingActionButton(
                                        onPressed: () {
                                          setState(() {
                                            _currentSolutionImageIndex--;
                                          });
                                        },
                                        backgroundColor: Colors.white,
                                        child: const Icon(
                                          Icons.chevron_left,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ),
                                // Sağ ok
                                if (_currentSolutionImageIndex <
                                    _loadedSolutionImages.length - 1)
                                  Positioned(
                                    right: 16,
                                    top: 0,
                                    bottom: 0,
                                    child: Center(
                                      child: FloatingActionButton(
                                        onPressed: () {
                                          setState(() {
                                            _currentSolutionImageIndex++;
                                          });
                                        },
                                        backgroundColor: Colors.white,
                                        child: const Icon(
                                          Icons.chevron_right,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                              // Bilgi yazısı
                              Positioned(
                                bottom: 16,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.7,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      _loadedSolutionImages.length > 1
                                          ? '${_currentSolutionImageIndex + 1} / ${_loadedSolutionImages.length}'
                                          : 'Çözüm Resmi',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerCard(BuildContext context, String answer) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  answer,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'Seçilen Cevap',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSolutionImagesCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.photo_library,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Çözüm Resimleri',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_loadedSolutionImages.length} Resim',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _loadedSolutionImages.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _currentSolutionImageIndex = index;
                          _showSolutionImageViewer = true;
                        });
                      },
                      child: Container(
                        width: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline,
                            width: 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            _loadedSolutionImages[index],
                            fit: BoxFit.cover,
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
    );
  }

  Widget _buildAiSolutionCard(BuildContext context, AiSolution aiSolution) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.psychology,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
                const SizedBox(width: 8),
                const Text(
                  'AI Çözümü',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getConfidenceColor(
                      aiSolution.confidence,
                    ).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '%${(aiSolution.confidence * 100).toInt()}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getConfidenceColor(aiSolution.confidence),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cevap: ${aiSolution.answer}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    aiSolution.reasoning,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            if (aiSolution.steps.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Çözüm Adımları:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...aiSolution.steps.map(
                (step) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontSize: 14)),
                      Expanded(
                        child: Text(step, style: const TextStyle(fontSize: 14)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }

  Widget _buildDrawingToolbar() {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: ValueListenableBuilder<ToolState>(
          valueListenable: _toolNotifier,
          builder: (context, tool, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tools row
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Pencil
                    _buildToolButton(
                      icon: Icons.edit,
                      isSelected: tool.pencil,
                      onPressed: () => _selectTool('pencil'),
                      tooltip: 'Kalem',
                    ),
                    const SizedBox(width: 4),
                    // Highlighter
                    _buildToolButton(
                      icon: Icons.highlight,
                      isSelected: tool.highlighter,
                      onPressed: () => _selectTool('highlighter'),
                      tooltip: 'Fosforlu Kalem',
                    ),
                    const SizedBox(width: 4),
                    // Eraser
                    _buildToolButton(
                      icon: Icons.auto_fix_high,
                      isSelected: tool.eraser,
                      onPressed: () => _selectTool('eraser'),
                      tooltip: 'Silgi',
                    ),
                    const SizedBox(width: 4),
                    // Shape
                    _buildToolButton(
                      icon: Icons.rectangle,
                      isSelected: tool.shape,
                      onPressed: () => _selectTool('shape'),
                      tooltip: 'Şekiller',
                    ),
                  ],
                ),

                // Shapes row (only shown when shape tool is selected)
                if (tool.shape) ...[
                  const SizedBox(height: 8),
                  Container(
                    height: 1,
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildShapeButton(
                        icon: Icons.rectangle_outlined,
                        isSelected: tool.selectedShape == ShapeType.rectangle,
                        onPressed: () => _selectShape(ShapeType.rectangle),
                        tooltip: 'Dikdörtgen',
                      ),
                      const SizedBox(width: 4),
                      _buildShapeButton(
                        icon: Icons.circle_outlined,
                        isSelected: tool.selectedShape == ShapeType.circle,
                        onPressed: () => _selectShape(ShapeType.circle),
                        tooltip: 'Daire',
                      ),
                      const SizedBox(width: 4),
                      _buildShapeButton(
                        icon: Icons.arrow_forward,
                        isSelected: tool.selectedShape == ShapeType.arrow,
                        onPressed: () => _selectShape(ShapeType.arrow),
                        tooltip: 'Ok',
                      ),
                      const SizedBox(width: 4),
                      _buildShapeButton(
                        icon: Icons.remove,
                        isSelected: tool.selectedShape == ShapeType.line,
                        onPressed: () => _selectShape(ShapeType.line),
                        tooltip: 'Çizgi',
                      ),
                    ],
                  ),
                ],

                // Colors row
                const SizedBox(height: 8),
                Container(
                  height: 1,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildColorButton(Colors.red, tool.color == Colors.red),
                    const SizedBox(width: 4),
                    _buildColorButton(Colors.blue, tool.color == Colors.blue),
                    const SizedBox(width: 4),
                    _buildColorButton(Colors.green, tool.color == Colors.green),
                    const SizedBox(width: 4),
                    _buildColorButton(
                      Colors.orange,
                      tool.color == Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    _buildColorButton(
                      Colors.purple,
                      tool.color == Colors.purple,
                    ),
                    const SizedBox(width: 4),
                    _buildColorButton(Colors.black, tool.color == Colors.black),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primaryContainer
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildShapeButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.secondaryContainer
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isSelected
                ? Theme.of(context).colorScheme.onSecondaryContainer
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildColorButton(Color color, bool isSelected) {
    return InkWell(
      onTap: () => _selectColor(color),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
            width: isSelected ? 3 : 1,
          ),
        ),
      ),
    );
  }
}
