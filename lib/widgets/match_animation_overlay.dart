import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_colors.dart';
import '../generated/l10n/app_localizations.dart';
import '../services/user_settings_service.dart';

/// طبقة احتفال الماتش: تصميم احترافي — اندماج الصور، شرارات أنيقة، وإرسال رسالة مع وردة.
class MatchAnimationOverlay extends StatefulWidget {
  const MatchAnimationOverlay({
    super.key,
    required this.myImageUrl,
    required this.otherImageUrl,
    required this.onComplete,
    this.partnerId,
    this.partnerName,
    this.partnerAvatarUrl,
    this.onSendFeeling,
    this.onNavigateToChat,
    this.onSendTextOnly,
  });

  final String? myImageUrl;
  final String? otherImageUrl;
  final VoidCallback onComplete;
  final String? partnerId;
  final String? partnerName;
  final String? partnerAvatarUrl;
  final Future<void> Function(String partnerId, String message, String giftType)? onSendFeeling;
  /// يُستدعى بعد إرسال الهدية بنجاح للانتقال إلى شاشة الدردشة مع هذا الشريك.
  final void Function(String partnerId, String partnerName, String? partnerAvatarUrl)? onNavigateToChat;
  /// إرسال النص فقط بدون هدية — يُستدعى عند الضغط على «إرسال النص فقط».
  final Future<void> Function(String partnerId, String message)? onSendTextOnly;

  @override
  State<MatchAnimationOverlay> createState() => _MatchAnimationOverlayState();
}

