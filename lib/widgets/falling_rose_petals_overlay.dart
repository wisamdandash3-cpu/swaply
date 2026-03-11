import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_colors.dart';

/// رابط صوت التأثير السحري (soft magic chime) — يُشغّل عند بدء التساقط.
const _kMagicChimeUrl =
    'https://orangefreesounds.com/wp-content/uploads/2022/12/Magic-chimes-sound-effect.mp3';

/// طبقة بتلات وردية تسقط من الأعلى — تُستخدم عند عرض رسالة هدية جادة أو شاشة "وصلك شعور".
class FallingRosePetalsOverlay extends StatefulWidget {
  const FallingRosePetalsOverlay({
    super.key,
    required this.child,
    this.showGlowBehindRose = false,
    this.onComplete,
  });

  final Widget child;
  /// إظهار توهج خلف الوردة المركزية عند بدء التساقط.
  final bool showGlowBehindRose;
  final VoidCallback? onComplete;

  /// عرض التساقط فوق الشاشة الحالية.
  static void show(
    BuildContext context, {
    bool playSound = true,
    VoidCallback? onComplete,
  }) {
    playMagicChime(playSound);
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => const _FallingPetalsFullScreen(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    ).then((_) => onComplete?.call());
  }

  /// تشغيل صوت التأثير السحري — للاستدعاء من GiftReceivedOverlay.
  static void playMagicChime(bool play) {
    if (!play) return;
    try {
      final player = AudioPlayer();
      player.play(UrlSource(_kMagicChimeUrl));
      player.onPlayerComplete.listen((_) {
        player.dispose();
      });
    } catch (_) {
      HapticFeedback.mediumImpact();
    }
  }

  @override
  State<FallingRosePetalsOverlay> createState() => _FallingRosePetalsOverlayState();
}

