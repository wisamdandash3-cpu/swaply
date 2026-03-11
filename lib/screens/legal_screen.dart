import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../generated/l10n/app_localizations.dart';
import '../legal/legal_content.dart';

/// شاشة عرض شروط الاستخدام أو سياسة الخصوصية (نص طويل قابل للتمرير).
class LegalScreen extends StatelessWidget {
  const LegalScreen({
    super.key,
    required this.type,
    required this.languageCode,
  });

  final LegalType type;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final String title;
    final String content;
    switch (type) {
      case LegalType.terms:
        title = l10n.termsOfUse;
        content = getTermsOfUseContent(languageCode);
        break;
      case LegalType.privacy:
        title = l10n.privacyPolicy;
        content = getPrivacyPolicyContent(languageCode);
        break;
      case LegalType.safeDatingTips:
        title = l10n.safeDatingTips;
        content = getSafeDatingTipsContent(languageCode);
        break;
      case LegalType.memberPrinciples:
        title = l10n.memberPrinciples;
        content = getMemberPrinciplesContent(languageCode);
        break;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.darkBlack,
        elevation: 0,
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.darkBlack,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
      body: SafeArea(
        child: SelectionArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Text(
              content.trim(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.darkBlack,
                    height: 1.5,
                    fontSize: 15,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

enum LegalType { terms, privacy, safeDatingTips, memberPrinciples }
