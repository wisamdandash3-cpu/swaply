import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_colors.dart';
import '../generated/l10n/app_localizations.dart';
import '../legal/legal_content.dart';
import 'report_complaint_screen.dart';

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

    final userId = type == LegalType.safeDatingTips
        ? Supabase.instance.client.auth.currentUser?.id
        : null;

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
        actions: [
          if (type == LegalType.safeDatingTips && userId != null)
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ReportComplaintScreen.generalComplaint(reporterId: userId),
                  ),
                );
              },
              icon: const Icon(Icons.feedback_outlined, size: 20),
              label: Text(l10n.submitComplaint),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.hingePurple,
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: SelectionArea(
          child: Column(
            children: [
              Expanded(
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
              if (type == LegalType.safeDatingTips) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Builder(
                    builder: (context) {
                      final userId = Supabase.instance.client.auth.currentUser?.id;
                      if (userId == null) return const SizedBox.shrink();
                      return FilledButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => ReportComplaintScreen.generalComplaint(reporterId: userId),
                            ),
                          );
                        },
                        icon: const Icon(Icons.feedback_outlined, size: 20),
                        label: Text(l10n.submitComplaint),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.hingePurple,
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

enum LegalType { terms, privacy, safeDatingTips, memberPrinciples }
