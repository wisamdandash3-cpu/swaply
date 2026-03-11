import 'package:flutter/material.dart';

/// وردة ماسية — مكونة من أيقونات ماس متلألئة بتدرج ذهبي وتأثير لمعان نابض.
class DiamondRoseWidget extends StatefulWidget {
  const DiamondRoseWidget({
    super.key,
    required this.size,
  });

  final double size;

  @override
  State<DiamondRoseWidget> createState() => _DiamondRoseWidgetState();
}

class _DiamondRoseWidgetState extends State<DiamondRoseWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _shimmerAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _shimmerAnim = Tween<double>(begin: 0.9, end: 1.12).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// مواقع الماسات في شكل وردة — (x,y) طبيعية 0–1، وحجم نسبي.
  static const List<({double x, double y, double scale})> _positions = [
    (x: 0.50, y: 0.18, scale: 1.0),
    (x: 0.72, y: 0.28, scale: 0.70),
    (x: 0.78, y: 0.50, scale: 0.60),
    (x: 0.62, y: 0.72, scale: 0.65),
    (x: 0.38, y: 0.72, scale: 0.65),
    (x: 0.22, y: 0.50, scale: 0.60),
    (x: 0.28, y: 0.28, scale: 0.70),
    (x: 0.50, y: 0.38, scale: 0.80),
    (x: 0.64, y: 0.48, scale: 0.50),
    (x: 0.50, y: 0.58, scale: 0.55),
    (x: 0.36, y: 0.48, scale: 0.50),
    (x: 0.50, y: 0.48, scale: 0.45),
  ];

  static const _goldLight = Color(0xFFFFF8E1);
  static const _goldMid = Color(0xFFFFD54F);
  static const _goldDark = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _shimmerAnim,
        builder: (_, __) => Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            for (var i = 0; i < _positions.length; i++) ...[
              Positioned(
                left: _positions[i].x * widget.size -
                    (_positions[i].scale * widget.size * 0.28 * _shimmerAnim.value),
                top: _positions[i].y * widget.size -
                    (_positions[i].scale * widget.size * 0.28 * _shimmerAnim.value),
                child: _ShimmerDiamond(
                  size: _positions[i].scale * widget.size * 0.4 * _shimmerAnim.value,
                  colorIndex: i,
                  gradientColors: [_goldLight, _goldMid, _goldDark],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ShimmerDiamond extends StatelessWidget {
  const _ShimmerDiamond({
    required this.size,
    required this.colorIndex,
    required this.gradientColors,
  });

  final double size;
  final int colorIndex;
  final List<Color> gradientColors;

  @override
  Widget build(BuildContext context) {
    final t = (colorIndex / 12).clamp(0.0, 1.0);
    final color = Color.lerp(
      gradientColors[0],
      gradientColors[2],
      t * 0.7,
    )!;
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          gradientColors[0],
          color,
          gradientColors[2].withValues(alpha: 0.8),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(bounds),
      child: Icon(
        Icons.diamond_rounded,
        size: size,
        color: Colors.white,
      ),
    );
  }
}