class _MatchAnimationOverlayState extends State<MatchAnimationOverlay>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final UserSettingsService _userSettings = UserSettingsService();
  String? _giftHint;
  bool _sendingRose = false;
  bool _sendSuccess = false;
  late AnimationController _successAnimController;
  late Animation<double> _successAnim;

  late AnimationController _fusionController;
  late AnimationController _particleController;
  late AnimationController _textController;
  late Animation<double> _fusionAnim;
  late Animation<double> _textFade;

  bool get _canSendFeeling =>
      widget.partnerId != null && widget.onSendFeeling != null;

  @override
  void initState() {
    super.initState();
    _heartbeatHaptic();

    _fusionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fusionAnim = CurvedAnimation(
      parent: _fusionController,
      curve: Curves.easeOutCubic,
    );
    _textFade = CurvedAnimation(
      parent: _textController,
      curve: Curves.elasticOut,
    );

    _successAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _successAnim = CurvedAnimation(
      parent: _successAnimController,
      curve: Curves.easeOut,
    );

    _fusionController.forward();
    _fusionController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        _particleController.forward();
        HapticFeedback.selectionClick();
        // تأخير بسيط لحركة النص حتى تظهر بوضوح بعد الشرارات
        Future.delayed(const Duration(milliseconds: 120), () {
          if (mounted) _textController.forward();
        });
      }
    });

    if (!_canSendFeeling) {
      Future.delayed(const Duration(milliseconds: 3400), () {
        if (mounted) widget.onComplete();
      });
    }

    _messageController.addListener(() {
      if (mounted) setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadGiftHint());
  }

  Future<void> _loadGiftHint() async {
    if (!mounted) return;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final l10n = AppLocalizations.of(context);
    final pronounSetting = userId != null
        ? await _userSettings.getPreferredRecipientPronoun(userId)
        : 'male';
    final pronoun = pronounSetting == 'female' ? l10n.pronounHer : l10n.pronounHim;
    if (mounted) setState(() => _giftHint = l10n.giftMessageWhisperHint(pronoun));
  }

  String? _selectedGift;

  Future<void> _sendFeeling() async {
    if (widget.partnerId == null || widget.onSendFeeling == null || _selectedGift == null) return;
    final text = _messageController.text.trim();
    _hapticForGift(_selectedGift!);
    setState(() => _sendingRose = true);
    try {
      await widget.onSendFeeling!(widget.partnerId!, text.isNotEmpty ? text : ' ', _selectedGift!);
      if (!mounted) return;
      setState(() => _sendSuccess = true);
      _successAnimController.forward();
      await Future.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;
      if (widget.onNavigateToChat != null && widget.partnerId != null && widget.partnerName != null) {
        widget.onNavigateToChat!(widget.partnerId!, widget.partnerName!, widget.partnerAvatarUrl);
      }
      widget.onComplete();
    } catch (_) {
      if (mounted) setState(() => _sendingRose = false);
      rethrow;
    }
  }

  Future<void> _sendTextOnly() async {
    if (widget.partnerId == null || widget.onSendTextOnly == null) return;
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    setState(() => _sendingRose = true);
    try {
      await widget.onSendTextOnly!(widget.partnerId!, text);
      if (!mounted) return;
      if (widget.onNavigateToChat != null && widget.partnerId != null && widget.partnerName != null) {
        widget.onNavigateToChat!(widget.partnerId!, widget.partnerName!, widget.partnerAvatarUrl);
      }
      widget.onComplete();
    } catch (_) {
      if (mounted) setState(() => _sendingRose = false);
      rethrow;
    }
  }

  void _heartbeatHaptic() {
    HapticFeedback.lightImpact();
    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) HapticFeedback.lightImpact();
    });
  }

  /// اهتزاز مميز لكل نوع هدية: قهوة اهتزاز بطيء، خاتم نقرتان، وردة متوسطة.
  void _hapticForGift(String giftType) {
    switch (giftType) {
      case kGiftTypeCoffee:
        HapticFeedback.mediumImpact();
        Future.delayed(const Duration(milliseconds: 180), () {
          if (mounted) HapticFeedback.mediumImpact();
        });
        Future.delayed(const Duration(milliseconds: 360), () {
          if (mounted) HapticFeedback.lightImpact();
        });
        break;
      case kGiftTypeRing:
        HapticFeedback.lightImpact();
        Future.delayed(const Duration(milliseconds: 80), () {
          if (mounted) HapticFeedback.lightImpact();
        });
        break;
      default:
        HapticFeedback.mediumImpact();
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _fusionController.dispose();
    _particleController.dispose();
    _textController.dispose();
    _successAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(AppColors.hingeDarkBg, Colors.black, 0.3)!,
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _fusionController,
              _particleController,
              _textController,
              _successAnimController,
            ]),
            builder: (context, _) {
              return Stack(
                fit: StackFit.expand,
                clipBehavior: Clip.none,
                children: [
                  _FusionPhotos(
                    progress: _fusionAnim.value,
                    myImageUrl: widget.myImageUrl,
                    otherImageUrl: widget.otherImageUrl,
                    selectedGift: _selectedGift,
                    sending: _sendingRose,
                    sendSuccess: _sendSuccess,
                    successProgress: _successAnim.value,
                  ),
                  if (_particleController.value > 0)
                    _ParticleOverlay(progress: _particleController.value),
                  Positioned(
                    left: 24,
                    right: 24,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Opacity(
                        opacity: _textFade.value.clamp(0.0, 1.0),
                        child: Transform.scale(
                          scale: 0.45 + 0.55 * _textFade.value,
                          alignment: Alignment.center,
                          child: _MatchTitle(l10n: AppLocalizations.of(context)),
                        ),
                      ),
                    ),
                  ),
                  if (_canSendFeeling)
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 24,
                      child: Opacity(
                        opacity: _textFade.value.clamp(0.0, 1.0),
                        child: _SendFeelingSection(
                          controller: _messageController,
                          sending: _sendingRose,
                          selectedGift: _selectedGift,
                          onSelectGift: (gift) => setState(() => _selectedGift = gift),
                          onSend: _sendFeeling,
                          onSkip: widget.onComplete,
                          onSendTextOnly: widget.onSendTextOnly != null ? _sendTextOnly : null,
                          giftHint: _giftHint,
                        ),
                      ),
                    ),
                  if (_sendSuccess)
                    Positioned.fill(
                      child: _SuccessGiftOverlay(progress: _successAnim.value),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MatchTitle extends StatelessWidget {
  const _MatchTitle({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final title = l10n.youMatched;
    // خط كلاسيكي أنيق (serif italic bold) كما في صورة الثالثة
    final titleStyle = GoogleFonts.playfairDisplay(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      fontStyle: FontStyle.italic,
      letterSpacing: 0.6,
      height: 1.2,
      color: Colors.white,
      shadows: [
        Shadow(
          color: AppColors.rosePink.withValues(alpha: 0.9),
          blurRadius: 20,
          offset: const Offset(0, 2),
        ),
        Shadow(
          color: AppColors.rosePink.withValues(alpha: 0.5),
          blurRadius: 32,
          offset: const Offset(0, 0),
        ),
        Shadow(
          color: Colors.black.withValues(alpha: 0.5),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    );

    return SizedBox(
      width: double.infinity,
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: titleStyle,
      ),
    );
  }
}

class _FusionPhotos extends StatelessWidget {
  const _FusionPhotos({
    required this.progress,
    required this.myImageUrl,
    required this.otherImageUrl,
    this.selectedGift,
    this.sending = false,
    this.sendSuccess = false,
    this.successProgress = 0.0,
  });

  final double progress;
  final String? myImageUrl;
  final String? otherImageUrl;
  final String? selectedGift;
  final bool sending;
  final bool sendSuccess;
  final double successProgress;

  @override
  Widget build(BuildContext context) {
    const size = 178.0; // بطاقات أكبر وأكثر ميلاناً كما في الصورة الرابعة
    const gapBetween = -32.0; // تداخل البطاقات
    const tiltRad = 0.20; // ميلان أوضح (حوالي 11.5°)
    const cardsTop = 78.0; // مسافة أكبر بين "Swapped!" والبطاقات
    final screenWidth = MediaQuery.sizeOf(context).width;
    final centerX = screenWidth / 2;
    final avatarCenterY = cardsTop + size / 2;

    final myStartX = -size;
    final otherStartX = screenWidth + size / 2;
    final myEndX = centerX - size / 2 - gapBetween / 2;
    final otherEndX = centerX + size / 2 + gapBetween / 2;

    final myX = myStartX + (myEndX - myStartX) * progress;
    final otherX = otherStartX + (otherEndX - otherStartX) * progress;

    final giftInfo = selectedGift != null ? kGiftIconAndColor[selectedGift] : null;
    final showGiftGlow = !sendSuccess;
    final avatarGlow = selectedGift != null
        ? null
        : (showGiftGlow ? (giftInfo?.color ?? AppColors.rosePink) : null);

    final landingGlow = sendSuccess && successProgress >= 0.90 ? (giftInfo?.color) : null;

    return SizedBox(
      height: 330,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: myX - size / 2,
            top: cardsTop,
            child: Transform.rotate(
              angle: -tiltRad,
              child: _AvatarCard(
                size: size,
                imageUrl: myImageUrl,
                glowColor: avatarGlow,
                landingGlow: null,
              ),
            ),
          ),
          Positioned(
            left: otherX - size / 2,
            top: cardsTop,
            child: Transform.rotate(
              angle: tiltRad,
              child: _AvatarCard(
                size: size,
                imageUrl: otherImageUrl,
                glowColor: avatarGlow,
                landingGlow: landingGlow,
              ),
            ),
          ),
          if (progress >= 0.98 && selectedGift == null && !sending)
            Positioned(
              left: centerX - 30,
              top: avatarCenterY + 22,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.hingePurple,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.hingePurple.withValues(alpha: 0.6),
                      blurRadius: 18,
                      spreadRadius: 0,
                    ),
                  ],
                  border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  size: 32,
                  color: Colors.white,
                ),
              ),
            ),
          if (sendSuccess && giftInfo != null) ...[
            Positioned.fill(
              child: _FlyingGiftIcon(
                fromX: myX,
                fromY: avatarCenterY,
                toX: otherX,
                toY: avatarCenterY,
                progress: successProgress,
                icon: giftInfo.icon,
                color: giftInfo.color,
                giftType: selectedGift,
              ),
            ),
            if (successProgress >= 0.90)
              _LandingCrownRing(centerX: otherX, centerY: avatarCenterY),
          ],
          if (sending && giftInfo != null) ...[
            _PulsingGiftIcon(
              centerX: centerX,
              centerY: avatarCenterY + 18,
              icon: giftInfo.icon,
              color: giftInfo.color,
              giftType: selectedGift,
            ),
            if (selectedGift == kGiftTypeCoffee)
              _VaporEffect(centerX: centerX, centerY: avatarCenterY),
            if (selectedGift == kGiftTypeRing)
              _SparkleEffect(centerX: centerX, centerY: avatarCenterY),
          ],
        ],
      ),
    );
  }
}

