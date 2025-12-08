import 'dart:io';
import 'package:path/path.dart' as path;

class FileUtils {
  FileUtils._();

  static String getExtension(String filePath) {
    return path.extension(filePath).toLowerCase();
  }

  static String getFileNameWithoutExtension(String filePath) {
    return path.basenameWithoutExtension(filePath);
  }

  static String getFileName(String filePath) {
    return path.basename(filePath);
  }

  static bool isPdf(String filePath) {
    return getExtension(filePath) == '.pdf';
  }

  static bool isBookFile(String filePath) {
    return getExtension(filePath) == '.book';
  }

  static Future<bool> fileExists(String filePath) async {
    return await File(filePath).exists();
  }

  static Future<bool> directoryExists(String dirPath) async {
    return await Directory(dirPath).exists();
  }

  static Future<void> ensureDirectoryExists(String dirPath) async {
    final dir = Directory(dirPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  static Future<void> deleteFileIfExists(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  static String getParentDirectory(String filePath) {
    return path.dirname(filePath);
  }

  static String joinPaths(List<String> components) {
    return path.joinAll(components);
  }

  static String normalizePath(String filePath) {
    return path.normalize(filePath);
  }
}
