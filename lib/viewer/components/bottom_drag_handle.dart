import 'package:flutter/material.dart';

class BottomDragHandle extends StatelessWidget {
  final VoidCallback onSwipeUp;

  const BottomDragHandle({super.key, required this.onSwipeUp});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null &&
              details.primaryVelocity! < -500) {
            onSwipeUp();
          }
        },
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
              ],
            ),
          ),
          child: Center(child: Icon(Icons.swipe_up)),
        ),
      ),
    );
  }
}