/// أيقونة الهدية النابضة عند الضغط على "إرسال".
class _PulsingGiftIcon extends StatefulWidget {
  const _PulsingGiftIcon({
    required this.centerX,
    required this.centerY,
    required this.icon,
    required this.color,
    this.giftType,
  });

  final double centerX;
  final double centerY;
  final IconData icon;
  final Color color;
  final String? giftType;

  @override
  State<_PulsingGiftIcon> createState() => _PulsingGiftIconState();
}

class _PulsingGiftIconState extends State<_PulsingGiftIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _opacity = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
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
      builder: (context, _) {
        return Positioned(
          left: widget.centerX - 28,
          top: widget.centerY - 28,
          child: Opacity(
            opacity: _opacity.value,
            child: Transform.scale(
              scale: _scale.value,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(alpha: 0.3),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.6),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: widget.giftType == kGiftTypeRing
                    ? Center(child: _RingShape(color: widget.color))
                    : Icon(widget.icon, size: 32, color: Colors.white),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// تأثير البخار عند إرسال القهوة.
class _VaporEffect extends StatefulWidget {
  const _VaporEffect({required this.centerX, required this.centerY});

  final double centerX;
  final double centerY;

  @override
  State<_VaporEffect> createState() => _VaporEffectState();
}

class _VaporEffectState extends State<_VaporEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _anim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        return Positioned(
          left: widget.centerX - 50,
          top: widget.centerY - 60 - _anim.value * 40,
          child: CustomPaint(
            size: const Size(100, 50),
            painter: _VaporPainter(progress: _anim.value),
          ),
        );
      },
    );
  }
}

