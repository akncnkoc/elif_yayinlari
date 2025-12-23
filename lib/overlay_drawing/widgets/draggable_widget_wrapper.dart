import 'package:flutter/material.dart';

class DraggableWidgetWrapper extends StatelessWidget {
  final Widget child;
  final String title;
  final VoidCallback onClose;
  final Function(DragUpdateDetails) onDragUpdate;
  final Function(DragUpdateDetails)? onResize; // [NEW] relative resize
  final Color headerColor;
  final double? width; // [NEW]
  final double? height; // [NEW]

  const DraggableWidgetWrapper({
    super.key,
    required this.child,
    required this.title,
    required this.onClose,
    required this.onDragUpdate,
    this.onResize,
    this.headerColor = Colors.blue,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    // If we have specific width/height, we use that.
    // If not, we fall back to IntrinsicWidth (for simple widgets).

    Widget contentStructure = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(4, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Important if no resizing
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          GestureDetector(
            onPanUpdate: onDragUpdate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: headerColor.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                border: Border(
                  bottom: BorderSide(color: headerColor.withOpacity(0.2)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.drag_indicator_rounded,
                        size: 16,
                        color: headerColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: headerColor.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  InkWell(
                    onTap: onClose,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content Body
          if (width != null && height != null)
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
                child: child,
              ),
            )
          else
            Flexible(
              child: child,
            ), // If no size, just let child determine size or fit
        ],
      ),
    );

    // If resizing is enabled, we MUST force a size on the container using SizedBox
    // and wrap in a Stack to add the resize handle.
    if (onResize != null && width != null && height != null) {
      return SizedBox(
        width: width,
        height: height,
        child: Stack(
          children: [
            Positioned.fill(child: contentStructure),

            // Resize Handle (Bottom Right)
            Positioned(
              right: 2,
              bottom: 2,
              child: GestureDetector(
                onPanUpdate: onResize,
                behavior: HitTestBehavior.translucent,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                    // Optional corner indicator
                  ),
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: Icon(
                      Icons.south_east_rounded,
                      size: 16,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Fallback for non-resizable widgets (Calculator, Dice)
    return IntrinsicWidth(child: contentStructure);
  }
}
