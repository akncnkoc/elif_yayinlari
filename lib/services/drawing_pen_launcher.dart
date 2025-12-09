import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as path;

/// Çizim kalemi uygulamasını ayrı bir process olarak başlatır
class DrawingPenLauncher {
  static Process? _process;

  /// Çizim kalemi açık mı?
  static bool get isRunning => _process != null;

  /// Desktop platformunda mı?
  static bool get isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  /// Çizim kalemini başlat
  static Future<bool> launch() async {
    if (!isDesktop) {
      debugPrint('⚠️ Çizim kalemi sadece desktop platformlarında çalışır');
      return false;
    }

    if (isRunning) {
      debugPrint('⚠️ Çizim kalemi zaten çalışıyor');
      return false;
    }

    try {
      // Flutter executable path'i bul
      String executable;
      List<String> arguments;

      if (Platform.isWindows) {
        // Windows'ta build edilmiş executable kullan
        final buildPath = path.join(
          Directory.current.path,
          'build',
          'windows',
          'x64',
          'runner',
          'Release',
          'akilli_tahta_proje_demo.exe',
        );

        if (File(buildPath).existsSync()) {
          // Build edilmiş exe var, onu kullan
          executable = buildPath;
          arguments = ['--drawing-pen'];
        } else {
          // Development mode - flutter run kullan
          executable = 'flutter';
          arguments = [
            'run',
            '-d',
            'windows',
            '-t',
            'lib/drawing_pen_main.dart',
          ];
        }
      } else if (Platform.isLinux) {
        executable = 'flutter';
        arguments = [
          'run',
          '-d',
          'linux',
          '-t',
          'lib/drawing_pen_main.dart',
        ];
      } else if (Platform.isMacOS) {
        executable = 'flutter';
        arguments = [
          'run',
          '-d',
          'macos',
          '-t',
          'lib/drawing_pen_main.dart',
        ];
      } else {
        return false;
      }

      debugPrint('🚀 Çizim kalemi başlatılıyor: $executable ${arguments.join(' ')}');

      _process = await Process.start(
        executable,
        arguments,
        mode: ProcessStartMode.detached,
      );

      debugPrint('✅ Çizim kalemi başlatıldı (PID: ${_process!.pid})');
      return true;
    } catch (e) {
      debugPrint('❌ Çizim kalemi başlatılamadı: $e');
      return false;
    }
  }

  /// Çizim kalemini kapat
  static Future<void> stop() async {
    if (_process != null) {
      _process!.kill();
      _process = null;
      debugPrint('✅ Çizim kalemi kapatıldı');
    }
  }

  static void debugPrint(String message) {
    if (kIsWeb) return;
    print(message);
  }
}
