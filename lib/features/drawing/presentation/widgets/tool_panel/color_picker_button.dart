import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

/// Color picker button component
class ColorPickerButton extends StatelessWidget {
  final Color currentColor;
  final Function(Color) onColorChanged;
  final double size;

  const ColorPickerButton({
    super.key,
    required this.currentColor,
    required this.onColorChanged,
    this.size = 40.0,
  });

  void _showColorPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        Color tempColor = currentColor;
        return AlertDialog(
          title: const Text('Renk Seçin'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: currentColor,
              onColorChanged: (Color color) {
                tempColor = color;
              },
              pickerAreaHeightPercent: 0.8,
              displayThumbColor: true,
              enableAlpha: false,
              labelTypes: const [],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('İptal'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('Seç'),
              onPressed: () {
                onColorChanged(tempColor);
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Renk Seç',
      child: InkWell(
        onTap: () => _showColorPicker(context),
        borderRadius: BorderRadius.circular(size / 2),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: currentColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(context).colorScheme.outline,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Grid of preset colors for quick selection
class ColorGrid extends StatelessWidget {
  final Color currentColor;
  final Function(Color) onColorChanged;
  final List<Color> colors;

  const ColorGrid({
    super.key,
    required this.currentColor,
    required this.onColorChanged,
    this.colors = const [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.brown,
      Colors.black,
      Colors.grey,
    ],
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: colors.map((color) {
        final isSelected = color == currentColor;
        return GestureDetector(
          onTap: () => onColorChanged(color),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline,
                width: isSelected ? 3 : 1,
              ),
            ),
            child: isSelected
                ? const Icon(
                    Icons.check,
                    size: 16,
                    color: Colors.white,
                  )
                : null,
          ),
        );
      }).toList(),
    );
  }
}