class _VaporPainter extends CustomPainter {
  _VaporPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: (0.15 * (1 - progress)).clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (var i = 0; i < 4; i++) {
      final path = Path();
      final baseY = size.height * 0.3 + i * 8.0;
      path.moveTo(10 + i * 5, baseY);
      path.quadraticBezierTo(
        size.width * 0.3 + i * 3,
        baseY - 12 - i * 2,
        size.width * 0.5,
        baseY - 8,
      );
      path.quadraticBezierTo(
        size.width * 0.7,
        baseY - 18,
        size.width - 10,
        baseY - 5,
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _VaporPainter old) => old.progress != progress;
}

/// تأثير البريق عند إرسال الخاتم.
class _SparkleEffect extends StatefulWidget {
  const _SparkleEffect({required this.centerX, required this.centerY});

  final double centerX;
  final double centerY;

  @override
  State<_SparkleEffect> createState() => _SparkleEffectState();
}

class _SparkleEffectState extends State<_SparkleEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();
    _anim = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final positions = [
      const Offset(-28, -35),
      const Offset(22, -40),
      const Offset(-35, 5),
      const Offset(30, 0),
      const Offset(-20, 30),
      const Offset(25, 28),
    ];
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        return Positioned(
          left: widget.centerX - 40,
          top: widget.centerY - 45,
          child: SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              children: List.generate(positions.length, (i) {
                final phase = (i / positions.length + _anim.value) % 1.0;
                final opacity = (math.sin(phase * math.pi * 2) * 0.4 + 0.5).clamp(0.0, 1.0);
                return Positioned(
                  left: 40 + positions[i].dx - 6,
                  top: 40 + positions[i].dy - 6,
                  child: Icon(
                    Icons.auto_awesome,
                    size: 12,
                    color: Colors.amber.withValues(alpha: opacity),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }
}

/// نقطة على منحنى Bézier تربيعي: B(t) = (1-t)² P0 + 2(1-t)t P1 + t² P2.
Offset _bezierPoint(double t, Offset p0, Offset p1, Offset p2) {
  final mt = 1 - t;
  final mt2 = mt * mt;
  final t2 = t * t;
  final twoMtT = 2 * mt * t;
  return Offset(
    mt2 * p0.dx + twoMtT * p1.dx + t2 * p2.dx,
    mt2 * p0.dy + twoMtT * p1.dy + t2 * p2.dy,
  );
}

/// أيقونة الهدية تتحرك على قوس Bézier من المرسل إلى المستقبل، مع أثر جزيئات وتكبير في المنتصف.
class _FlyingGiftIcon extends StatelessWidget {
  const _FlyingGiftIcon({
    required this.fromX,
    required this.fromY,
    required this.toX,
    required this.toY,
    required this.progress,
    required this.icon,
    required this.color,
    this.giftType,
  });

  final double fromX;
  final double fromY;
  final double toX;
  final double toY;
  final double progress;
  final IconData icon;
  final Color color;
  final String? giftType;

  @override
  Widget build(BuildContext context) {
    const arcDip = 72.0;
    final p0 = Offset(fromX, fromY);
    final p2 = Offset(toX, toY);
    final p1 = Offset((fromX + toX) / 2, (fromY + toY) / 2 + arcDip);

    final pos = _bezierPoint(progress, p0, p1, p2);
    final x = pos.dx;
    final y = pos.dy;

    final scaleMid = 1.15 + 0.35 * math.sin(progress * math.pi);
    final opacity = (0.85 + 0.15 * (1 - progress)).clamp(0.0, 1.0);

    const trailCount = 6;
    final trailPaints = <Widget>[];
    for (var i = 1; i <= trailCount; i++) {
      final trailT = (progress - i * 0.06).clamp(0.0, 1.0);
      if (trailT <= 0) continue;
      final trailPos = _bezierPoint(trailT, p0, p1, p2);
      final trailOpacity = (0.4 * (1 - i / (trailCount + 1)) * (1 - trailT)).clamp(0.0, 1.0);
      final trailSize = 12.0 + 6 * (1 - i / (trailCount + 1));
      trailPaints.add(
        Positioned(
          left: trailPos.dx - trailSize / 2,
          top: trailPos.dy - trailSize / 2,
          child: Container(
            width: trailSize,
            height: trailSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: trailOpacity * 0.6),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: trailOpacity * 0.5),
                  blurRadius: trailSize,
                  spreadRadius: 0,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (var w in trailPaints) w,
        Positioned(
          left: x - 40,
          top: y - 40,
          child: Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: scaleMid,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.35),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.7),
                      blurRadius: 28,
                      spreadRadius: 4,
                    ),
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 40,
                      spreadRadius: -4,
                    ),
                  ],
                ),
                child: giftType == kGiftTypeRing
                    ? Center(
                        child: Transform.scale(
                          scale: 2.2,
                          child: _RingShape(color: color),
                        ),
                      )
                    : Icon(icon, size: 44, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// حلقة أيقونات تاج الماس الذهبي حول صورة المستقبل عند وصول الهدية (تأكيد قبول الشعور).
class _LandingCrownRing extends StatelessWidget {
  const _LandingCrownRing({
    required this.centerX,
    required this.centerY,
  });

  final double centerX;
  final double centerY;

  static const _count = 12;
  static const _radius = 62.0;
  static const _iconSize = 16.0;
  static const _gold = Color(0xFFFFD700);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: centerX - _radius - _iconSize,
      top: centerY - _radius - _iconSize,
      child: SizedBox(
        width: (_radius + _iconSize) * 2,
        height: (_radius + _iconSize) * 2,
        child: Stack(
          alignment: Alignment.center,
          children: List.generate(_count, (i) {
            final angle = i * (2 * math.pi / _count);
            final x = _radius + _iconSize + math.cos(angle) * _radius - _iconSize / 2;
            final y = _radius + _iconSize + math.sin(angle) * _radius - _iconSize / 2;
            return Positioned(
              left: x,
              top: y,
              child: Icon(
                Icons.diamond_rounded,
                size: _iconSize,
                color: _gold,
              ),
            );
          }),
        ),
      ),
    );
  }
}

/// صورة بروفايل بشكل مربع بزوايا مستديرة (أكبر وواضح مع فراغ لرؤية الهدية).
class _AvatarCard extends StatelessWidget {
  const _AvatarCard({required this.size, this.imageUrl, this.glowColor, this.landingGlow});

  final double size;
  final String? imageUrl;
  final Color? glowColor;
  /// توهج عند هبوط الهدية على صورة المستقبل.
  final Color? landingGlow;

  static const _radius = 22.0;

  @override
  Widget build(BuildContext context) {
    final effectiveGlow = landingGlow ?? glowColor ?? AppColors.rosePink;
    final showGlow = glowColor != null || landingGlow != null;
    final glow = showGlow ? effectiveGlow : null;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: Colors.white, width: 2.2),
        boxShadow: glow == null
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.15),
                  blurRadius: 4,
                  spreadRadius: -2,
                  offset: const Offset(-0.5, -0.5),
                ),
              ]
            : [
                BoxShadow(
                  color: glow.withValues(alpha: 0.45),
                  blurRadius: 22,
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: glow.withValues(alpha: 0.2),
                  blurRadius: 40,
                  spreadRadius: -6,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.12),
                  blurRadius: 2,
                  spreadRadius: -4,
                  offset: const Offset(-0.5, -0.5),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius - 0.5),
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.hingePurple.withValues(alpha: 0.7),
            AppColors.hingePurple.withValues(alpha: 0.5),
          ],
        ),
      ),
      child: Icon(
        Icons.person_rounded,
        size: size * 0.55,
        color: Colors.white.withValues(alpha: 0.85),
      ),
    );
  }
}

