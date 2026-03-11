import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_colors.dart';
import 'star_icon_widget.dart';

/// تصميم موحّد للحالة الفارغة (معجب بك / الدردشة): دائرة بتدرج وأيقونات، عنوان، نص، وزران.
class EmptyStateIllustration extends StatelessWidget {
  const EmptyStateIllustration({
    super.key,
    required this.title,
    required this.description,
    this.primaryButtonLabel,
    this.primaryButtonIcon,
    this.onPrimaryPressed,
    this.secondaryButtonLabel,
    this.secondaryButtonIcon,
    this.onSecondaryPressed,
  });

  final String title;
  final String description;

  /// الزر الأول (تدرج بنفسجي–وردي)، مثلاً "ممیزون" أو "اذهب للرئيسية".
  final String? primaryButtonLabel;
  final Widget? primaryButtonIcon;
  final VoidCallback? onPrimaryPressed;

  /// الزر الثاني (إطار بنفسجي)، مثلاً "اشتراك Swaply".
  final String? secondaryButtonLabel;
  final Widget? secondaryButtonIcon;
  final VoidCallback? onSecondaryPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              _buildCircleWithIcons(),
              const SizedBox(height: 24),
              Text(
                title,
                style: GoogleFonts.montserrat(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkBlack,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                description,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 15,
                  height: 1.5,
                  color: AppColors.darkBlack.withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(height: 24),
              if (primaryButtonLabel != null && onPrimaryPressed != null)
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.hingePurple,
                          AppColors.hingePurple.withValues(alpha: 0.85),
                          AppColors.rosePink.withValues(alpha: 0.9),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.hingePurple.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: FilledButton.icon(
                      onPressed: onPrimaryPressed,
                      icon: primaryButtonIcon ?? StarIconWidget(
                        color: Colors.white,
                        size: 30,
                        isSelected: true,
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      label: Text(
                        primaryButtonLabel!,
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              if (primaryButtonLabel != null &&
                  secondaryButtonLabel != null &&
                  onSecondaryPressed != null)
                const SizedBox(height: 12),
              if (secondaryButtonLabel != null && onSecondaryPressed != null)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onSecondaryPressed,
                    icon: secondaryButtonIcon ?? Icon(
                      Icons.card_giftcard_rounded,
                      size: 22,
                      color: AppColors.hingePurple,
                    ),
                    label: Text(
                      secondaryButtonLabel!,
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppColors.hingePurple,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: AppColors.hingePurple.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      backgroundColor: AppColors.hingePurple.withValues(alpha: 0.04),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircleWithIcons() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 260,
          height: 220,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.hingePurple.withValues(alpha: 0.08),
                AppColors.rosePink.withValues(alpha: 0.06),
                AppColors.hingePurple.withValues(alpha: 0.05),
              ],
            ),
            shape: BoxShape.circle,
          ),
        ),
        Positioned(
          top: 38,
          child: Icon(
            Icons.chat_bubble_outline_rounded,
            size: 52,
            color: AppColors.hingePurple.withValues(alpha: 0.65),
          ),
        ),
        Positioned(
          top: 80,
          left: 48,
          child: Icon(
            Icons.chat_bubble_rounded,
            size: 34,
            color: AppColors.rosePink.withValues(alpha: 0.75),
          ),
        ),
        Positioned(
          top: 90,
          right: 44,
          child: Icon(
            Icons.favorite_border_rounded,
            size: 30,
            color: AppColors.hingePurple.withValues(alpha: 0.6),
          ),
        ),
        Positioned(
          bottom: 44,
          child: Icon(
            Icons.mail_outline_rounded,
            size: 40,
            color: AppColors.hingePurple.withValues(alpha: 0.55),
          ),
        ),
        Positioned(
          bottom: 64,
          left: 58,
          child: Icon(
            Icons.waving_hand_rounded,
            size: 28,
            color: AppColors.rosePink.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}
