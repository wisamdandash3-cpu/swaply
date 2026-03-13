import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_colors.dart';
import 'cinematic_rose_widget.dart';
import 'coffee_icon_widget.dart';
import 'falling_rose_petals_overlay.dart';
import '../generated/l10n/app_localizations.dart';
import 'ring_icon_widget.dart';

/// نوع الهدية للمستلم (نفس قيم المرسل).
const String _kGiftRose = 'rose_gift';
const String _kGiftRing = 'ring_gift';
const String _kGiftCoffee = 'coffee_gift';

/// شاشة "وصلك شعور جاد" للمستلم: صورة المرسل مع تاج الماس، أيقونة الهدية النابضة، وصندوق الرسالة.
class GiftReceivedOverlay extends StatefulWidget {
  const GiftReceivedOverlay({
    super.key,
    required this.senderName,
    required this.senderAvatarUrl,
    this.receiverAvatarUrl,
    required this.giftType,
    required this.giftMessage,
    required this.onReplySeriously,
    required this.onLater,
  });

  final String senderName;
  final String? senderAvatarUrl;
  final String? receiverAvatarUrl;
  final String giftType;
  final String giftMessage;
  final VoidCallback onReplySeriously;
  final VoidCallback onLater;

  /// عرض الـ overlay فوق الشاشة الحالية. يُرجع true إذا اختار "أعطِ فرصة"، false إذا "لاحقاً".
  static Future<bool?> show(
    BuildContext context, {
    required String senderName,
    required String? senderAvatarUrl,
    String? receiverAvatarUrl,
    required String giftType,
    required String giftMessage,
  }) async {
    return Navigator.of(context).push<bool>(
      PageRouteBuilder<bool>(
        opaque: false,
        barrierColor: AppColors.hingeDarkBg,
        pageBuilder: (_, __, ___) => GiftReceivedOverlay(
          senderName: senderName,
          senderAvatarUrl: senderAvatarUrl,
          receiverAvatarUrl: receiverAvatarUrl,
          giftType: giftType,
          giftMessage: giftMessage,
          onReplySeriously: () => Navigator.of(context).pop(true),
          onLater: () => Navigator.of(context).pop(false),
        ),
      ),
    );
  }

  @override
  State<GiftReceivedOverlay> createState() => _GiftReceivedOverlayState();
}

class _GiftReceivedOverlayState extends State<GiftReceivedOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  Offset _giftDragOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.9, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) FallingRosePetalsOverlay.playMagicChime(true);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color get _giftColor {
    switch (widget.giftType) {
      case _kGiftRose:
        return AppColors.rosePink;
      case _kGiftRing:
        return Colors.amber;
      case _kGiftCoffee:
        return Colors.brown;
      default:
        return AppColors.rosePink;
    }
  }

  /// أيقونة الهدية — الخاتم من 434.png بدون خلفية وبدون تلوين.
  Widget _buildGiftContent() {
    switch (widget.giftType) {
      case _kGiftRing:
        return RingIconWidget(size: 64, color: null, withGlow: true);
      case _kGiftCoffee:
        return CoffeeIconWidget(size: 64, color: null, withGlow: true);
      default:
        return CinematicRoseWidget(size: 64, color: null, withGlow: true);
    }
  }

  Widget _buildBlurredPhotoBackground() {
    final senderUrl = widget.senderAvatarUrl;
    final receiverUrl = widget.receiverAvatarUrl;
    final hasTwo = senderUrl != null && senderUrl.isNotEmpty && receiverUrl != null && receiverUrl.isNotEmpty;
    if (hasTwo) {
      return ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Row(
          children: [
            Expanded(
              child: Image.network(
                senderUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallbackBackground(),
              ),
            ),
            Expanded(
              child: Image.network(
                receiverUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallbackBackground(),
              ),
            ),
          ],
        ),
      );
    }
    final singleUrl = senderUrl ?? receiverUrl;
    if (singleUrl != null && singleUrl.isNotEmpty) {
      return ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Image.network(
          singleUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, __, ___) => _fallbackBackground(),
        ),
      );
    }
    return _fallbackBackground();
  }

  Widget _fallbackBackground() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF352E42),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF352E42),
            AppColors.hingePurple.withValues(alpha: 0.25),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.hingeDarkBg,
              AppColors.darkBlack,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.hingePurple.withValues(alpha: 0.35),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.hingePurple.withValues(alpha: 0.15),
                      blurRadius: 32,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned.fill(child: _buildBlurredPhotoBackground()),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.52),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                    Text(
                      l10n.giftReceivedTitle(widget.senderName),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.35,
                        color: Colors.white,
                        shadows: const [
                          Shadow(color: Colors.black38, offset: Offset(0, 1), blurRadius: 4),
                          Shadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 6),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        _SubtleAvatarRing(radius: 72),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _SenderAvatar(avatarUrl: widget.senderAvatarUrl),
                            const SizedBox(height: 14),
                            GestureDetector(
                              onPanUpdate: (d) {
                                setState(() {
                                  _giftDragOffset += d.delta;
                                });
                              },
                              child: AnimatedBuilder(
                                animation: _pulseAnim,
                                builder: (_, __) => Transform.translate(
                                  offset: _giftDragOffset,
                                  child: Transform.scale(
                                    scale: _pulseAnim.value,
                                    child: Container(
                                      width: 92,
                                      height: 92,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: RadialGradient(
                                          colors: [
                                            _giftColor.withValues(alpha: 0.35),
                                            _giftColor.withValues(alpha: 0.14),
                                            _giftColor.withValues(alpha: 0.05),
                                          ],
                                          stops: const [0.0, 0.5, 1.0],
                                        ),
                                        border: Border.all(
                                          color: _giftColor.withValues(alpha: 0.55),
                                          width: 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: _giftColor.withValues(alpha: 0.4),
                                            blurRadius: 18,
                                            spreadRadius: 0,
                                          ),
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.3),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Center(child: _buildGiftContent()),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: widget.onLater,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white70,
                              side: BorderSide(
                                color: AppColors.hingePurple.withValues(alpha: 0.5),
                                width: 1.5,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(l10n.later),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: FilledButton(
                            onPressed: widget.onReplySeriously,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.hingePurple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Text(l10n.replySeriously),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    ),
    ),
    );
  }
}

/// حلقة أنيقة حول صورة المرسل بدل تاج الماس — مظهر احترافي.
class _SubtleAvatarRing extends StatelessWidget {
  const _SubtleAvatarRing({required this.radius});

  final double radius;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (radius + 8) * 2,
      height: (radius + 8) * 2,
      child: Center(
        child: Container(
          width: radius * 2 + 12,
          height: radius * 2 + 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.hingePurple.withValues(alpha: 0.45),
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}

class _SenderAvatar extends StatelessWidget {
  const _SenderAvatar({this.avatarUrl});

  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.9),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.hingePurple.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipOval(
        child: avatarUrl != null && avatarUrl!.isNotEmpty
            ? Image.network(avatarUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder())
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.hingePurple.withValues(alpha: 0.6),
      child: Icon(Icons.person_rounded, size: 56, color: Colors.white.withValues(alpha: 0.8)),
    );
  }
}

