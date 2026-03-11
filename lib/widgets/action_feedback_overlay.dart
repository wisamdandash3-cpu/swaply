import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_colors.dart';

/// نوع التأثير: تخطّي (X أحمر) أو إعجاب (قلب بتصميم أجمل).
enum ActionFeedbackType { pass, like }

/// طبقة تغطي الشاشة وتعرض تأثيراً بصرياً قصيراً (X للتخطي، قلب للإعجاب) ثم تستدعي [onComplete].
class ActionFeedbackOverlay extends StatefulWidget {
  const ActionFeedbackOverlay({
    super.key,
    required this.type,
    required this.onComplete,
  });

  final ActionFeedbackType type;
  final VoidCallback onComplete;

  /// يعرض الـ overlay فوق الشاشة الحالية ثم يستدعي [onComplete] بعد انتهاء الأنيميشن.
  static void show(
    BuildContext context, {
    required ActionFeedbackType type,
    required VoidCallback onComplete,
  }) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 150),
      pageBuilder: (ctx, anim, secondary) => Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: () {},
          behavior: HitTestBehavior.opaque,
          child: Center(
            child: ActionFeedbackOverlay(
              type: type,
              onComplete: () {
                Navigator.of(ctx).pop();
                onComplete();
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  State<ActionFeedbackOverlay> createState() => _ActionFeedbackOverlayState();
}

class _ActionFeedbackOverlayState extends State<ActionFeedbackOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    HapticFeedback.lightImpact();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
    Future.delayed(const Duration(milliseconds: 450), () {
      if (mounted) {
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnim.value,
          child: Transform.scale(
            scale: _scaleAnim.value,
            child: widget.type == ActionFeedbackType.pass
                ? _buildPassIcon()
                : _buildLikeIcon(),
          ),
        );
      },
    );
  }

  /// دائرة أنيقة بحد مرجاني وتوهج و X واضح مع أقواس حركة.
  Widget _buildPassIcon() {
    const double size = 148.0;
    const double strokeWidth = 10.0;
    const Color borderColor = AppColors.neonCoral;

    return SizedBox(
      width: size + 72,
      height: size + 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // توهج خارجي
          Container(
            width: size + 44,
            height: size + 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: borderColor.withValues(alpha: 0.35),
                  blurRadius: 32,
                  spreadRadius: 4,
                ),
                BoxShadow(
                  color: borderColor.withValues(alpha: 0.15),
                  blurRadius: 48,
                  spreadRadius: 8,
                ),
              ],
            ),
          ),
          CustomPaint(
            size: Size(size + 56, size + 56),
            painter: _PassFeedbackPainter(
              circleSize: size,
              strokeWidth: strokeWidth,
              borderColor: borderColor,
            ),
          ),
          // X بظل خفيف لوضوح أكبر
          Center(
            child: Stack(
              children: [
                // ظل خفيف خلف الـ X
                Icon(
                  Icons.close,
                  size: 76,
                  color: borderColor.withValues(alpha: 0.35),
                  weight: 800,
                ),
                Icon(
                  Icons.close,
                  size: 74,
                  color: borderColor,
                  weight: 800,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// دائرة بتدرج غني وقلب أنيق مع توهج وشرارات.
  Widget _buildLikeIcon() {
    const double size = 152.0;

    return SizedBox(
      width: size + 64,
      height: size + 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // توهج خارجي متعدد الطبقات
          Container(
            width: size + 36,
            height: size + 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.rosePink.withValues(alpha: 0.5),
                  blurRadius: 36,
                  spreadRadius: 6,
                ),
                BoxShadow(
                  color: AppColors.hingePurple.withValues(alpha: 0.3),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: AppColors.neonCoral.withValues(alpha: 0.25),
                  blurRadius: 48,
                  spreadRadius: 0,
                ),
              ],
            ),
          ),
          // الدائرة الرئيسية بتدرج أنيق
          Container(
            width: size + 24,
            height: size + 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.darkBlack.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
              gradient: const LinearGradient(
                begin: Alignment(-0.9, -0.9),
                end: Alignment(0.9, 0.9),
                colors: [
                  Color(0xFF7B5BB8),
                  AppColors.hingePurple,
                  AppColors.neonCoral,
                  AppColors.rosePink,
                  Color(0xFFF06292),
                ],
                stops: [0.0, 0.3, 0.55, 0.8, 1.0],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.6),
                width: 3.5,
              ),
            ),
            child: CustomPaint(
              painter: _LikeArcsPainter(),
              child: Center(
                child: Stack(
                  children: [
                    // ظل خفيف للقلب
                    Icon(
                      Icons.favorite_rounded,
                      size: 76,
                      color: Colors.black.withValues(alpha: 0.2),
                    ),
                    Icon(
                      Icons.favorite_rounded,
                      size: 74,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// يرسم الدائرة والأقواس لتأثير التخطي.
class _PassFeedbackPainter extends CustomPainter {
  _PassFeedbackPainter({
    required this.circleSize,
    required this.strokeWidth,
    required this.borderColor,
  });

  final double circleSize;
  final double strokeWidth;
  final Color borderColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = circleSize / 2;

    // أقواس رمادية خفيفة (حركة)
    final arcPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 8; i++) {
      final startAngle = (i * 45) * math.pi / 180;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius + 18 + (i % 3) * 4),
        startAngle,
        1.2,
        false,
        arcPaint,
      );
    }

    // دائرة بيضاء بحد أحمر
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, borderPaint);

    final fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius - strokeWidth / 2, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// أقواس خفيفة حول دائرة الإعجاب (نسبية لحجم الودجت).
class _LikeArcsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width / 2;

    final arcPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 8; i++) {
      final startAngle = (i * 45) * math.pi / 180;
      canvas.drawArc(
        Rect.fromCircle(
          center: center,
          radius: baseRadius + 8 + (i % 3) * 3,
        ),
        startAngle,
        0.9,
        false,
        arcPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
