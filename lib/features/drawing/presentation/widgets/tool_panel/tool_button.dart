import 'package:flutter/material.dart';

/// Reusable tool button for the drawing panel
class ToolButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isSelected;
  final VoidCallback onPressed;
  final Color? selectedColor;
  final double size;
  final EdgeInsets padding;

  const ToolButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.isSelected,
    required this.onPressed,
    this.selectedColor,
    this.size = 48.0,
    this.padding = const EdgeInsets.all(8),
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final effectiveColor = isSelected ? (selectedColor ?? scheme.primary) : null;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: isSelected
            ? scheme.primaryContainer.withValues(alpha: 0.3)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: size,
            height: size,
            padding: padding,
            child: Icon(
              icon,
              size: 24,
              color: effectiveColor,
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact version for collapsed panel
class ToolButtonCompact extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isSelected;
  final VoidCallback onPressed;
  final Color? selectedColor;

  const ToolButtonCompact({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.isSelected,
    required this.onPressed,
    this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final effectiveColor = isSelected ? (selectedColor ?? scheme.primary) : null;

    return IconButton(
      icon: Icon(
        icon,
        size: 18,
        color: effectiveColor,
      ),
      onPressed: onPressed,
      tooltip: tooltip,
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(),
    );
  }
}
