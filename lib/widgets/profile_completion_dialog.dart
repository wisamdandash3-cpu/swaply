import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../generated/l10n/app_localizations.dart';
import '../utils/profile_completion.dart';

/// نافذة منبثقة احترافية (مثل Parship) تمنع الإعجاب حتى يكمل المستخدم بروفايله 50%.
/// تصميم محدّث: تدرج، ظل، أيقونة تعبيرية، نسبة وهدف، زر بتدرج.
class ProfileCompletionDialog extends StatelessWidget {
  const ProfileCompletionDialog({
    super.key,
    required this.completionPercent,
    this.profilePhotoUrl,
    required this.onFillNow,
    required this.onNotNow,
  });

  final int completionPercent;
  final String? profilePhotoUrl;
  final VoidCallback onFillNow;
  final VoidCallback onNotNow;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const double avatarSize = 88.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.warmSand.withValues(alpha: 0.18),
              Colors.white,
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.neonCoral.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.darkBlack.withValues(alpha: 0.1),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // أيقونة تعبيرية
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.neonCoral.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.favorite_border,
                  color: AppColors.neonCoral,
                  size: 32,
                ),
              ),
              const SizedBox(height: 22),
              // صورة المستخدم + حلقة التقدّم
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: avatarSize + 14,
                    height: avatarSize + 14,
                    child: CircularProgressIndicator(
                      value: completionPercent / 100,
                      strokeWidth: 5,
                      strokeCap: StrokeCap.round,
                      backgroundColor: AppColors.darkBlack.withValues(alpha: 0.08),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.neonCoral,
                      ),
                    ),
                  ),
                  Container(
                    width: avatarSize,
                    height: avatarSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.darkBlack.withValues(alpha: 0.06),
                      border: Border.all(
                        color: Colors.white,
                        width: 3,
                      ),
                    ),
                    child: ClipOval(
                      child: profilePhotoUrl != null && profilePhotoUrl!.isNotEmpty
                          ? Image.network(
                              profilePhotoUrl!,
                              width: avatarSize,
                              height: avatarSize,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.person,
                                size: 44,
                                color: AppColors.darkBlack.withValues(alpha: 0.35),
                              ),
                            )
                          : Icon(
                              Icons.person,
                              size: 44,
                              color: AppColors.darkBlack.withValues(alpha: 0.35),
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // النسبة الحالية + الهدف
              Text(
                '$completionPercent%',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkBlack,
                      fontSize: 28,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.profileCompletionGoal(ProfileCompletion.minPercentToLike),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.darkBlack.withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.profileCompletionLikeBlockedTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkBlack,
                      fontSize: 20,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                l10n.profileCompletionLikeBlockedDesc,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.darkBlack.withValues(alpha: 0.72),
                      height: 1.45,
                      fontSize: 15,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 26),
              // زر رئيسي بتدرج وظل
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onFillNow,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.neonCoral,
                          AppColors.rosePink,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.neonCoral.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      l10n.profileCompletionFillNow,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextButton(
                onPressed: onNotNow,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.darkBlack.withValues(alpha: 0.5),
                ),
                child: Text(
                  l10n.profileCompletionNotNow,
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
