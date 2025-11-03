import 'dart:io';
import 'package:path/path.dart' as path;

/// Utility functions for file operations
class FileUtils {
  FileUtils._();

  /// Extracts the file extension from a path
  static String getExtension(String filePath) {
    return path.extension(filePath).toLowerCase();
  }

  /// Gets the file name without extension
  static String getFileNameWithoutExtension(String filePath) {
    return path.basenameWithoutExtension(filePath);
  }

  /// Gets the file name with extension
  static String getFileName(String filePath) {
    return path.basename(filePath);
  }

  /// Checks if a file is a PDF
  static bool isPdf(String filePath) {
    return getExtension(filePath) == '.pdf';
  }

  /// Checks if a file is a .book file
  static bool isBookFile(String filePath) {
    return getExtension(filePath) == '.book';
  }

  /// Checks if a file exists
  static Future<bool> fileExists(String filePath) async {
    return await File(filePath).exists();
  }

  /// Checks if a directory exists
  static Future<bool> directoryExists(String dirPath) async {
    return await Directory(dirPath).exists();
  }

  /// Creates a directory if it doesn't exist
  static Future<void> ensureDirectoryExists(String dirPath) async {
    final dir = Directory(dirPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  /// Deletes a file if it exists
  static Future<void> deleteFileIfExists(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Gets the parent directory path
  static String getParentDirectory(String filePath) {
    return path.dirname(filePath);
  }

  /// Joins path components
  static String joinPaths(List<String> components) {
    return path.joinAll(components);
  }

  /// Normalizes a path
  static String normalizePath(String filePath) {
    return path.normalize(filePath);
  }
}
