import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_io/io.dart';
import 'drawing_overlay_window.dart';

/// Sistem genelinde çalışan çizim overlay'ini yöneten singleton sınıf
class DrawingOverlayManager {
  static final DrawingOverlayManager _instance = DrawingOverlayManager._internal();
  factory DrawingOverlayManager() => _instance;
  DrawingOverlayManager._internal();

  bool _isActive = false;
  OverlayEntry? _overlayEntry;

  bool get isActive => _isActive;

  /// Desktop platformunda mı çalışıyoruz?
  bool get isDesktop => !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  /// Drawing overlay'i başlat
  void start(BuildContext context) {
    if (!isDesktop) {
      debugPrint('⚠️ Drawing overlay sadece desktop platformlarında çalışır');
      return;
    }

    if (_isActive) {
      debugPrint('⚠️ Drawing overlay zaten aktif');
      return;
    }

    _isActive = true;

    // Overlay oluştur
    _overlayEntry = OverlayEntry(
      builder: (context) => const DrawingOverlayWindow(),
    );

    // Overlay'i ekle
    Overlay.of(context).insert(_overlayEntry!);

    debugPrint('✅ Drawing overlay başlatıldı');
  }

  /// Drawing overlay'i durdur
  void stop() {
    if (!_isActive) {
      debugPrint('⚠️ Drawing overlay zaten kapalı');
      return;
    }

    _overlayEntry?.remove();
    _overlayEntry = null;
    _isActive = false;

    debugPrint('✅ Drawing overlay durduruldu');
  }

  /// Drawing overlay'i aç/kapat
  void toggle(BuildContext context) {
    if (_isActive) {
      stop();
    } else {
      start(context);
    }
  }

  /// Temizle
  void dispose() {
    stop();
  }
}
