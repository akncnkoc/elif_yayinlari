import 'package:flutter/material.dart';
import '../services/virtual_keyboard_service.dart';

/// Uygulama içi sanal klavye widget'ı
class VirtualKeyboard extends StatefulWidget {
  const VirtualKeyboard({super.key});

  @override
  State<VirtualKeyboard> createState() => _VirtualKeyboardState();
}

class _VirtualKeyboardState extends State<VirtualKeyboard> {
  bool _isShiftPressed = false;
  bool _isCapsLock = false;

  // Türkçe Q klavye düzeni
  final List<List<String>> _keyboardLayout = [
    ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '*', '-'],
    ['q', 'w', 'e', 'r', 't', 'y', 'u', 'ı', 'o', 'p', 'ğ', 'ü'],
    ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', 'ş', 'i'],
    ['z', 'x', 'c', 'v', 'b', 'n', 'm', 'ö', 'ç', '.', ','],
  ];

  // Shift basılıyken karakterler
  final Map<String, String> _shiftMap = {
    '1': '!',
    '2': '\'',
    '3': '^',
    '4': '+',
    '5': '%',
    '6': '&',
    '7': '/',
    '8': '(',
    '9': ')',
    '0': '=',
    '*': '?',
    '-': '_',
    '.': ':',
    ',': ';',
  };

  String _getKeyLabel(String key) {
    if (_isShiftPressed || _isCapsLock) {
      // Sayılar ve özel karakterler için shift map
      if (_shiftMap.containsKey(key)) {
        return _shiftMap[key]!;
      }
      // Harfler için büyük harf
      return key.toUpperCase();
    }
    return key;
  }

  void _onKeyTap(String key) {
    final service = VirtualKeyboardService();
    final displayKey = _getKeyLabel(key);
    service.onKeyPressed(displayKey);

    // Shift tek seferlik, caps lock kalıcı
    if (_isShiftPressed && !_isCapsLock) {
      setState(() {
        _isShiftPressed = false;
      });
    }
  }

  void _toggleShift() {
    setState(() {
      _isShiftPressed = !_isShiftPressed;
      _isCapsLock = false;
    });
  }

  void _toggleCapsLock() {
    setState(() {
      _isCapsLock = !_isCapsLock;
      _isShiftPressed = _isCapsLock;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.98),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              0.1,
            ), // Reduced opacity for performance
            blurRadius: 10, // Reduced blur for performance
            offset: const Offset(0, -2),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Klavye tuşları
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Ekran genişliğine göre tuş boyutunu ayarla veya scrol edilebilir yap
                  // En basit çözüm: Sığmıyorsa scroll etsin
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: constraints.maxWidth,
                      ),
                      child: Column(
                        children: [
                          // Harf satırları
                          ..._keyboardLayout.map((row) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: row.map((key) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 2,
                                    ),
                                    child: _KeyButton(
                                      label: _getKeyLabel(key),
                                      onTap: () => _onKeyTap(key),
                                    ),
                                  );
                                }).toList(),
                              ),
                            );
                          }),

                          // Alt satır: Shift, Space, Backspace, Enter
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Shift
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                  ),
                                  child: _SpecialKeyButton(
                                    icon: Icons.arrow_upward,
                                    width: 60,
                                    isActive: _isShiftPressed,
                                    onTap: _toggleShift,
                                    onLongPress:
                                        _toggleCapsLock, // Long press for Caps Lock
                                  ),
                                ),

                                // Space
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                  ),
                                  child: _KeyButton(
                                    label: 'Space',
                                    width: 200,
                                    onTap: () => VirtualKeyboardService()
                                        .onKeyPressed(' '),
                                  ),
                                ),

                                // Backspace
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                  ),
                                  child: _SpecialKeyButton(
                                    icon: Icons.backspace_outlined,
                                    width: 60,
                                    onTap: () => VirtualKeyboardService()
                                        .onKeyPressed('⌫'),
                                  ),
                                ),

                                // Enter/Close
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                  ),
                                  child: _SpecialKeyButton(
                                    icon: Icons.keyboard_hide,
                                    width: 60,
                                    color: theme.colorScheme.primary,
                                    onTap: () =>
                                        VirtualKeyboardService().hide(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Normal tuş butonu
class _KeyButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final double? width;

  const _KeyButton({required this.label, required this.onTap, this.width});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Use pure InkWell on Material for better performance
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: onTap,
        canRequestFocus: false,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          // Replaced Container with SizedBox for potential minor perf gain
          width: width ?? 40,
          height: 45,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Özel tuş butonu (icon'lu)
class _SpecialKeyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onLongPress;
  final double? width;
  final bool isActive;
  final Color? color;

  const _SpecialKeyButton({
    required this.icon,
    required this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.width,
    this.isActive = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonColor =
        color ??
        (isActive
            ? theme.colorScheme.primary
            : theme.colorScheme.surfaceContainerHighest);

    return Material(
      color: buttonColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: onTap,
        onDoubleTap: onDoubleTap,
        onLongPress: onLongPress,
        canRequestFocus: false,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: width ?? 40,
          height: 45,
          child: Center(
            child: Icon(
              icon,
              size: 20,
              color: isActive || color != null
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
