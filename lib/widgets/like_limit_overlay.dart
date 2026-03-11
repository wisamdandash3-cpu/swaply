import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_colors.dart';
import '../generated/l10n/app_localizations.dart';
import '../screens/subscription_screen.dart';

/// طبقة حد الإعجابات: عرض رسالة وعداد تنازلي 12 ساعة وزر اشتراك.
class LikeLimitOverlay extends StatefulWidget {
  const LikeLimitOverlay({
    super.key,
    required this.cooldownUntil,
    required this.onDismiss,
  });

  final DateTime cooldownUntil;
  final VoidCallback onDismiss;

  static void show(
    BuildContext context, {
    required DateTime cooldownUntil,
    VoidCallback? onDismiss,
  }) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, _, __) => LikeLimitOverlay(
        cooldownUntil: cooldownUntil,
        onDismiss: () {
          Navigator.of(ctx).pop();
          onDismiss?.call();
        },
      ),
    );
  }

  @override
  State<LikeLimitOverlay> createState() => _LikeLimitOverlayState();
}

class _LikeLimitOverlayState extends State<LikeLimitOverlay> {
  late Timer _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _updateRemaining();
    });
  }

  void _updateRemaining() {
    final now = DateTime.now();
    if (widget.cooldownUntil.isBefore(now)) {
      _timer.cancel();
      widget.onDismiss();
      return;
    }
    setState(() {
      _remaining = widget.cooldownUntil.difference(now);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatCountdown() {
    final h = _remaining.inHours;
    final m = _remaining.inMinutes % 60;
    final s = _remaining.inSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    return Material(
      color: Colors.transparent,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 360),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
                BoxShadow(
                  color: AppColors.rosePink.withValues(alpha: 0.12),
                  blurRadius: 60,
                  spreadRadius: -12,
                ),
                BoxShadow(
                  color: AppColors.hingePurple.withValues(alpha: 0.08),
                  blurRadius: 32,
                  spreadRadius: -8,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      'assets/1000_F_329046482_SLaH6nGEdvbNGNuSlkUHKnkZdlqYoXu7.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned.fill(
                    child: ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(color: Colors.transparent),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 36),
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.rosePink.withValues(alpha: 0.2),
                              AppColors.hingePurple.withValues(alpha: 0.15),
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.rosePink.withValues(alpha: 0.25),
                              blurRadius: 20,
                              spreadRadius: -2,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.favorite_rounded,
                          size: 44,
                          color: AppColors.rosePink.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          l10n.likeLimitReachedTitle,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppColors.darkBlack,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          l10n.likeLimitReachedMessage,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                            fontSize: 19,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkBlack,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 28),
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 28),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.hingePurple.withValues(alpha: 0.12),
                              AppColors.rosePink.withValues(alpha: 0.08),
                            ],
                            begin: isRTL ? Alignment.centerRight : Alignment.centerLeft,
                            end: isRTL ? Alignment.centerLeft : Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppColors.hingePurple.withValues(alpha: 0.25),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.hingePurple.withValues(alpha: 0.06),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          _formatCountdown(),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                            fontSize: 44,
                            fontWeight: FontWeight.w800,
                            color: AppColors.hingePurple,
                            letterSpacing: 4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const SubscriptionScreen(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.hingePurple,
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shadowColor: AppColors.hingePurple.withValues(alpha: 0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: Text(
                              l10n.likeLimitSubscribeCta,
                              style: GoogleFonts.montserrat(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextButton(
                        onPressed: () => widget.onDismiss(),
                        child: Text(
                          l10n.likeLimitOk,
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkBlack,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
