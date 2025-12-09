import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:window_manager/window_manager.dart';

/// Çizim kalemi uygulamasını ayrı bir process olarak başlatır
class DrawingPenLauncher {
  static Process? _process;

  /// Çizim kalemi açık mı?
  static bool get isRunning {
    if (_process == null) return false;

    // Process'in hala çalışıp çalışmadığını kontrol et
    try {
      // Windows'ta tasklist ile kontrol et
      if (Platform.isWindows) {
        final result = Process.runSync('tasklist', ['/FI', 'PID eq ${_process!.pid}']);
        if (!result.stdout.toString().contains('${_process!.pid}')) {
          _process = null;
          return false;
        }
      }
      return true;
    } catch (e) {
      _process = null;
      return false;
    }
  }

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
        // Debug veya Release build edilmiş exe kullan
        final debugPath = '${Directory.current.path}\\build\\windows\\x64\\runner\\Debug\\akilli_tahta_proje_demo.exe';
        final releasePath = '${Directory.current.path}\\build\\windows\\x64\\runner\\Release\\akilli_tahta_proje_demo.exe';

        if (File(debugPath).existsSync()) {
          executable = debugPath;
          arguments = ['--drawing-pen'];
        } else if (File(releasePath).existsSync()) {
          executable = releasePath;
          arguments = ['--drawing-pen'];
        } else {
          // Hiçbir exe bulunamadı
          debugPrint('❌ Hiçbir exe bulunamadı. Önce uygulamayı build edin.');
          return false;
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

      // Ana uygulamayı minimize et
      if (!kIsWeb) {
        // Önce fullscreen'den çık
        await windowManager.setFullScreen(false);
        // Sonra minimize et
        await windowManager.minimize();
        debugPrint('📦 Ana uygulama minimize edildi');
      }

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
