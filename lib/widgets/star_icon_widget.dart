import 'dart:math' show cos, sin, sqrt;

import 'package:flutter/material.dart';

/// تصميم انفجار نجوم — نجوم مفرغة ومملوءة مع خطوط حركة ووميض، كما في الصورة المرجعية.
class StarIconPainter extends CustomPainter {
  StarIconPainter({required this.color, this.isSelected = false});

  final Color color;
  final bool isSelected;

  static const int _points = 5;
  static const double _outerRatio = 0.50;
  static const double _innerRatio = 0.22;

  Path _buildStarPath(double cx, double cy, double rOut, double rIn) {
    const halfTurn = 3.14159265359;
    const step = halfTurn * 2 / _points;
    const startAngle = -halfTurn * 0.5;
    final path = Path();
    for (int i = 0; i < _points * 2; i++) {
      final angle = startAngle + i * (step * 0.5);
      final radius = i.isEven ? rOut : rIn;
      final x = cx + radius * cos(angle);
      final y = cy + radius * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  void _drawTaperingLine(
    Canvas canvas,
    double x1,
    double y1,
    double x2,
    double y2,
    double baseWidth,
    Paint paint,
  ) {
    final dx = x2 - x1;
    final dy = y2 - y1;
    final len = sqrt(dx * dx + dy * dy);
    if (len < 0.1) return;
    final perpX = -dy / len * baseWidth;
    final perpY = dx / len * baseWidth;
    final path = Path()
      ..moveTo(x2, y2)
      ..lineTo(x1 + perpX, y1 + perpY)
      ..lineTo(x1 - perpX, y1 - perpY)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width < size.height ? size.width : size.height;
    final scale = s / 32.0;

    double tx(double x) => x * s;
    double ty(double y) => y * s;

    final paint = Paint()..color = color;

    // خطوط الحركة — أنحف وأقصر لتركيز الانتباه على النجمة
    final lineBase = 0.6 * scale;
    final lineStarts = [
      Offset(0.50, 0.48),
      Offset(0.46, 0.50),
      Offset(0.48, 0.52),
    ];
    final lineEnds = [
      Offset(0.12, 0.88),
      Offset(0.08, 0.84),
      Offset(0.10, 0.90),
    ];
    for (var i = 0; i < lineStarts.length; i++) {
      _drawTaperingLine(
        canvas,
        tx(lineStarts[i].dx),
        ty(lineStarts[i].dy),
        tx(lineEnds[i].dx),
        ty(lineEnds[i].dy),
        lineBase,
        paint,
      );
    }

    // نجوم مملوءة صغيرة — أقل عددًا وأوضح
    final filledStars = [
      (tx(0.68), ty(0.22), 2.8 * scale),
      (tx(0.78), ty(0.36), 2.0 * scale),
      (tx(0.58), ty(0.48), 1.8 * scale),
    ];
    for (final (cx, cy, r) in filledStars) {
      final path = _buildStarPath(cx, cy, r * _outerRatio, r * _innerRatio);
      canvas.drawPath(path, paint);
    }

    // النجمة الرئيسية — أكبر وأوضح، مركزية
    final mainCx = s * 0.5;
    final mainCy = s * 0.42;
    final mainR = 11.0 * scale; // أكبر بكثير لملء المساحة
    final mainPath = _buildStarPath(
      mainCx,
      mainCy,
      mainR * _outerRatio,
      mainR * _innerRatio,
    );
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = (isSelected ? 2.2 : 1.8) * scale
      ..strokeJoin = StrokeJoin.miter;
    canvas.drawPath(mainPath, strokePaint);

    if (isSelected) {
      final glow = Paint()
        ..color = color.withValues(alpha: 0.4)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 * scale);
      canvas.drawPath(mainPath, glow);
    }

    // نقاط وميض أقل عددًا
    final dots = [Offset(0.28, 0.58), Offset(0.22, 0.72), Offset(0.38, 0.46)];
    for (final d in dots) {
      canvas.drawCircle(Offset(tx(d.dx), ty(d.dy)), 0.7 * scale, paint);
    }
  }

  @override
  bool shouldRepaint(covariant StarIconPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.isSelected != isSelected;
}

/// أيقونة نجمة بحجم ثابت — للاستخدام في الأزرار أو الشريط السفلي.
class StarIconWidget extends StatelessWidget {
  const StarIconWidget({
    super.key,
    required this.color,
    this.size = 32,
    this.isSelected = false,
  });

  final Color color;
  final double size;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: StarIconPainter(color: color, isSelected: isSelected),
        size: Size(size, size),
      ),
    );
  }
}
