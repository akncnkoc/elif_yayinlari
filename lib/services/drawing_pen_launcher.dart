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
        final result = Process.runSync('tasklist', [
          '/FI',
          'PID eq ${_process!.pid}',
        ]);
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
      return false;
    }

    if (isRunning) {
      return false;
    }

    try {
      // Flutter executable path'i bul
      String executable;
      List<String> arguments;

      if (Platform.isWindows) {
        // Ana executable'ı --drawing-pen argümanı ile çalıştır
        final exeDir = Platform.resolvedExecutable;
        final exeDirPath = Directory(exeDir).parent.path;
        final mainExe = Platform.resolvedExecutable; // Şu anda çalışan exe

        // Ana exe'yi --drawing-pen ile çalıştır
        executable = mainExe;
        arguments = ['--drawing-pen'];
      } else if (Platform.isLinux) {
        executable = 'flutter';
        arguments = ['run', '-d', 'linux', '-t', 'lib/drawing_pen_main.dart'];
      } else if (Platform.isMacOS) {
        executable = 'flutter';
        arguments = ['run', '-d', 'macos', '-t', 'lib/drawing_pen_main.dart'];
      } else {
        return false;
      }

      _process = await Process.start(
        executable,
        arguments,
        mode: ProcessStartMode.detached,
      );

      // Ana uygulamayı minimize et
      if (!kIsWeb) {
        // Önce fullscreen'den çık
        await windowManager.setFullScreen(false);
        // Sonra minimize et
        await windowManager.minimize();
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Çizim kalemini kapat
  static Future<void> stop() async {
    if (_process != null) {
      _process!.kill();
      _process = null;
    }
  }

  static void debugPrint(String message) {
    if (kIsWeb) return;
  }
}
