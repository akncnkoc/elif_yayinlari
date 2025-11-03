import 'package:flutter/material.dart';

/// Undo/Redo buttons component
class UndoRedoButtons extends StatelessWidget {
  final bool canUndo;
  final bool canRedo;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final bool isCompact;

  const UndoRedoButtons({
    super.key,
    required this.canUndo,
    required this.canRedo,
    required this.onUndo,
    required this.onRedo,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.undo, size: 18),
            onPressed: canUndo ? onUndo : null,
            tooltip: 'Geri Al (Ctrl+Z)',
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
          ),
          IconButton(
            icon: const Icon(Icons.redo, size: 18),
            onPressed: canRedo ? onRedo : null,
            tooltip: 'Yinele (Ctrl+Y)',
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: canUndo ? onUndo : null,
            icon: const Icon(Icons.undo, size: 18),
            label: const Text('Geri Al'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: canRedo ? onRedo : null,
            icon: const Icon(Icons.redo, size: 18),
            label: const Text('Yinele'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
      ],
    );
  }
}
