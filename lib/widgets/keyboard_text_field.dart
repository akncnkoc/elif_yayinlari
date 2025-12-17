import 'package:flutter/material.dart';
import '../services/virtual_keyboard_service.dart';

/// TextField wrapper that automatically shows virtual keyboard
class KeyboardTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final InputDecoration? decoration;
  final bool autofocus;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onSubmitted;
  final bool useVirtualKeyboard;
  final int? maxLines;

  const KeyboardTextField({
    super.key,
    this.controller,
    this.hintText,
    this.decoration,
    this.autofocus = false,
    this.keyboardType,
    this.onSubmitted,
    this.useVirtualKeyboard = true,
    this.maxLines = 1,
  });

  @override
  State<KeyboardTextField> createState() => _KeyboardTextFieldState();
}

class _KeyboardTextFieldState extends State<KeyboardTextField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = FocusNode();

    // Focus değişikliklerini dinle
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    if (widget.controller == null) {
      _controller.dispose();
    }
    // Widget kapandığında klavyeyi de kapat
    if (_focusNode.hasFocus) {
      VirtualKeyboardService().hide();
    }
    super.dispose();
  }

  void _handleFocusChange() {
    if (widget.useVirtualKeyboard) {
      if (_focusNode.hasFocus) {
        // TextField'a focus olduğunda virtual keyboard'u göster
        VirtualKeyboardService().show(
          controller: _controller,
          focusNode: _focusNode,
        );
      } else {
        // Focus kaybolduğunda keyboard'u gizle
        // VirtualKeyboardService().hide(); // REMOVED: Clicking the keyboard itself causes focus loss
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      keyboardType: widget.keyboardType,
      onSubmitted: widget.onSubmitted,
      maxLines: widget.maxLines,
      // Sistem klavyesini devre dışı bırak
      readOnly: widget.useVirtualKeyboard,
      showCursor: true, // Cursor'ı her zaman göster
      decoration:
          widget.decoration ??
          InputDecoration(
            hintText: widget.hintText,
            border: const OutlineInputBorder(),
          ),
    );
  }
}
