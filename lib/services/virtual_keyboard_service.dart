import 'package:flutter/material.dart';

/// Virtual keyboard yönetimi için servis
class VirtualKeyboardService extends ChangeNotifier {
  static final VirtualKeyboardService _instance =
      VirtualKeyboardService._internal();

  factory VirtualKeyboardService() => _instance;

  VirtualKeyboardService._internal();

  bool _isVisible = false;
  TextEditingController? _currentController;
  FocusNode? _currentFocusNode;

  bool get isVisible => _isVisible;
  TextEditingController? get currentController => _currentController;

  /// Klavyeyi göster
  void show({required TextEditingController controller, FocusNode? focusNode}) {
    _currentController = controller;
    _currentFocusNode = focusNode;
    _isVisible = true;
    notifyListeners();
  }

  /// Klavyeyi gizle
  void hide() {
    _currentController = null;
    _currentFocusNode?.unfocus();
    _currentFocusNode = null;
    _isVisible = false;
    notifyListeners();
  }

  /// Tuşa basıldığında
  void onKeyPressed(String key) {
    if (_currentController == null) return;

    final text = _currentController!.text;
    final selection = _currentController!.selection;

    if (key == '⌫') {
      // Backspace
      if (selection.start > 0) {
        final newText =
            text.substring(0, selection.start - 1) +
            text.substring(selection.end);
        _currentController!.text = newText;
        _currentController!.selection = TextSelection.collapsed(
          offset: selection.start - 1,
        );
      }
    } else if (key == '↵') {
      // Enter - klavyeyi kapat
      hide();
    } else {
      // Normal karakter
      final newText =
          text.substring(0, selection.start) +
          key +
          text.substring(selection.end);
      _currentController!.text = newText;
      _currentController!.selection = TextSelection.collapsed(
        offset: selection.start + key.length,
      );
    }
  }
}
