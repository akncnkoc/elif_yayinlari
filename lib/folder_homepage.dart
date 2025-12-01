import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:window_manager/window_manager.dart';
import 'package:file_picker/file_picker.dart';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import './dropbox/dropbox_service.dart';
import './dropbox/models.dart';
import './models/crop_data.dart';
import 'login_page.dart';
import 'viewer/pdf_drawing_viewer_page.dart';
import 'widgets/dropbox_pdf_thumbnail.dart';

class FolderHomePage extends StatefulWidget {
  const FolderHomePage({super.key});

  @override
  State<FolderHomePage> createState() => _FolderHomePageState();
}

class _FolderHomePageState extends State<FolderHomePage> {
  DropboxService? dropboxService;
  List<DropboxItem> folders = [];
  List<DropboxItem> pdfs = [];
  List<OpenPdfTab> openTabs = [];
  int currentTabIndex = 0;
  bool isLoading = false;
  bool isFullScreen = false;
  bool showFolderBrowser = false;
  bool useDropbox = false;
  bool showStorageSelection = true;

  List<BreadcrumbItem> breadcrumbs = [
    BreadcrumbItem(name: 'Akilli Tahta Proje Demo', path: ''),
  ];

  @override
  void initState() {
    super.initState();
    // Don't automatically load anything - let user choose storage type
  }

  String get currentPath => breadcrumbs.last.path;

  void _selectLocalStorage() {
    setState(() {
      showStorageSelection = false;
      useDropbox = false;
      // Local files will be picked by user on-demand
    });
  }

  Future<void> _makeFullscreen() async {
    setState(() => isFullScreen = !isFullScreen);
    // Web'de window_manager yok
    if (!kIsWeb) {
      await windowManager.setFullScreen(isFullScreen);
    }
  }

  Future<void> _loadFolder(String path) async {
    if (dropboxService == null) return;

    setState(() => isLoading = true);

    try {
      final items = await dropboxService!.listFolder(path);

      print('=== FOLDER CONTENTS: $path ===');
      print('Total items found: ${items.length}');

      final foldersList = items.where((item) => item.isFolder).toList();
      final pdfsList = items.where((item) => item.isPdf).toList();

      print('Total folders: ${foldersList.length}');
      print('Total PDFs: ${pdfsList.length}');
      print('=== END ===');

      setState(() {
        folders = foldersList;
        pdfs = pdfsList;
        isLoading = false;
      });

      if (foldersList.isEmpty && pdfsList.isEmpty) {
        _showError('This folder is empty');
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showError('Failed to load folder: $e');
      print('❌ Error loading folder: $e');
    }
  }

  Future<void> _pickLocalPdf() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['book'],
        allowMultiple: false,
        withData: kIsWeb, // Web'de bytes gerekli
      );

