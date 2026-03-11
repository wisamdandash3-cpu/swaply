import 'package:flutter/material.dart';

import '../app_colors.dart';
import 'cinematic_rose_widget.dart';

/// وردة من [assets/rose.png] قابلة للتحريك باللمس مع دوران بزوايا 3D (منظور).
class Draggable3DRoseWidget extends StatefulWidget {
  const Draggable3DRoseWidget({
    super.key,
    required this.size,
    this.withGlow = true,
  });

  final double size;
  final bool withGlow;

  static const String _roseAsset = 'assets/rose.png';

  @override
  State<Draggable3DRoseWidget> createState() => _Draggable3DRoseWidgetState();
}

class _Draggable3DRoseWidgetState extends State<Draggable3DRoseWidget> {
  Offset _offset = Offset.zero;
  double _rotationX = 0;
  double _rotationY = 0;

  static const double _rotationFactor = 0.005;
  static const double _perspective = 0.0012;
  static const double _maxRotation = 0.85;

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _offset += details.delta;
      _rotationY += details.delta.dx * _rotationFactor;
      _rotationX -= details.delta.dy * _rotationFactor;
      _rotationX = _rotationX.clamp(-_maxRotation, _maxRotation);
      _rotationY = _rotationY.clamp(-_maxRotation, _maxRotation);
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final pad = (size * 0.5).clamp(20.0, 50.0);
    final total = size + pad * 2;
    return SizedBox(
      width: total,
      height: total,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          if (widget.withGlow)
            Positioned(
              left: pad + _offset.dx,
              top: pad + _offset.dy,
              child: Container(
                width: size * 1.25,
                height: size * 1.25,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.rosePink.withValues(alpha: 0.18),
                      blurRadius: size * 0.35,
                      spreadRadius: size * 0.02,
                    ),
                    BoxShadow(
                      color: AppColors.rosePink.withValues(alpha: 0.08),
                      blurRadius: size * 0.5,
                      spreadRadius: 0,
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            left: pad + _offset.dx,
            top: pad + _offset.dy,
            child: GestureDetector(
              onPanUpdate: _onPanUpdate,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, _perspective)
                  ..rotateX(_rotationX)
                  ..rotateY(_rotationY),
                child: SizedBox(
                  width: size,
                  height: size,
                  child: Image.asset(
                    Draggable3DRoseWidget._roseAsset,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => CinematicRoseWidget(
                      size: size,
                      color: null,
                      withGlow: false,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