/// قيم نوع الهدية المرسلة (تُخزّن في photo_url).
const String kGiftTypeRose = 'rose_gift';
const String kGiftTypeRing = 'ring_gift';
const String kGiftTypeCoffee = 'coffee_gift';

/// ربط نوع الهدية بالأيقونة ولون التوهج (وردي للوردة، ذهبي للخاتم، بني للقهوة).
const Map<String, ({IconData icon, Color color})> kGiftIconAndColor = {
  kGiftTypeRose: (icon: Icons.local_florist_rounded, color: AppColors.rosePink),
  kGiftTypeRing: (icon: Icons.diamond_rounded, color: Colors.amber),
  kGiftTypeCoffee: (icon: Icons.coffee_rounded, color: Colors.brown),
};

class _SendFeelingSection extends StatelessWidget {
  const _SendFeelingSection({
    required this.controller,
    required this.sending,
    required this.selectedGift,
    required this.onSelectGift,
    required this.onSend,
    required this.onSkip,
    this.onSendTextOnly,
    this.giftHint,
  });

  final TextEditingController controller;
  final bool sending;
  final String? selectedGift;
  final ValueChanged<String?> onSelectGift;
  final VoidCallback onSend;
  final VoidCallback onSkip;
  final VoidCallback? onSendTextOnly;
  final String? giftHint;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.rosePink.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.matchSeriousPrompt,
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              fontStyle: FontStyle.italic,
              color: Colors.white,
              shadows: [
                Shadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 4, offset: const Offset(0, 1)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                _GiftChip(
                label: l10n.giftRose,
                emoji: '🌹',
                value: kGiftTypeRose,
                selected: selectedGift == kGiftTypeRose,
                onTap: () => onSelectGift(selectedGift == kGiftTypeRose ? null : kGiftTypeRose),
                imagePath: 'assets/34.png',
              ),
              const SizedBox(width: 8),
              _GiftChip(
                label: l10n.giftRing,
                emoji: '💍',
                value: kGiftTypeRing,
                selected: selectedGift == kGiftTypeRing,
                onTap: () => onSelectGift(selectedGift == kGiftTypeRing ? null : kGiftTypeRing),
                imagePath: 'assets/ring_icon.png',
              ),
              const SizedBox(width: 8),
              _GiftChip(
                label: l10n.giftCoffee,
                emoji: '☕',
                value: kGiftTypeCoffee,
                selected: selectedGift == kGiftTypeCoffee,
                onTap: () => onSelectGift(selectedGift == kGiftTypeCoffee ? null : kGiftTypeCoffee),
                imagePath: 'assets/coffee_icon.png',
              ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            maxLines: 2,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              hintText: giftHint ?? l10n.matchGiftHint,
              hintStyle: GoogleFonts.playfairDisplay(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
                color: Colors.white.withValues(alpha: 0.9),
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.08),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
          const SizedBox(height: 10),
          if (onSendTextOnly != null && selectedGift == null) ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: sending || controller.text.trim().isEmpty
                    ? null
                    : onSendTextOnly,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
                ),
                icon: const Icon(Icons.send_rounded, size: 18),
                label: Text(l10n.sendNiceMessageButton),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: sending ? null : onSkip,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.7), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  child: Text(l10n.matchContinue, style: GoogleFonts.cormorantGaramond(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: (sending || selectedGift == null) ? null : onSend,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.rosePink,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 3,
                    shadowColor: Colors.black.withValues(alpha: 0.35),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  child: sending
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          l10n.matchConfirmAndSend,
                          style: GoogleFonts.cormorantGaramond(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// شكل خاتم كالمصورة: طوق فضيّ سميك + حجر أزرق واضح في الأعلى بمظهر متألق — داخل البادج الكريستالي.
class _RingShape extends StatelessWidget {
  const _RingShape({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.transparent,
              border: Border.all(
                color: const Color(0xFFE8E8E8),
                width: 2.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.5),
                  blurRadius: 1,
                  offset: const Offset(-0.5, -0.5),
                ),
              ],
            ),
          ),
          Positioned(
            top: -1,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(-0.3, -0.3),
                  radius: 0.9,
                  colors: [
                    Colors.white,
                    const Color(0xFFB0E0E6),
                    const Color(0xFF87CEEB),
                    const Color(0xFF5BA3B8),
                  ],
                  stops: const [0.0, 0.3, 0.7, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.8),
                    blurRadius: 2,
                    spreadRadius: 0,
                    offset: const Offset(-0.5, -0.5),
                  ),
                  BoxShadow(
                    color: const Color(0xFF87CEEB).withValues(alpha: 0.5),
                    blurRadius: 3,
                    spreadRadius: 0,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// أيقونة هدية كريستالية ثلاثية الأبعاد (وردة / خاتم / قهوة) بتوهج نابض وحواف متوهجة.
class _CrystalGiftBadge extends StatefulWidget {
  const _CrystalGiftBadge({
    required this.icon,
    required this.color,
    required this.selected,
    this.customChild,
  });

  final IconData icon;
  final Color color;
  final bool selected;
  final Widget? customChild;

  @override
  State<_CrystalGiftBadge> createState() => _CrystalGiftBadgeState();
}

class _CrystalGiftBadgeState extends State<_CrystalGiftBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.color;
    final dark = Color.lerp(c, Colors.black, 0.35) ?? c;
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final glow = 10.0 + _pulse.value * 14;
        final spread = _pulse.value * 4;
        return Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(-0.25, -0.3),
              radius: 0.95,
              colors: [
                Colors.white.withValues(alpha: widget.selected ? 0.7 : 0.4),
                Colors.white.withValues(alpha: widget.selected ? 0.35 : 0.2),
                c.withValues(alpha: widget.selected ? 0.7 : 0.45),
                c.withValues(alpha: widget.selected ? 0.9 : 0.6),
                dark.withValues(alpha: widget.selected ? 0.95 : 0.7),
              ],
              stops: const [0.0, 0.2, 0.5, 0.78, 1.0],
            ),
            border: Border.all(
              color: widget.selected
                  ? Colors.white.withValues(alpha: 0.95)
                  : Colors.white.withValues(alpha: 0.55),
              width: 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.5),
                blurRadius: 3,
                spreadRadius: 0,
                offset: const Offset(-1.5, -1.5),
              ),
              BoxShadow(
                color: c.withValues(alpha: 0.55),
                blurRadius: glow,
                spreadRadius: spread,
              ),
              BoxShadow(
                color: c.withValues(alpha: 0.35),
                blurRadius: glow + 10,
                spreadRadius: spread,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: widget.customChild != null
                ? widget.customChild!
                : ShaderMask(
                    blendMode: BlendMode.srcATop,
                    shaderCallback: (bounds) => LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        Colors.white.withValues(alpha: 0.85),
                        Colors.white.withValues(alpha: 0.7),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ).createShader(bounds),
                    child: Icon(
                      widget.icon,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
          ),
        );
      },
    );
  }
}

