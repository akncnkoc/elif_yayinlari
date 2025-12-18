import 'dart:typed_data';
import 'crop_data.dart';
import 'page_content.dart';

class OpenPdfTab {
  final String pdfPath;
  final String title;
  final String? dropboxPath; // Also used for Google Drive with 'gdrive:' prefix
  final CropData? cropData;
  final String? zipFilePath;
  final Uint8List? pdfBytes;
  final Uint8List? zipBytes;
  final PageContent? pageContent; // [NEW]

  OpenPdfTab({
    required this.pdfPath,
    required this.title,
    this.dropboxPath,
    this.cropData,
    this.zipFilePath,
    this.pdfBytes,
    this.zipBytes,
    this.pageContent,
  });
}

class BreadcrumbItem {
  final String name;
  final String path;

  BreadcrumbItem({required this.name, required this.path});
}
