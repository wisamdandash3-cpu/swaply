import 'package:flutter/material.dart';

import '../app_colors.dart';
import 'draggable_3d_rose_widget.dart';
import 'coffee_icon_widget.dart';
import 'ring_icon_widget.dart';

/// أنواع الهدايا (تطابق قيم photo_url في الرسائل).
const String kGiftTypeRose = 'rose_gift';
const String kGiftTypeRing = 'ring_gift';
const String kGiftTypeCoffee = 'coffee_gift';

/// طبقة الهدية: ظهور سينمائي لبروفايل المرسل ثم الهدية (ورد/خاتم/قهوة) تنمو وتتلاشى لتترك رسالة المرسل.
class RoseGiftOverlay extends StatefulWidget {
  const RoseGiftOverlay({
    super.key,
    required this.senderName,
    this.message,
    required this.onComplete,
    this.senderAvatarUrl,
    this.giftType = kGiftTypeRose,
  });

  final String senderName;
  final String? message;
  final VoidCallback onComplete;
  final String? senderAvatarUrl;
  final String giftType;

  /// عرض الهدية فوق الشاشة الحالية.
  static void show(
    BuildContext context, {
    required String senderName,
    String? message,
    required VoidCallback onComplete,
    String? senderAvatarUrl,
    String giftType = kGiftTypeRose,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      pageBuilder: (_, __, ___) => RoseGiftOverlay(
        senderName: senderName,
        message: message,
        onComplete: () {
          Navigator.of(context).pop();
          onComplete();
        },
        senderAvatarUrl: senderAvatarUrl,
        giftType: giftType,
      ),
    );
  }

  @override
  State<RoseGiftOverlay> createState() => _RoseGiftOverlayState();
}

class _RoseGiftOverlayState extends State<RoseGiftOverlay>
    with TickerProviderStateMixin {
  late AnimationController _profileController;
  late AnimationController _growController;
  late AnimationController _fadeController;
  late Animation<double> _profileAnim;
  late Animation<double> _growAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _profileController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _growController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _profileAnim = CurvedAnimation(
      parent: _profileController,
      curve: Curves.easeOutCubic,
    );
    _growAnim = CurvedAnimation(
      parent: _growController,
      curve: Curves.elasticOut,
    );
    _fadeAnim = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _profileController.forward();
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) _growController.forward();
    });
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) _fadeController.forward();
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) widget.onComplete();
    });
  }

  @override
  void dispose() {
    _profileController.dispose();
    _growController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _profileController,
          _growController,
          _fadeController,
        ]),
        builder: (context, _) {
          return Stack(
            fit: StackFit.expand,
            children: [
              if (_profileAnim.value > 0 && _fadeAnim.value < 0.5)
                Center(
                  child: Opacity(
                    opacity: (_profileAnim.value * (1 - _fadeAnim.value * 2)).clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: 0.35 + 0.65 * _profileAnim.value,
                      child: _CinematicProfile(
                        senderName: widget.senderName,
                        avatarUrl: widget.senderAvatarUrl,
                      ),
                    ),
                  ),
                ),
              Center(
                child: Opacity(
                  opacity: (1 - _fadeAnim.value).clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: _growAnim.value,
                    child: Builder(
                      builder: (context) {
                        final size = MediaQuery.sizeOf(context);
                        final side = size.width < size.height ? size.width : size.height;
                        final containerSize = side * 0.82;
                        final roseSize = containerSize * 0.78;
                        return _GiftWidget(
                          giftType: widget.giftType,
                          containerSize: containerSize,
                          roseSize: roseSize,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// ظهور سينمائي: دائرة بروفايل مع إطار ووهج.
class _CinematicProfile extends StatelessWidget {
  const _CinematicProfile({
    required this.senderName,
    this.avatarUrl,
  });

  final String senderName;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.rosePink.withValues(alpha: 0.5),
            blurRadius: 28,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipOval(
        child: avatarUrl != null && avatarUrl!.trim().isNotEmpty
            ? Image.network(
                avatarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _avatarFallback(senderName),
              )
            : _avatarFallback(senderName),
      ),
    );
  }

  Widget _avatarFallback(String name) {
    return Container(
      color: AppColors.hingePurple.withValues(alpha: 0.4),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            fontSize: 56,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _GiftWidget extends StatelessWidget {
  const _GiftWidget({
    required this.giftType,
    this.containerSize,
    this.roseSize,
  });

  final String giftType;
  final double? containerSize;
  final double? roseSize;

  Widget _giftContent() {
    final size = giftType == kGiftTypeRose ? (roseSize ?? 380) : 160.0;
    switch (giftType) {
      case kGiftTypeCoffee:
        return CoffeeIconWidget(size: 160, color: null, withGlow: true);
      case kGiftTypeRing:
        return RingIconWidget(size: 160, color: null, withGlow: true);
      case kGiftTypeRose:
      default:
        return Draggable3DRoseWidget(size: size, withGlow: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = giftType == kGiftTypeRing
        ? Colors.amber.shade300
        : giftType == kGiftTypeCoffee
            ? Colors.brown.shade400
            : AppColors.rosePink;
    final isRose = giftType == kGiftTypeRose;
    final w = isRose ? (containerSize ?? 480) : 220.0;
    final h = isRose ? (containerSize ?? 480) : 220.0;
    return Container(
      width: w,
      height: h,
      decoration: isRose
          ? null
          : BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  color.withValues(alpha: 0.35),
                  color.withValues(alpha: 0.15),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.6),
                  blurRadius: 32,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
      child: Center(child: _giftContent()),
    );
  }
}
