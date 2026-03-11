import 'package:flutter/material.dart';

import '../app_colors.dart';

/// أيقونة قهوة مخصصة — فنجان مع قلب، طراز جذاب.
class CoffeeIconWidget extends StatelessWidget {
  const CoffeeIconWidget({
    super.key,
    required this.size,
    this.color,
    this.withGlow = true,
  });

  final double size;
  final Color? color;
  final bool withGlow;

  static const _coffeeAsset = 'assets/coffee_icon.png';

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
                    color: (color ?? AppColors.coffeeBrown).withValues(alpha: 0.25),
                    blurRadius: size * 0.4,
                    spreadRadius: 0,
                  ),
                ],
              ),
            ),
          ClipRRect(
            borderRadius: BorderRadius.circular(size * 0.2),
            child: Image.asset(
              _coffeeAsset,
              width: size,
              height: size,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => _FallbackCoffeeIcon(size: size, color: color),
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
class _FallbackCoffeeIcon extends StatelessWidget {
  const _FallbackCoffeeIcon({required this.size, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.coffeeBrown;
    return Icon(Icons.coffee_rounded, size: size, color: c);
  }
}
