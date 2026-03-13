import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_colors.dart';

/// ورقة طائرة كهدية (ذهبية مع رباط) — تصميم أنيق للعرض في تأثير الطيران.
class _PaperPlaneGiftPainter extends CustomPainter {
  _PaperPlaneGiftPainter({this.progress = 1.0});

  final double progress;

  static const Color _gold = Color(0xFFE5C76B);
  static const Color _goldMid = Color(0xFFD4AF37);
  static const Color _goldDark = Color(0xFFB8860B);
  static const Color _ribbon = Color(0xFFC9A227);
  static const Color _ribbonAccent = Color(0xFFE8D48B);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final scale = size.width / 80;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-0.35);
    canvas.translate(-center.dx, -center.dy);

    // ظل خفيف تحت الطائرة
    final shadowPath = Path();
    shadowPath.moveTo(center.dx - 26 * scale, center.dy + 11 * scale);
    shadowPath.lineTo(center.dx + 34 * scale, center.dy - 1 * scale);
    shadowPath.lineTo(center.dx - 26 * scale, center.dy - 13 * scale);
    shadowPath.close();
    canvas.drawPath(
      shadowPath,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.2)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5 * scale),
    );

    // جسم الطائرة — مثلث بتدرج ذهبي أنيق
    final path = Path();
    path.moveTo(center.dx - 28 * scale, center.dy + 8 * scale);
    path.lineTo(center.dx + 32 * scale, center.dy - 4 * scale);
    path.lineTo(center.dx - 28 * scale, center.dy - 16 * scale);
    path.close();

    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_gold, _goldMid, _goldDark, _goldMid],
        stops: const [0.0, 0.35, 0.65, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(path, bodyPaint);

    // حد ذهبي لامع
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _gold.withValues(alpha: 0.9),
            _goldDark.withValues(alpha: 0.7),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..strokeWidth = 1.5 * scale,
    );

    // رباط الهدية — شريط مع تدرج
    final ribbonRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx + 4 * scale, center.dy - 2 * scale),
        width: 26 * scale,
        height: 9 * scale,
      ),
      Radius.circular(5 * scale),
    );
    canvas.drawRRect(
      ribbonRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_ribbonAccent, _ribbon, _goldDark.withValues(alpha: 0.8)],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(ribbonRect.outerRect),
    );
    canvas.drawRRect(
      ribbonRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = _goldDark.withValues(alpha: 0.5)
        ..strokeWidth = 0.8 * scale,
    );

    // نجمة صغيرة على الرباط
    final starCenter = Offset(center.dx + 6 * scale, center.dy - 2 * scale);
    _drawStar(
      canvas,
      starCenter,
      4.5 * scale,
      Paint()..color = Colors.white.withValues(alpha: 0.98),
    );
    _drawStar(
      canvas,
      starCenter,
      3.5 * scale,
      Paint()..color = _gold.withValues(alpha: 0.5),
    );

    canvas.restore();

    // شرر ذهبي أنيق حول الطائرة
    if (progress > 0.2) {
      final alpha = (1 - progress) * 0.5;
      for (var i = 0; i < 8; i++) {
        final angle = (i / 8) * 2 * math.pi + progress * 3;
        final r = 38 * scale + 12 * math.sin(progress * 5);
        final o = Offset(
          center.dx + r * math.cos(angle),
          center.dy + r * math.sin(angle),
        );
        canvas.drawCircle(
          o,
          2.5 * scale,
          Paint()..color = _gold.withValues(alpha: alpha),
        );
      }
      for (var i = 0; i < 4; i++) {
        final angle = (i / 4) * 2 * math.pi + progress * 2;
        final r = 48 * scale;
        final o = Offset(
          center.dx + r * math.cos(angle),
          center.dy + r * math.sin(angle),
        );
        canvas.drawCircle(
          o,
          1.5 * scale,
          Paint()..color = _gold.withValues(alpha: alpha * 0.6),
        );
      }
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    const points = 5;
    final path = Path();
    for (var i = 0; i < points * 2; i++) {
      final r = i.isEven ? radius : radius * 0.45;
      final angle = (i * math.pi / points) - math.pi / 2;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PaperPlaneGiftPainter old) =>
      old.progress != progress;
}

/// عرض رسالة «اختر هدية» مع ورقة طائرة كهدية تطير وتختفي عند أعلى الشاشة (الكاميرا الأمامية).
class FlyingGiftMessageOverlay extends StatefulWidget {
  const FlyingGiftMessageOverlay({super.key, required this.message});

  final String message;

  static void show(BuildContext context, String message) {
    HapticFeedback.lightImpact();
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      transitionDuration: const Duration(milliseconds: 100),
      pageBuilder: (ctx, _, __) => Material(
        color: Colors.transparent,
        child: FlyingGiftMessageOverlay(message: message),
      ),
    );
  }

  @override
  State<FlyingGiftMessageOverlay> createState() =>
      _FlyingGiftMessageOverlayState();
}

class _FlyingGiftMessageOverlayState extends State<FlyingGiftMessageOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _flyAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _flyAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _fadeAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 1.0, curve: Curves.easeIn),
      ),
    );
    _controller.forward();
    Future.delayed(const Duration(milliseconds: 1550), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final topPadding = MediaQuery.paddingOf(context).top;
    final startY = screenHeight * 0.55;
    final endY = topPadding + 24;

    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      behavior: HitTestBehavior.opaque,
      child: SizedBox.expand(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final dy = startY + (endY - startY) * _flyAnim.value;
            final opacity = _fadeAnim.value.clamp(0.0, 1.0);
            return Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: dy - 80,
                  child: Opacity(
                    opacity: opacity,
                    child: Center(
                      child: Material(
                        color: Colors.transparent,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CustomPaint(
                              size: const Size(80, 80),
                              painter: _PaperPlaneGiftPainter(
                                progress: _flyAnim.value,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 22,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppColors.hingePurple.withValues(
                                        alpha: 0.95,
                                      ),
                                      AppColors.hingePurple,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.35),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.hingePurple.withValues(
                                        alpha: 0.35,
                                      ),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.15,
                                      ),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  widget.message,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
