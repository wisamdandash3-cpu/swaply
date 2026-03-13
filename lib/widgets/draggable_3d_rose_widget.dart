import 'package:flutter/material.dart';

import 'cinematic_rose_widget.dart';

/// وردة قابلة للتحريك — تُعرض كبديل 2D (تم إزالة الاعتماد على rose_gltf).
class Draggable3DRoseWidget extends StatelessWidget {
  const Draggable3DRoseWidget({
    super.key,
    required this.size,
    this.withGlow = true,
  });

  final double size;
  final bool withGlow;

  @override
  Widget build(BuildContext context) {
    final pad = (size * 0.5).clamp(20.0, 50.0);
    final total = size + pad * 2;
    return SizedBox(
      width: total,
      height: total,
      child: Center(
        child: CinematicRoseWidget(
          size: size,
          color: null,
          withGlow: withGlow,
        ),
      ),
    );
  }
}
