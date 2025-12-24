import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/crop_data.dart';
import '../models/page_content.dart';

class BookResult {
  final String pdfPath;
  final CropData? cropData;
  final PageContent? pageContent;
  final String? zipFilePath; // Original zip path

  BookResult({
    required this.pdfPath,
    this.cropData,
    this.pageContent,
    this.zipFilePath,
  });
}

class BookOpeningService {
  /// Opens a book (zip) in a separate isolate.
  ///
  /// Returns a [BookResult] containing the paths and parsed data.
  /// Throws an exception if opening fails.
  static Future<BookResult> openBook(String zipPath) async {
    // We need a temp directory. This must be passed to the isolate because
    // getTemporaryDirectory() is a platform channel call (main isolate only usually).
    // Actually, getTemporaryDirectory is channel based, so invoke it here.
    final tempDir = await getTemporaryDirectory();
    final tempPath = tempDir.path;

    // Use compute to spawn an isolate
    return compute(_isolateOpenBook, _IsolateParams(zipPath, tempPath));
  }

  /// The entry point for the isolate.
  static Future<BookResult> _isolateOpenBook(_IsolateParams params) async {
    final zipFile = File(params.zipPath);
    if (!await zipFile.exists()) {
      throw Exception('Zip file not found: ${params.zipPath}');
    }

    final bytes = await zipFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    ArchiveFile? cropCoordinatesJson;
    ArchiveFile? pageContentsJson;
    ArchiveFile? originalPdf; // Keep as fallback

    // 1. Scan archive for key files
    for (final file in archive) {
      final lowerName = file.name.toLowerCase();
      if (lowerName.endsWith('crop_coordinates.json')) {
        cropCoordinatesJson = file;
      } else if (lowerName.endsWith('page_contents.json')) {
        pageContentsJson = file;
      } else if (lowerName == 'original.pdf') {
        originalPdf = file;
      }
    }

    CropData? cropData;
    String? dynamicPdfName;

    // Parse crop coordinates data if available
    if (cropCoordinatesJson != null) {
      try {
        final jsonString = utf8.decode(
          cropCoordinatesJson.content as List<int>,
        );
        cropData = CropData.fromJsonString(jsonString);
        if (cropData.pdfFile.isNotEmpty) {
          dynamicPdfName = cropData.pdfFile;
        }
      } catch (e) {
        // print('Error parsing crop coordinates: $e');
      }
    }

    // 2. Locate the PDF file
    ArchiveFile? targetPdfFile;

    // Try finding the dynamic PDF name from JSON
    if (dynamicPdfName != null) {
      for (final file in archive) {
        if (file.name == dynamicPdfName) {
          targetPdfFile = file;
          break;
        }
      }
      // Normalize match (case insensitive try)
      if (targetPdfFile == null) {
        for (final file in archive) {
          if (file.name.toLowerCase() == dynamicPdfName.toLowerCase()) {
            targetPdfFile = file;
            break;
          }
        }
      }
    }

    // Fallback to original.pdf
    if (targetPdfFile == null) {
      targetPdfFile = originalPdf;
    }

    // Ultimate fallback: first PDF found
    if (targetPdfFile == null) {
      for (final file in archive) {
        if (file.name.toLowerCase().endsWith('.pdf')) {
          targetPdfFile = file;
          break;
        }
      }
    }

    if (targetPdfFile == null) {
      throw Exception(
        'No PDF file found in book archive (expected $dynamicPdfName or original.pdf)',
      );
    }

    // Extract the PDF to a temporary location
    // Use the actual filename if possible, otherwise a timestamped fallback, but sanitize it
    final safePdfName = targetPdfFile.name.replaceAll(RegExp(r'[^\w\.-]'), '_');
    final pdfPath =
        '${params.tempPath}/${DateTime.now().millisecondsSinceEpoch}_$safePdfName';

    final pdfFile = File(pdfPath);
    await pdfFile.writeAsBytes(targetPdfFile.content as List<int>);

    // Parse page contents if available
    PageContent? pageContent;
    if (pageContentsJson != null) {
      try {
        final jsonString = utf8.decode(pageContentsJson.content as List<int>);
        pageContent = PageContent.fromJsonString(jsonString);
      } catch (e) {
        // print('Error parsing page contents: $e');
      }
    }

    return BookResult(
      pdfPath: pdfPath,
      cropData: cropData,
      pageContent: pageContent,
      zipFilePath: params.zipPath,
    );
  }
}

class _IsolateParams {
  final String zipPath;
  final String tempPath;

  _IsolateParams(this.zipPath, this.tempPath);
}
