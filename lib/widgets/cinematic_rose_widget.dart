import 'package:flutter/material.dart';

import '../app_colors.dart';

/// وردة من صورة مرجعية — طراز كلاسيكي بخطوط واضحة وأوراق خضراء.
class CinematicRoseWidget extends StatelessWidget {
  const CinematicRoseWidget({
    super.key,
    required this.size,
    this.color,
    this.withGlow = true,
  });

  final double size;
  final Color? color;
  final bool withGlow;

  static const _roseAsset = 'assets/34.png';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          if (withGlow)
            Container(
              width: size * 1.2,
              height: size * 1.2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (color ?? AppColors.rosePink).withValues(alpha: 0.25),
                    blurRadius: size * 0.4,
                    spreadRadius: 0,
                  ),
                ],
              ),
            ),
          ClipRRect(
            borderRadius: BorderRadius.circular(size * 0.2),
            child: Image.asset(
              _roseAsset,
              width: size,
              height: size,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => _FallbackRoseIcon(size: size, color: color),
              color: color,
              colorBlendMode: color != null ? BlendMode.srcIn : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// وردة بديلة مرسومة عند فشل تحميل الصورة.
class _FallbackRoseIcon extends StatelessWidget {
  const _FallbackRoseIcon({required this.size, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.rosePink;
    return Icon(Icons.local_florist_rounded, size: size, color: c);
  }
}
