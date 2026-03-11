import 'package:flutter/material.dart';

import '../app_colors.dart';

/// مسار صورة شارة التوثيق (تُعرض في كل مكان يظهر فيه المستخدم الموثّق).
const String kVerificationBadgeAsset = 'assets/verification.jpg';

/// شارة التوثيق (علامة التحقق) بعرض صورة verification.jpg بجانب اسم المستخدم الموثّق.
class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({
    super.key,
    this.size = 16,
    this.color,
  });

  final double size;
  /// لون تدرج اختياري على الصورة (للخلفيات الداكنة استخدم Colors.white).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        kVerificationBadgeAsset,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(
          Icons.verified,
          size: size,
          color: color ?? AppColors.forestGreen,
        ),
      ),
    );
  }
}
