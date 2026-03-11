import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../generated/l10n/app_localizations.dart';

/// شاشة عرض تراخيص المكتبات (استخدام LicensePage المدمج في Flutter).
class LicensesScreen extends StatelessWidget {
  const LicensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.darkBlack,
        elevation: 0,
        title: Text(
          l10n.licences,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.darkBlack,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
      body: LicensePage(
        applicationName: 'Swaply',
        applicationVersion: '1.0.0',
        applicationIcon: Image.asset(
          'assets/swaply_logo.png',
          width: 48,
          height: 48,
          errorBuilder: (_, __, ___) => const Icon(Icons.info_outline, size: 48),
        ),
        applicationLegalese: '© 2025 Swaply. All rights reserved.',
      ),
    );
  }
}
