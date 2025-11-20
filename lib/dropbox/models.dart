import 'dart:typed_data';
import '../models/crop_data.dart';

class OpenPdfTab {
  final String pdfPath;
  final String title;
  final String? dropboxPath;
  final CropData? cropData;
  final String? zipFilePath; // Zip dosyasının yolu (crop resimleri için)
  final Uint8List? pdfBytes; // Web platformu için PDF bytes
  final Uint8List? zipBytes; // Web platformu için ZIP bytes

  OpenPdfTab({
    required this.pdfPath,
    required this.title,
    this.dropboxPath,
    this.cropData,
    this.zipFilePath,
    this.pdfBytes,
    this.zipBytes,
  });
}

class BreadcrumbItem {
  final String name;
  final String path;

  BreadcrumbItem({required this.name, required this.path});
}