class _GiftChip extends StatefulWidget {
  const _GiftChip({
    required this.label,
    required this.emoji,
    required this.value,
    required this.selected,
    required this.onTap,
    this.imagePath,
  });

  final String label;
  final String emoji;
  final String value;
  final bool selected;
  final VoidCallback onTap;
  final String? imagePath;

  @override
  State<_GiftChip> createState() => _GiftChipState();
}

class _GiftChipState extends State<_GiftChip> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _pulseScale = Tween<double>(begin: 0.98, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final giftInfo = kGiftIconAndColor[widget.value]!;
    Widget? customChild;
    if (widget.imagePath != null) {
      customChild = Image.asset(
        widget.imagePath!,
        fit: BoxFit.contain,
        width: 28,
        height: 28,
        errorBuilder: (_, __, ___) => Icon(giftInfo.icon, size: 20, color: Colors.white),
      );
    } else if (widget.value == kGiftTypeRing) {
      customChild = _RingShape(color: giftInfo.color);
    }
    return AnimatedBuilder(
      animation: _pulseScale,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.selected ? 1.0 : _pulseScale.value,
          child: child,
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: widget.selected ? AppColors.rosePink.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: widget.selected ? AppColors.rosePink : Colors.white.withValues(alpha: 0.4),
                width: widget.selected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _CrystalGiftBadge(
                  icon: giftInfo.icon,
                  color: giftInfo.color,
                  selected: widget.selected,
                  customChild: customChild,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w500,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// أنيميشن تأكيد الإرسال: قلوب صغيرة ووردة تتطاير من المركز.
class _SuccessGiftOverlay extends StatelessWidget {
  const _SuccessGiftOverlay({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final center = Offset(size.width / 2, size.height / 2 - 40);
    return IgnorePointer(
      child: CustomPaint(
        painter: _SuccessHeartsPainter(progress: progress, center: center),
        size: size,
      ),
    );
  }
}

class _SuccessHeartsPainter extends CustomPainter {
  _SuccessHeartsPainter({required this.progress, required this.center});

  final double progress;
  final Offset center;

  @override
  void paint(Canvas canvas, Size size) {
    const int count = 14;
    final scale = (progress * 1.4).clamp(0.0, 1.0);
    final alpha = progress < 0.4 ? progress / 0.4 : (1 - (progress - 0.4) / 0.6).clamp(0.0, 1.0);
    final rand = math.Random(7);
    for (var i = 0; i < count; i++) {
      final angle = (i / count) * 2 * math.pi + progress * 0.8;
      final dist = 30 + progress * 90;
      final x = center.dx + math.cos(angle) * dist;
      final y = center.dy + math.sin(angle) * dist - progress * 20;
      final s = (8 + rand.nextDouble() * 10) * scale;
      final paint = Paint()
        ..color = AppColors.rosePink.withValues(alpha: alpha * 0.9)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), s, paint);
    }
    final roseAlpha = alpha * 0.95;
    final rosePaint = Paint()
      ..color = AppColors.rosePink.withValues(alpha: roseAlpha)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 24 * scale, rosePaint);
  }

  @override
  bool shouldRepaint(covariant _SuccessHeartsPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _ParticleOverlay extends StatelessWidget {
  const _ParticleOverlay({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final centerX = screenSize.width / 2;
    final centerY = screenSize.height / 2 - 80;

    return IgnorePointer(
      child: CustomPaint(
        painter: _ParticlePainter(
          progress: progress,
          center: Offset(centerX, centerY),
        ),
        size: screenSize,
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({required this.progress, required this.center});

  final double progress;
  final Offset center;

  @override
  void paint(Canvas canvas, Size size) {
    final rand = math.Random(42);
    final spread = 20.0 + progress * 110.0;
    final peak = 0.35;
    final alpha = progress <= peak
        ? (progress / peak).clamp(0.0, 1.0)
        : (1.0 - (progress - peak) / (1.0 - peak)).clamp(0.0, 1.0);

    for (var layer = 0; layer < 2; layer++) {
      final count = layer == 0 ? 28 : 18;
      final baseSize = layer == 0 ? 2.5 : 4.0;
      final sizeVar = layer == 0 ? 3.5 : 5.0;
      final layerSpread = spread * (layer == 0 ? 1.0 : 0.7);
      final layerAlpha = alpha * (layer == 0 ? 0.95 : 0.45);

      for (var i = 0; i < count; i++) {
        final angle = (i / count) * 2 * math.pi + rand.nextDouble() * 0.5;
        final dist = rand.nextDouble() * layerSpread;
        final x = center.dx + math.cos(angle) * dist;
        final y = center.dy + math.sin(angle) * dist - 24;

        final particleSize = baseSize + rand.nextDouble() * sizeVar;
        final color = layer == 0
            ? AppColors.rosePink.withValues(alpha: layerAlpha)
            : Color.lerp(
                AppColors.rosePink,
                Colors.white,
                0.4,
              )!.withValues(alpha: layerAlpha);

        final paint = Paint()
          ..color = color
          ..style = PaintingStyle.fill;

        canvas.drawCircle(Offset(x, y), particleSize, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
