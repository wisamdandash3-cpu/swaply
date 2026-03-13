import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_colors.dart';
import '../generated/l10n/app_localizations.dart';
import '../screens/subscription_screen.dart';

/// طبقة حد الإعجابات: عرض رسالة وعداد تنازلي وزر اشتراك — تصميم متناسق مع بقية التطبيق.
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
  static const Color _cardBg = Color(0xFFF8F6F2);

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

    return Material(
      color: Colors.transparent,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 360),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: AppColors.hingePurple.withValues(alpha: 0.06),
                  blurRadius: 24,
                  spreadRadius: -4,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.rosePink.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.rosePink.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        Icons.favorite_rounded,
                        size: 38,
                        color: AppColors.rosePink,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l10n.likeLimitReachedTitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkBlack,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.likeLimitReachedMessage,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.darkBlack.withValues(alpha: 0.7),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                      decoration: BoxDecoration(
                        color: AppColors.hingePurple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.hingePurple.withValues(alpha: 0.22),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _formatCountdown(),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: AppColors.hingePurple,
                          letterSpacing: 3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const SubscriptionScreen(),
                            ),
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.hingePurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          l10n.likeLimitSubscribeCta,
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => widget.onDismiss(),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.darkBlack.withValues(alpha: 0.65),
                      ),
                      child: Text(
                        l10n.likeLimitOk,
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
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
