// version_checker.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';

class VersionChecker {
  static const String serverUrl = 'https://your-server.com/server.json';
  static const String currentVersion = '1.0.0'; // Update this with each release

  /// Check if a new version is available
  static Future<UpdateInfo?> checkForUpdate() async {
    try {
      final response = await http.get(Uri.parse(serverUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final serverVersion = data['version'] as String;
        final updateUrl = data['updateUrl'] as String;
        final mandatory = data['mandatory'] as bool? ?? false;
        final releaseNotes = data['releaseNotes'] as String? ?? '';

        if (_isNewerVersion(serverVersion, currentVersion)) {
          return UpdateInfo(
            version: serverVersion,
            updateUrl: updateUrl,
            mandatory: mandatory,
            releaseNotes: releaseNotes,
          );
        }
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
    }
    return null;
  }

  /// Compare version strings (e.g., "1.2.3" vs "1.2.4")
  static bool _isNewerVersion(String serverVersion, String currentVersion) {
    final serverParts = serverVersion.split('.').map(int.parse).toList();
    final currentParts = currentVersion.split('.').map(int.parse).toList();

    for (int i = 0; i < 3; i++) {
      if (serverParts[i] > currentParts[i]) return true;
      if (serverParts[i] < currentParts[i]) return false;
    }
    return false;
  }

  /// Download and install update
  static Future<bool> downloadAndInstall(
    String updateUrl,
    Function(double) onProgress,
  ) async {
    try {
      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final downloadPath = '${tempDir.path}/update.zip';

      // Download the update file
      final response = await http.Client().send(
        http.Request('GET', Uri.parse(updateUrl)),
      );

      final totalBytes = response.contentLength ?? 0;
      int receivedBytes = 0;

      final file = File(downloadPath);
      final sink = file.openWrite();

      await for (var chunk in response.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0) {
          onProgress(receivedBytes / totalBytes);
        }
      }

      await sink.close();

      // Extract the archive
      final appDir = await getApplicationDocumentsDirectory();
      final updateDir = Directory('${appDir.path}/update');

      if (await updateDir.exists()) {
        await updateDir.delete(recursive: true);
      }
      await updateDir.create(recursive: true);

      // Unzip the downloaded file
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      for (final file in archive) {
        final filename = '${updateDir.path}/${file.name}';
        if (file.isFile) {
          final outFile = File(filename);
          await outFile.create(recursive: true);
          await outFile.writeAsBytes(file.content as List<int>);
        } else {
          await Directory(filename).create(recursive: true);
        }
      }

      // Clean up
      await File(downloadPath).delete();

      return true;
    } catch (e) {
      debugPrint('Error downloading update: $e');
      return false;
    }
  }

  /// Apply the update and restart the app
  static Future<void> applyUpdateAndRestart() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final updateDir = Directory('${appDir.path}/update');

      if (await updateDir.exists()) {
        // Get the executable path
        final executablePath = Platform.resolvedExecutable;
        final executableDir = File(executablePath).parent.path;

        // Copy all files from update directory to executable directory
        await for (var entity in updateDir.list(recursive: true)) {
          if (entity is File) {
            final relativePath = entity.path.replaceFirst(updateDir.path, '');
            final targetPath = '$executableDir$relativePath';
            final targetFile = File(targetPath);

            await targetFile.create(recursive: true);
            await entity.copy(targetPath);
          }
        }

        // Clean up update directory
        await updateDir.delete(recursive: true);

        // Restart the application
        if (Platform.isWindows) {
          await Process.start('cmd', [
            '/c',
            'timeout',
            '2',
            '&&',
            executablePath,
          ], mode: ProcessStartMode.detached);
        } else if (Platform.isLinux || Platform.isMacOS) {
          await Process.start('sh', [
            '-c',
            'sleep 2 && "$executablePath"',
          ], mode: ProcessStartMode.detached);
        }

        // Exit current instance
        exit(0);
      }
    } catch (e) {
      debugPrint('Error applying update: $e');
      rethrow;
    }
  }
}

class UpdateInfo {
  final String version;
  final String updateUrl;
  final bool mandatory;
  final String releaseNotes;

  UpdateInfo({
    required this.version,
    required this.updateUrl,
    required this.mandatory,
    required this.releaseNotes,
  });
}
