import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_colors.dart';
import '../generated/l10n/app_localizations.dart';

/// نافذة منبثقة: شريط أخضر مائل، X خارج الصورة، إطار صورة كما في الصورة الثالثة، خط النسبة serif، مقياس متحرك.
class ProfileVisibilityPromptDialog extends StatefulWidget {
  const ProfileVisibilityPromptDialog({
    super.key,
    required this.onAnswerQuestions,
    required this.onLater,
    required this.completionPercent,
  });

  final VoidCallback onAnswerQuestions;
  final VoidCallback onLater;
  final int completionPercent;

  @override
  State<ProfileVisibilityPromptDialog> createState() => _ProfileVisibilityPromptDialogState();
}

class _ProfileVisibilityPromptDialogState extends State<ProfileVisibilityPromptDialog>
    with SingleTickerProviderStateMixin {
  static const Color _creamBg = Color(0xFFF5F0E8);

  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    final percent = widget.completionPercent.clamp(0, 100) / 100.0;
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scaleAnimation = Tween<double>(begin: 0, end: percent).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutCubic),
    );
    _scaleController.forward();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final percent = widget.completionPercent.clamp(0, 100);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: _creamBg,
          borderRadius: BorderRadius.circular(24),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      color: _creamBg,
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildDecorIcons(),
                          const SizedBox(height: 16),
                          _buildCard(l10n, percent),
                        ],
                      ),
                    ),
                    // زر X في الزاوية العليا (مكان صورة الثالثة — شريط كريمي)، يتكيّف مع RTL
                    Positioned(
                      top: 12,
                      left: Directionality.of(context) == TextDirection.rtl ? 12 : null,
                      right: Directionality.of(context) == TextDirection.rtl ? null : 12,
                      child: Material(
                        color: Colors.white,
                        shape: const CircleBorder(),
                        elevation: 2,
                        shadowColor: Colors.black.withValues(alpha: 0.15),
                        child: InkWell(
                          onTap: widget.onLater,
                          customBorder: const CircleBorder(),
                          child: const Padding(
                            padding: EdgeInsets.all(10),
                            child: Icon(Icons.close, color: Colors.black87, size: 22),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDecorIcons() {
    const iconColor = Color(0xFFE0DAD0);
    const iconSize = 32.0;
    return SizedBox(
      height: 56,
      child: Stack(
        children: [
          Positioned(left: 12, top: 4, child: Icon(Icons.card_giftcard_rounded, size: iconSize, color: iconColor)),
          Positioned(left: 52, top: 14, child: Icon(Icons.diamond_rounded, size: iconSize * 0.85, color: iconColor)),
          Positioned(left: 88, top: 2, child: Icon(Icons.local_florist_rounded, size: iconSize * 0.9, color: iconColor)),
          Positioned(left: 130, top: 18, child: Icon(Icons.chat_bubble_outline_rounded, size: iconSize * 0.8, color: iconColor)),
          Positioned(right: 80, top: 6, child: Icon(Icons.coffee_rounded, size: iconSize * 0.9, color: iconColor)),
          Positioned(right: 36, top: 20, child: Icon(Icons.card_giftcard_rounded, size: iconSize * 0.75, color: iconColor)),
          Positioned(right: 8, top: 8, child: Icon(Icons.local_florist_rounded, size: iconSize * 0.7, color: iconColor)),
        ],
      ),
    );
  }

  Widget _buildCard(AppLocalizations l10n, int percent) {
    return Container(
      constraints: const BoxConstraints(minWidth: 320),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // إطار الصورة كما في الصورة الثالثة: زوايا علوية أكثر استدارة، حدود خفيفة
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                  bottom: Radius.circular(10),
                ),
                border: Border.all(color: Colors.grey.shade300, width: 0.8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(15),
                  bottom: Radius.circular(9),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Image.asset(
                      'assets/46.jpg',
                      width: double.infinity,
                      height: 240,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 240,
                        color: AppColors.hingePurple.withValues(alpha: 0.15),
                        child: const Center(child: Icon(Icons.person_rounded, size: 64, color: AppColors.hingePurple)),
                      ),
                    ),
                    // NEW و القلب كما في صورة الثانية — متداخلان مع أسفل الصورة
                    Positioned(
                      left: 12,
                      bottom: -8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          l10n.newMatchLabel,
                          style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 12,
                      bottom: -8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6)],
                        ),
                        child: Icon(Icons.favorite_rounded, size: 22, color: AppColors.forestGreen),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // شريط أخضر بشكل مائل + خط النسبة بنفس شكل الصورة الرابعة (serif) + مقياس متحرك
                Transform.rotate(
                  angle: -0.04,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                    decoration: BoxDecoration(
                      color: AppColors.forestGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              l10n.completionScore,
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '$percent%',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                fontStyle: FontStyle.italic,
                                color: const Color(0xFFF5F0E8),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        AnimatedBuilder(
                          animation: _scaleAnimation,
                          builder: (context, child) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: _scaleAnimation.value,
                                backgroundColor: Colors.white.withValues(alpha: 0.4),
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                minHeight: 4,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.attractMoreAttention,
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkBlack,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.completeProfileCardDesc,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    height: 1.45,
                    color: AppColors.darkBlack.withValues(alpha: 0.72),
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: widget.onAnswerQuestions,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.darkBlack,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      l10n.profileCompleteTitle,
                      style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
