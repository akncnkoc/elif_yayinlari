import 'package:flutter/material.dart';

/// Draggable panel header component
class PanelHeader extends StatelessWidget {
  final bool isCollapsed;
  final bool isPinned;
  final VoidCallback onTogglePin;
  final VoidCallback onCollapse;
  final VoidCallback? onExpand;
  final String title;

  const PanelHeader({
    super.key,
    required this.isCollapsed,
    required this.isPinned,
    required this.onTogglePin,
    required this.onCollapse,
    this.onExpand,
    this.title = 'Araç Paneli',
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: isCollapsed
          ? _CollapsedHeader(onExpand: onExpand, scheme: scheme)
          : _ExpandedHeader(
              title: title,
              isPinned: isPinned,
              onTogglePin: onTogglePin,
              onCollapse: onCollapse,
            ),
    );
  }
}

class _CollapsedHeader extends StatelessWidget {
  final VoidCallback? onExpand;
  final ColorScheme scheme;

  const _CollapsedHeader({
    required this.onExpand,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    if (onExpand != null) {
      return GestureDetector(
        onTap: onExpand,
        child: Center(
          child: Icon(
            Icons.drag_indicator,
            size: 20,
            color: scheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Center(
      child: Icon(
        Icons.drag_indicator,
        size: 20,
        color: scheme.onSurfaceVariant,
      ),
    );
  }
}

class _ExpandedHeader extends StatelessWidget {
  final String title;
  final bool isPinned;
  final VoidCallback onTogglePin;
  final VoidCallback onCollapse;

  const _ExpandedHeader({
    required this.title,
    required this.isPinned,
    required this.onTogglePin,
    required this.onCollapse,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pin button
            IconButton(
              icon: Icon(
                isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                size: 18,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: onTogglePin,
              tooltip: isPinned ? 'Sabitlemeyi Kaldır' : 'Sabitle',
            ),
            const SizedBox(width: 4),
            // Collapse button
            IconButton(
              icon: const Icon(Icons.remove, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: onCollapse,
              tooltip: 'Küçült',
            ),
          ],
        ),
      ],
    );
  }
}