class _FallingRosePetalsOverlayState extends State<FallingRosePetalsOverlay>
    with TickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _glowAnim;
  bool _hasTriggeredComplete = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..forward();
    _glowAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0, 0.15, curve: Curves.easeOut),
      ),
    );
    _ctrl.addStatusListener((s) {
      if (s == AnimationStatus.completed && !_hasTriggeredComplete) {
        _hasTriggeredComplete = true;
        widget.onComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        Positioned.fill(
          child: RepaintBoundary(
            child: IgnorePointer(
              child: LayoutBuilder(
                builder: (_, c) => AnimatedBuilder(
                  animation: _ctrl,
                  builder: (_, __) => CustomPaint(
                    painter: _FallingPetalsPainter(
                      progress: _ctrl.value,
                      showGlow: widget.showGlowBehindRose,
                      glowIntensity: _glowAnim.value,
                    ),
                    size: Size(c.maxWidth, c.maxHeight),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// شاشة كاملة للتساقط تُغلق تلقائياً بعد المدة.
class _FallingPetalsFullScreen extends StatefulWidget {
  const _FallingPetalsFullScreen();

  @override
  State<_FallingPetalsFullScreen> createState() => _FallingPetalsFullScreenState();
}

class _FallingPetalsFullScreenState extends State<_FallingPetalsFullScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();
    _ctrl.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return SizedBox(
      width: size.width,
      height: size.height,
      child: RepaintBoundary(
        child: IgnorePointer(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => CustomPaint(
              painter: _FallingPetalsPainter(
                progress: _ctrl.value,
                showGlow: true,
                glowIntensity: 1,
              ),
              size: size,
            ),
          ),
        ),
      ),
    );
  }
}

/// طبقة البتلات: خلف المحتوى، أمامه، أو الكل.
enum _PetalsLayer { back, front, all }

class _FallingPetalsPainter extends CustomPainter {
  _FallingPetalsPainter({
    required this.progress,
    this.showGlow = false,
    this.glowIntensity = 1,
    this.layer = _PetalsLayer.all,
    this.petalScale = 1.0,
  });

  final double progress;
  final bool showGlow;
  final double glowIntensity;
  final _PetalsLayer layer;
  final double petalScale;

  static const int _particleCount = 35;
  static const List<Color> _petalColors = [
    Color(0xFFE91E63),
    Color(0xFFF06292),
    Color(0xFFEC407A),
    Color(0xFFAD1457),
    Color(0xFFF8BBD9),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);
    if (showGlow && glowIntensity > 0) {
      _drawGlow(canvas, size);
    }
    for (var i = 0; i < _particleCount; i++) {
      final isBack = i % 3 == 0;
      if (layer == _PetalsLayer.back && !isBack) continue;
      if (layer == _PetalsLayer.front && isBack) continue;
      final seed = rng.nextDouble();
      final p = _particleProgress(progress, seed);
      if (p > 1) continue;
      _drawPetal(canvas, size, i, seed, p, isBack);
    }
  }

  void _drawGlow(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.35;
    final paint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.2,
        colors: [
          AppColors.rosePink.withValues(alpha: 0.35 * glowIntensity),
          AppColors.rosePink.withValues(alpha: 0.1 * glowIntensity),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: 120));
    canvas.drawCircle(Offset(cx, cy), 120, paint);
  }

  double _particleProgress(double t, double seed) {
    final delay = seed * 0.6;
    return (t - delay) / (1 - delay);
  }

  void _drawPetal(
    Canvas canvas,
    Size size,
    int i,
    double seed,
    double p,
    bool isBack,
  ) {
    final w = size.width;
    final h = size.height;
    final rng = math.Random(i * 1000 + 123);
    final baseX = (rng.nextDouble() - 0.5) * w * 1.2 + w / 2;
    final startY = -30.0 - rng.nextDouble() * 40;
    final endY = h + 50;
    final y = startY + (endY - startY) * p;
    final sway = math.sin(p * math.pi * 4 + seed * 10) * 25 * petalScale * (1 - p * 0.5);
    final x = baseX + sway;
    final rot = p * math.pi * 2 + seed * 5;
    final sizeFactor = 0.4 + rng.nextDouble() * 0.8;
    final petalW = 12.0 * sizeFactor * petalScale;
    final petalH = 18.0 * sizeFactor * petalScale;
    final fade = p > 0.7 ? (1 - (p - 0.7) / 0.3) : 1.0;
    final alpha = (isBack ? 0.35 : 0.85) * fade;
    final color = _petalColors[rng.nextInt(_petalColors.length)];
    final fillColor = color.withValues(alpha: alpha);
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(rot);
    final path = _petalPath(petalW, petalH);
    canvas.drawPath(
      path,
      Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: alpha * 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
    canvas.restore();
  }

  Path _petalPath(double w, double h) {
    final path = Path();
    path.moveTo(0, -h * 0.5);
    path.quadraticBezierTo(w * 0.6, 0, w * 0.3, h * 0.5);
    path.quadraticBezierTo(0, h * 0.3, -w * 0.3, h * 0.5);
    path.quadraticBezierTo(-w * 0.6, 0, 0, -h * 0.5);
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _FallingPetalsPainter old) =>
      old.progress != progress ||
      old.glowIntensity != glowIntensity ||
      old.layer != layer ||
      old.petalScale != petalScale;
}

/// تساقط البتلات داخل منطقة محددة (مثل فقاعة الهدية).
class FallingPetalsInBox extends StatefulWidget {
  const FallingPetalsInBox({
    super.key,
    required this.child,
    required this.borderRadius,
  });

  final Widget child;
  final BorderRadius borderRadius;

  @override
  State<FallingPetalsInBox> createState() => _FallingPetalsInBoxState();
}

class _FallingPetalsInBoxState extends State<FallingPetalsInBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.antiAlias,
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: widget.borderRadius,
            child: IgnorePointer(
              child: LayoutBuilder(
                builder: (_, c) => AnimatedBuilder(
                  animation: _ctrl,
                  builder: (_, __) => CustomPaint(
                    painter: _FallingPetalsPainter(
                      progress: _ctrl.value,
                      showGlow: false,
                      glowIntensity: 0,
                      layer: _PetalsLayer.all,
                      petalScale: (c.maxHeight / 400).clamp(0.4, 1.2),
                    ),
                    size: Size(c.maxWidth, c.maxHeight),
                  ),
                ),
              ),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

/// عرض تساقط البتلات مع المحتوى في المنتصف — تأثير عمق ثلاثي الأبعاد.
class LayeredFallingPetals extends StatefulWidget {
  const LayeredFallingPetals({
    super.key,
    required this.child,
    this.onComplete,
  });

  final Widget child;
  final VoidCallback? onComplete;

  @override
  State<LayeredFallingPetals> createState() => _LayeredFallingPetalsState();
}

class _LayeredFallingPetalsState extends State<LayeredFallingPetals>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..forward();
    _ctrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) => CustomPaint(
                painter: _FallingPetalsPainter(
                  progress: _ctrl.value,
                  showGlow: true,
                  glowIntensity: 1,
                  layer: _PetalsLayer.back,
                ),
                size: size,
              ),
            ),
          ),
        ),
        widget.child,
        RepaintBoundary(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) => CustomPaint(
                painter: _FallingPetalsPainter(
                  progress: _ctrl.value,
                  showGlow: false,
                  glowIntensity: 0,
                  layer: _PetalsLayer.front,
                ),
                size: size,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
