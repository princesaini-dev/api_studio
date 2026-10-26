import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Draggable floating button inserted by `ApiStudio.showFloatingButton`.
class ApiStudioFloatingButton extends StatefulWidget {
  /// Called when the button is tapped.
  final VoidCallback onTap;

  /// Creates the floating debug button.
  const ApiStudioFloatingButton({super.key, required this.onTap});

  @override
  State<ApiStudioFloatingButton> createState() =>
      _ApiStudioFloatingButtonState();
}

class _ApiStudioFloatingButtonState extends State<ApiStudioFloatingButton> {
  static const double _size = 48;
  Offset? _position;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final size = media.size;
    final padding = media.padding;
    final maxX = size.width - _size - 8;
    final maxY = size.height - _size - padding.bottom - 8;
    final pos = _position ?? Offset(maxX, size.height * 0.6);
    final clamped = Offset(
      pos.dx.clamp(8, maxX < 8 ? 8 : maxX),
      pos.dy.clamp(
          padding.top + 8, maxY < padding.top + 8 ? padding.top + 8 : maxY),
    );

    return Positioned(
      left: clamped.dx,
      top: clamped.dy,
      child: GestureDetector(
        key: const Key('apiStudioFloatingButton'),
        onPanUpdate: (d) => setState(() => _position = clamped + d.delta),
        onTap: widget.onTap,
        child: Material(
          color: AppColors.primary,
          shape: const CircleBorder(),
          elevation: 6,
          child: const SizedBox(
            width: _size,
            height: _size,
            child: Icon(Icons.radar_rounded, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
