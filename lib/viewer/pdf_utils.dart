import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

Future<String> resolvePdfPath(String pdfPath) async {
  // If already a file path, return directly
  if (pdfPath.contains(':\\') || pdfPath.startsWith('/')) {
    return pdfPath;
  }

  // If it's an asset, copy it to a temp file
  final bytes = await rootBundle.load(pdfPath);
  final file = File('${(await getTemporaryDirectory()).path}/$pdfPath');
  await file.create(recursive: true);
  await file.writeAsBytes(
    bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
  );
  return file.path;
}
