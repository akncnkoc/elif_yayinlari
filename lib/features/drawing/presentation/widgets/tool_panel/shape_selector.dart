import 'package:flutter/material.dart';
import '../../../../../viewer/tool_state.dart';

/// Shape selector component
class ShapeSelector extends StatelessWidget {
  final ShapeType selectedShape;
  final Function(ShapeType) onShapeSelected;

  const ShapeSelector({
    super.key,
    required this.selectedShape,
    required this.onShapeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Şekil Seç',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _ShapeButton(
              shapeType: ShapeType.rectangle,
              icon: Icons.crop_square,
              label: 'Dikdörtgen',
              isSelected: selectedShape == ShapeType.rectangle,
              onTap: () => onShapeSelected(ShapeType.rectangle),
              selectedColor: scheme.primary,
            ),
            _ShapeButton(
              shapeType: ShapeType.circle,
              icon: Icons.circle_outlined,
              label: 'Daire',
              isSelected: selectedShape == ShapeType.circle,
              onTap: () => onShapeSelected(ShapeType.circle),
              selectedColor: scheme.primary,
            ),
            _ShapeButton(
              shapeType: ShapeType.line,
              icon: Icons.remove,
              label: 'Çizgi',
              isSelected: selectedShape == ShapeType.line,
              onTap: () => onShapeSelected(ShapeType.line),
              selectedColor: scheme.primary,
            ),
            _ShapeButton(
              shapeType: ShapeType.arrow,
              icon: Icons.arrow_forward,
              label: 'Ok',
              isSelected: selectedShape == ShapeType.arrow,
              onTap: () => onShapeSelected(ShapeType.arrow),
              selectedColor: scheme.primary,
            ),
          ],
        ),
      ],
    );
  }
}

class _ShapeButton extends StatelessWidget {
  final ShapeType shapeType;
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color selectedColor;

  const _ShapeButton({
    required this.shapeType,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: label,
      child: Material(
        color: isSelected
            ? scheme.primaryContainer.withValues(alpha: 0.3)
            : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 64,
            height: 56,
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? selectedColor : scheme.onSurface,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: isSelected ? selectedColor : scheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
