import 'package:flutter/material.dart';

import '../app_colors.dart';

/// أيقونة خاتم مخصصة — خاتم ذهبي مع ماسة زرقاء.
class RingIconWidget extends StatelessWidget {
  const RingIconWidget({
    super.key,
    required this.size,
    this.color,
    this.withGlow = true,
  });

  final double size;
  final Color? color;
  final bool withGlow;

  static const _ringAsset = 'assets/ring_icon.png';

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
                    color: (color ?? AppColors.ringGold).withValues(alpha: 0.25),
                    blurRadius: size * 0.4,
                    spreadRadius: 0,
                  ),
                ],
              ),
            ),
          ClipRRect(
            borderRadius: BorderRadius.circular(size * 0.2),
            child: Image.asset(
              _ringAsset,
              width: size,
              height: size,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => _FallbackRingIcon(size: size, color: color),
              color: color,
              colorBlendMode: color != null ? BlendMode.srcIn : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// أيقونة بديلة عند فشل تحميل الصورة.
class _FallbackRingIcon extends StatelessWidget {
  const _FallbackRingIcon({required this.size, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.ringGold;
    return Icon(Icons.diamond_rounded, size: size, color: c);
  }
}
