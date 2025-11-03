import '../models/crop_data.dart';

class OpenPdfTab {
  final String pdfPath;
  final String title;
  final String? dropboxPath;
  final CropData? cropData;
  final String? zipFilePath; // Zip dosyasının yolu (crop resimleri için)

  OpenPdfTab({
    required this.pdfPath,
    required this.title,
    this.dropboxPath,
    this.cropData,
    this.zipFilePath,
  });
}

class BreadcrumbItem {
  final String name;
  final String path;

  BreadcrumbItem({required this.name, required this.path});
}