import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:path_provider/path_provider.dart';
import 'google_drive_auth.dart';
import 'models.dart';

class GoogleDriveService {
  final GoogleDriveAuth _auth = GoogleDriveAuth();
  bool _isInitialized = false;

  // Initialize the service (this will also initialize auth)
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _auth.initialize();
      _isInitialized = true;
      debugPrint('✅ GoogleDriveService initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize GoogleDriveService: $e');
      rethrow;
    }
  }

  // Check if service is ready
  bool get isReady => _isInitialized && _auth.isAuthenticated;

  // List files and folders in a specific folder (or root if folderId is null)
  Future<List<DriveItem>> listFiles({String? folderId}) async {
    try {
      // Ensure service is initialized
      if (!_isInitialized) {
        await initialize();
      }

      debugPrint('========================================');
      debugPrint(
        '📂 Listing Google Drive files in folder: ${folderId ?? "root"}',
      );

      final driveApi = _auth.getDriveApi();
      if (driveApi == null) {
        throw Exception(
          'Not authenticated. Service account initialization failed.',
        );
      }

      // Build query to get files
      String query = '';
      if (folderId != null) {
        query = "'$folderId' in parents and trashed = false";
      } else {
        query = "'root' in parents and trashed = false";
      }

      // List files
      final fileList = await driveApi.files.list(
        q: query,
        spaces: 'drive',
        $fields: 'files(id, name, mimeType, size)',
        orderBy: 'folder,name',
      );

      final items =
          fileList.files
              ?.map(
                (file) => DriveItem.fromJson({
                  'id': file.id,
                  'name': file.name,
                  'mimeType': file.mimeType,
                  'size': file.size,
                }),
              )
              .toList() ??
          [];

      debugPrint('✅ Found ${items.length} items');
      debugPrint('========================================');
      return items;
    } catch (e) {
      debugPrint('❌ Error listing files: $e');
      debugPrint('========================================');
      rethrow;
    }
  }

  // Search for .book files specifically
  Future<List<DriveItem>> searchBookFiles() async {
    try {
      // Ensure service is initialized
      if (!_isInitialized) {
        await initialize();
      }

      debugPrint('🔍 Searching for .book files in Google Drive');

      final driveApi = _auth.getDriveApi();
      if (driveApi == null) {
        throw Exception(
          'Not authenticated. Service account initialization failed.',
        );
      }

      // Search for files ending with .book
      final query = "name contains '.book' and trashed = false";

      final fileList = await driveApi.files.list(
        q: query,
        spaces: 'drive',
        $fields: 'files(id, name, mimeType, size)',
        orderBy: 'name',
      );

      final items =
          fileList.files
              ?.map(
                (file) => DriveItem.fromJson({
                  'id': file.id,
                  'name': file.name,
                  'mimeType': file.mimeType,
                  'size': file.size,
                }),
              )
              .where((item) => item.isBook)
              .toList() ??
          [];

      debugPrint('✅ Found ${items.length} .book files');
      return items;
    } catch (e) {
      debugPrint('❌ Error searching book files: $e');
      rethrow;
    }
  }

  // Download a file from Google Drive
  Future<File> downloadFile(String fileId, String fileName) async {
    try {
      // Ensure service is initialized
      if (!_isInitialized) {
        await initialize();
      }

      debugPrint('⬇️ Downloading file: $fileName (ID: $fileId)');

      final driveApi = _auth.getDriveApi();
      if (driveApi == null) {
        throw Exception(
          'Not authenticated. Service account initialization failed.',
        );
      }

      // Get file content
      final drive.Media media =
          await driveApi.files.get(
                fileId,
                downloadOptions: drive.DownloadOptions.fullMedia,
              )
              as drive.Media;

      // Save to temporary directory
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/$fileName';
      final file = File(filePath);

      // Write bytes to file
      final bytes = <int>[];
      await for (var chunk in media.stream) {
        bytes.addAll(chunk);
      }
      await file.writeAsBytes(bytes);

      debugPrint('✅ File downloaded successfully: $filePath');
      return file;
    } catch (e) {
      debugPrint('❌ Download error: $e');
      rethrow;
    }
  }

  // Download file and return bytes (for web platform)
  Future<Uint8List> downloadFileBytes(String fileId) async {
    try {
      // Ensure service is initialized
      if (!_isInitialized) {
        await initialize();
      }

      debugPrint('⬇️ Downloading file bytes (ID: $fileId)');

      final driveApi = _auth.getDriveApi();
      if (driveApi == null) {
        throw Exception(
          'Not authenticated. Service account initialization failed.',
        );
      }

      // Get file content
      final drive.Media media =
          await driveApi.files.get(
                fileId,
                downloadOptions: drive.DownloadOptions.fullMedia,
              )
              as drive.Media;

      // Collect bytes
      final bytes = <int>[];
      await for (var chunk in media.stream) {
        bytes.addAll(chunk);
      }

      debugPrint('✅ Downloaded ${bytes.length} bytes');
      return Uint8List.fromList(bytes);
    } catch (e) {
      debugPrint('❌ Download error: $e');
      rethrow;
    }
  }
}