      if (result != null && result.files.single.bytes != null) {
        // Web platformu - bytes kullan
        final bytes = result.files.single.bytes!;
        final fileName = result.files.single.name;

        // Check if it's a book file
        if (fileName.toLowerCase().endsWith('.book')) {
          await _handleZipFileFromBytes(bytes, fileName);
        } else {
          // PDF için web'de bytes'tan geçici dosya oluştur
          if (kIsWeb) {
            _showError('Web platformunda sadece .book dosyaları desteklenir');
          }
        }
      } else if (result != null && result.files.single.path != null) {
        // Mobil/Desktop platformu - path kullan
        final filePath = result.files.single.path!;
        final fileName = result.files.single.name;

        // Check if it's a book file
        if (fileName.toLowerCase().endsWith('.book')) {
          await _handleZipFile(filePath, fileName);
        } else {
          // It's a PDF file
          setState(() {
            openTabs.add(
              OpenPdfTab(
                pdfPath: filePath,
                title: fileName,
                dropboxPath: null,
              ),
            );
            currentTabIndex = openTabs.length - 1;
            showFolderBrowser = false;
          });
        }
      }
    } catch (e) {
      _showError('Failed to open file: $e');
    }
  }

  // Web platformu için bytes kullanarak zip işleme
  Future<void> _handleZipFileFromBytes(Uint8List bytes, String zipFileName) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Decode the book file (zip format)
      final archive = ZipDecoder().decodeBytes(bytes);

      print('📚 BOOK file opened: $zipFileName');
      print('📚 Total files in archive: ${archive.length}');

      // List all files in the archive
      for (final file in archive) {
        print('   - ${file.name} (${file.isFile ? "file" : "dir"})');
      }

      // Look for original.pdf and crop_coordinates.json in the archive
      ArchiveFile? originalPdf;
      ArchiveFile? cropCoordinatesJson;

      for (final file in archive) {
        if (file.isFile && file.name.toLowerCase() == 'original.pdf') {
          originalPdf = file;
          print('✅ Found original.pdf');
        } else if (file.isFile && file.name.toLowerCase() == 'crop_coordinates.json') {
          cropCoordinatesJson = file;
          print('✅ Found crop_coordinates.json');
        }
      }

      if (originalPdf == null) {
        if (!mounted) return;
        Navigator.of(context).pop();
        _showError('original.pdf not found in the book file');
        return;
      }

      // Web'de dosya yazmadan doğrudan bytes kullanacağız
      final pdfBytes = originalPdf.content as List<int>;

      // Parse crop coordinates data if available
      CropData? cropData;
      if (cropCoordinatesJson != null) {
        try {
          final jsonString = utf8.decode(cropCoordinatesJson.content as List<int>);
          print('📄 JSON content (first 500 chars): ${jsonString.substring(0, jsonString.length > 500 ? 500 : jsonString.length)}');
          cropData = CropData.fromJsonString(jsonString);
          print('✅ Crop data loaded: ${cropData.totalDetected} objects detected');
          print('✅ PDF file referenced: ${cropData.pdfFile}');
          print('✅ Total pages: ${cropData.totalPages}');
          print('✅ Total objects: ${cropData.objects.length}');
        } catch (e, stackTrace) {
          print('⚠️ Failed to parse crop_coordinates.json: $e');
          print('Stack trace: $stackTrace');
        }
      } else {
        print('⚠️ No crop_coordinates.json found in ZIP');
      }

      if (!mounted) return;
      Navigator.of(context).pop();

      // Web için bytes'ı kullan - path yerine
      // PDF viewer'a bytes eklemek gerekecek
      setState(() {
        openTabs.add(
          OpenPdfTab(
            pdfPath: 'web_${DateTime.now().millisecondsSinceEpoch}.pdf', // Placeholder
            title: 'original.pdf (from $zipFileName)',
            dropboxPath: null,
            cropData: cropData,
            zipFilePath: null, // Web'de zip path yok
            pdfBytes: Uint8List.fromList(pdfBytes), // PDF bytes'ı sakla
            zipBytes: bytes, // ZIP bytes'ı da sakla (crop resimleri için)
          ),
        );
        currentTabIndex = openTabs.length - 1;
        showFolderBrowser = false;
      });
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      _showError('Failed to extract PDF from zip: $e');
    }
  }

  Future<void> _handleZipFile(String zipPath, String zipFileName) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Read the book file (zip format)
      final bytes = await File(zipPath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      print('📚 BOOK file opened: $zipFileName');
      print('📚 Total files in archive: ${archive.length}');

      // List all files in the archive
      for (final file in archive) {
        print('   - ${file.name} (${file.isFile ? "file" : "dir"})');
      }

      // Look for original.pdf and crop_coordinates.json in the archive
      ArchiveFile? originalPdf;
      ArchiveFile? cropCoordinatesJson;

      for (final file in archive) {
        if (file.isFile && file.name.toLowerCase() == 'original.pdf') {
          originalPdf = file;
          print('✅ Found original.pdf');
        } else if (file.isFile && file.name.toLowerCase() == 'crop_coordinates.json') {
          cropCoordinatesJson = file;
          print('✅ Found crop_coordinates.json');
        }
      }

      if (originalPdf == null) {
        if (!mounted) return;
        Navigator.of(context).pop();
        _showError('original.pdf not found in the book file');
        return;
      }

      // Extract the PDF to a temporary location
      final tempDir = await getTemporaryDirectory();
      final pdfPath = '${tempDir.path}/original_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final pdfFile = File(pdfPath);
      await pdfFile.writeAsBytes(originalPdf.content as List<int>);

      // Parse crop coordinates data if available
      CropData? cropData;
      if (cropCoordinatesJson != null) {
        try {
          final jsonString = utf8.decode(cropCoordinatesJson.content as List<int>);
          print('📄 JSON content (first 500 chars): ${jsonString.substring(0, jsonString.length > 500 ? 500 : jsonString.length)}');
          cropData = CropData.fromJsonString(jsonString);
          print('✅ Crop data loaded: ${cropData.totalDetected} objects detected');
          print('✅ PDF file referenced: ${cropData.pdfFile}');
          print('✅ Total pages: ${cropData.totalPages}');
          print('✅ Total objects: ${cropData.objects.length}');
        } catch (e, stackTrace) {
          print('⚠️ Failed to parse crop_coordinates.json: $e');
          print('Stack trace: $stackTrace');
        }
      } else {
        print('⚠️ No crop_coordinates.json found in ZIP');
      }

      if (!mounted) return;
      Navigator.of(context).pop();

      // Open the extracted PDF
      setState(() {
        openTabs.add(
          OpenPdfTab(
            pdfPath: pdfPath,
            title: 'original.pdf (from $zipFileName)',
            dropboxPath: null,
            cropData: cropData,
            zipFilePath: zipPath, // Zip dosyasının yolunu sakla
          ),
        );
        currentTabIndex = openTabs.length - 1;
        showFolderBrowser = false;
      });
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      _showError('Failed to extract PDF from zip: $e');
    }
  }

  void _navigateToFolder(String folderPath, String folderName) {
    setState(() {
      breadcrumbs.add(BreadcrumbItem(name: folderName, path: folderPath));
    });
    _loadFolder(folderPath);
  }

  void _navigateToBreadcrumb(int index) {
    if (index < breadcrumbs.length - 1) {
      setState(() {
        breadcrumbs = breadcrumbs.sublist(0, index + 1);
      });
      _loadFolder(breadcrumbs.last.path);
    }
  }

  void _openFolderBrowser() {
    if (useDropbox) {
      setState(() {
        showFolderBrowser = true;
      });
    } else {
      // For local mode, open file picker directly
      _pickLocalPdf();
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _openPdfFromDropbox(DropboxItem pdf) async {
    if (dropboxService == null) return;

    final existingIndex = openTabs.indexWhere(
      (tab) => tab.dropboxPath == pdf.path,
    );
    if (existingIndex != -1) {
      setState(() {
        currentTabIndex = existingIndex;
        showFolderBrowser = false;
      });
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final file = await dropboxService!.downloadFile(pdf.path);
      if (!mounted) return;
      Navigator.of(context).pop();

      setState(() {
        openTabs.add(
          OpenPdfTab(
            pdfPath: file.path,
            title: pdf.name,
            dropboxPath: pdf.path,
          ),
        );
        currentTabIndex = openTabs.length - 1;
        showFolderBrowser = false;
      });
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      _showError('Failed to open PDF: $e');
    }
  }

  void closeTab(int index) {
    setState(() {
      if (openTabs.length > index) {
        openTabs.removeAt(index);
        if (currentTabIndex >= openTabs.length && openTabs.isNotEmpty) {
          currentTabIndex = openTabs.length - 1;
        }
        if (openTabs.isEmpty) {
          currentTabIndex = 0;
        }
      }
    });
  }

  Widget _buildBreadcrumbs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.folder_open_rounded,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (int i = 0; i < breadcrumbs.length; i++) ...[
                    InkWell(
                      onTap: () => _navigateToBreadcrumb(i),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: i == breadcrumbs.length - 1
                            ? BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                              )
                            : null,
                        child: Text(
                          breadcrumbs[i].name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: i == breadcrumbs.length - 1
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: i == breadcrumbs.length - 1
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ),
                    if (i < breadcrumbs.length - 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: openTabs.length,
                itemBuilder: (context, index) {
                  final tab = openTabs[index];
                  final isSelected = index == currentTabIndex;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        setState(() {
                          currentTabIndex = index;
                          showFolderBrowser = false;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        constraints: const BoxConstraints(maxWidth: 220),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: isSelected && !showFolderBrowser
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                          border: Border.all(
                            color: isSelected && !showFolderBrowser
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.picture_as_pdf_rounded,
                              size: 16,
                              color: isSelected && !showFolderBrowser
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                tab.title,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.2,
                                  color: isSelected && !showFolderBrowser
                                      ? Theme.of(context).colorScheme.onPrimary
                                      : Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              borderRadius: BorderRadius.circular(999),
                              onTap: () => closeTab(index),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: isSelected && !showFolderBrowser
                                      ? Theme.of(context).colorScheme.onPrimary
                                            .withValues(alpha: 0.8)
                                      : Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          // New PDF Button
          Material(
            color: showFolderBrowser
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: _openFolderBrowser,
              child: Container(
                padding: const EdgeInsets.all(11),
                child: Icon(
                  Icons.add_rounded,
                  size: 22,
                  color: showFolderBrowser
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildGridView() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!useDropbox) {
      // For local mode, show empty state with "open file" button
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.picture_as_pdf,
                size: 64,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              const Text(
                'PDF dosyası açın',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                'Bir PDF dosyası seçmek için + butonuna tıklayın',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _pickLocalPdf,
                icon: const Icon(Icons.file_open),
                label: const Text('Dosya Seç'),
              ),
            ],
          ),
        ),
      );
    }

    if (folders.isEmpty && pdfs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.folder_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Bu klasör boş',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                'Dropbox\'a dosya veya klasör ekleyin',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _loadFolder(currentPath),
                icon: const Icon(Icons.refresh),
                label: const Text('Yenile'),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1.3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: folders.length + pdfs.length,
      itemBuilder: (context, index) {
        if (index < folders.length) {
          final folder = folders[index];
          return GestureDetector(
            onTap: () => _navigateToFolder(folder.path, folder.name),
            child: Card(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.folder_rounded,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      folder.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                        letterSpacing: -0.2,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
          );
        } else {
          final pdfIndex = index - folders.length;
          final pdf = pdfs[pdfIndex];
          return GestureDetector(
            onTap: () => _openPdfFromDropbox(pdf),
            child: Card(
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        child: DropboxPdfThumbnail(
                          key: ValueKey(pdf.path),
                          pdfPath: pdf.path,
                          dropboxService: dropboxService!,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    width: double.infinity,
                    child: Row(
                      children: [
                        Icon(
                          Icons.picture_as_pdf_rounded,
                          size: 16,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            pdf.name,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                              letterSpacing: -0.2,
                            ),
                            overflow: TextOverflow.ellipsis,
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
      },
    );
  }

  Widget _buildStorageSelectionScreen() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Dosya Kaynağı Seçin',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'PDF dosyalarınızı nereden açmak istersiniz?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 48),
            Card(
              child: InkWell(
                onTap: _selectLocalStorage,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.computer,
                          size: 32,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Yerel Dosyalar',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Bilgisayarınızdan PDF dosyası seçin',
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 20,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // const SizedBox(height: 16),
            // Card(
            //   child: InkWell(
            //     onTap: _selectDropboxStorage,
            //     borderRadius: BorderRadius.circular(16),
            //     child: Container(
            //       padding: const EdgeInsets.all(24),
            //       child: Row(
            //         children: [
            //           Container(
            //             padding: const EdgeInsets.all(16),
            //             decoration: BoxDecoration(
            //               color: Theme.of(context)
            //                   .colorScheme
            //                   .secondary
            //                   .withValues(alpha: 0.1),
            //               borderRadius: BorderRadius.circular(12),
            //             ),
            //             child: Icon(
            //               Icons.cloud,
            //               size: 32,
            //               color: Theme.of(context).colorScheme.secondary,
            //             ),
            //           ),
            //           const SizedBox(width: 20),
            //           Expanded(
            //             child: Column(
            //               crossAxisAlignment: CrossAxisAlignment.start,
            //               children: [
            //                 Text(
            //                   'Dropbox',
            //                   style: TextStyle(
            //                     fontSize: 18,
            //                     fontWeight: FontWeight.w700,
            //                     color: Theme.of(context).colorScheme.onSurface,
            //                   ),
            //                 ),
            //                 const SizedBox(height: 4),
            //                 Text(
            //                   'Dropbox hesabınızdan dosya açın',
            //                   style: TextStyle(
            //                     fontSize: 14,
            //                     color: Theme.of(context)
            //                         .colorScheme
            //                         .onSurfaceVariant,
            //                   ),
            //                 ),
            //               ],
            //             ),
            //           ),
            //           Icon(
            //             Icons.arrow_forward_ios,
            //             size: 20,
            //             color: Theme.of(context).colorScheme.onSurfaceVariant,
            //           ),
            //         ],
            //       ),
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (showStorageSelection) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Akilli Tahta Proje Demo'),
          actions: [
            IconButton(
              tooltip: 'Çıkış Yap',
              icon: const Icon(Icons.logout),
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => LoginPage(onLogin: (_, __) async => false),
                  ),
                  (route) => false,
                );
              },
            ),
          ],
        ),
        body: _buildStorageSelectionScreen(),
      );
    }

    return PopScope(
      canPop: openTabs.isEmpty,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && openTabs.isNotEmpty) {
          closeTab(currentTabIndex);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            useDropbox
                ? 'Akilli Tahta Proje Demo - Dropbox'
                : 'Akilli Tahta Proje Demo - Yerel',
          ),
          actions: [
            IconButton(
              tooltip: 'Yenile',
              icon: !isFullScreen
                  ? const Icon(Icons.fullscreen)
                  : const Icon(Icons.fullscreen_exit),
              onPressed: () => _makeFullscreen(),
            ),
            if (openTabs.isEmpty && !isLoading)
              IconButton(
                tooltip: 'Yenile',
                icon: const Icon(Icons.refresh),
                onPressed: () => _loadFolder(currentPath),
              ),
            IconButton(
              tooltip: 'Çıkış Yap',
              icon: const Icon(Icons.logout),
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => LoginPage(onLogin: (_, __) async => false),
                  ),
                  (route) => false,
                );
              },
            ),
            IconButton(
              tooltip: 'Kapat',
              icon: const Icon(Icons.close),
              onPressed: () {
                SystemChannels.platform.invokeMethod<void>(
                  'SystemNavigator.pop',
                );
                exit(0);
              },
            ),
          ],
        ),
        body: Column(
          children: [
            if (openTabs.isNotEmpty) _buildTabBar(),
            if ((openTabs.isEmpty || showFolderBrowser) && !isLoading)
              _buildBreadcrumbs(),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: openTabs.isEmpty || showFolderBrowser
                    ? _buildGridView()
                    : PdfDrawingViewerPage(
                        key: ValueKey(openTabs[currentTabIndex].pdfPath),
                        pdfPath: openTabs[currentTabIndex].pdfPath,
                        onBack: () => closeTab(currentTabIndex),
                        cropData: openTabs[currentTabIndex].cropData,
                        zipFilePath: openTabs[currentTabIndex].zipFilePath,
                        pdfBytes: openTabs[currentTabIndex].pdfBytes,
                        zipBytes: openTabs[currentTabIndex].zipBytes,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
