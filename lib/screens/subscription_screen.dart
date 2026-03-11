import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../generated/l10n/app_localizations.dart';
import '../services/subscription_service.dart';

/// شاشة الاشتراك: خطة Swaply+ و خطة Swaply UNLIMITED بتصميم مشابه للصور المرجعية.
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  int _selectedPlanIndex = 1; // 0 = Swaply+, 1 = Swaply UNLIMITED (موصى به)

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final subscription = SubscriptionService.instance;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.darkBlack,
        elevation: 0,
        title: Text(
          l10n.subscriptionTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.darkBlack,
                fontWeight: FontWeight.bold,
              ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(
            l10n.subscriptionSubtitle,
            style: TextStyle(
              fontSize: 15,
              color: AppColors.darkBlack.withValues(alpha: 0.7),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          _PlanTabs(
            selectedIndex: _selectedPlanIndex,
            onSelected: (i) => setState(() => _selectedPlanIndex = i),
            l10n: l10n,
          ),
          const SizedBox(height: 20),
          _SelectedPlanCard(
            isUnlimited: _selectedPlanIndex == 1,
            l10n: l10n,
          ),
          const SizedBox(height: 24),
          _PlanFeaturesList(
            isUnlimited: _selectedPlanIndex == 1,
            l10n: l10n,
          ),
          const SizedBox(height: 24),
          if (!subscription.isPaymentEnabled) ...[
            _ComingSoonBanner(l10n: l10n),
            const SizedBox(height: 16),
          ] else
            _SelectButton(
              l10n: l10n,
              onTap: () => _onSelectPlanTapped(context),
            ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => _onRestoreTapped(context),
            child: Text(
              l10n.restoreSubscription,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.hingePurple,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// عند الضغط على "اختر الخطة": تحديث حالة الاشتراك من السيرفر. لربط IAP استدعِ شراء المتجر ثم refreshSubscriptionStatus بعد النجاح.
  Future<void> _onSelectPlanTapped(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    await SubscriptionService.instance.refreshSubscriptionStatus();
    if (!context.mounted) return;
    if (SubscriptionService.instance.isSubscribed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.subscriptionPurchaseSuccess),
          backgroundColor: AppColors.forestGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.subscriptionPurchaseFailed),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _onRestoreTapped(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    if (!SubscriptionService.instance.isPaymentEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.paymentComingSoon),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    await SubscriptionService.instance.refreshSubscriptionStatus();
    if (!context.mounted) return;
    if (SubscriptionService.instance.isSubscribed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.subscriptionRestoreSuccess),
          backgroundColor: AppColors.forestGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.subscriptionRestoreFailed),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _PlanTabs extends StatelessWidget {
  const _PlanTabs({
    required this.selectedIndex,
    required this.onSelected,
    required this.l10n,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Row(
          children: [
            Expanded(
              child: _PlanTab(
                label: l10n.planSwaplyPlus,
                isSelected: selectedIndex == 0,
                onTap: () => onSelected(0),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PlanTab(
                label: l10n.planSwaplyUnlimited,
                isSelected: selectedIndex == 1,
                isRecommended: true,
                onTap: () => onSelected(1),
              ),
            ),
          ],
        ),
        if (selectedIndex == 1)
          Positioned(
            top: -8,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.forestGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                l10n.planRecommended,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PlanTab extends StatelessWidget {
  const _PlanTab({
    required this.label,
    required this.isSelected,
    this.isRecommended = false,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final bool isRecommended;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.forestGreen
                  : AppColors.darkBlack.withValues(alpha: 0.15),
              width: isSelected ? 2.5 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.forestGreen : AppColors.darkBlack,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectedPlanCard extends StatelessWidget {
  const _SelectedPlanCard({
    required this.isUnlimited,
    required this.l10n,
  });

  final bool isUnlimited;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final planName = isUnlimited ? l10n.planSwaplyUnlimited : l10n.planSwaplyPlus;
    final topFeatures = isUnlimited
        ? [
            (l10n.featureUnlimitedChat, true),
            (l10n.featureSeeAllPhotos, true),
          ]
        : [
            (l10n.featureChatLimited, false),
            (l10n.featureSeeProfilePhotos, false),
          ];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.forestGreen.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            // صورة الخلفية — مختلفة لكل خطة
            Positioned.fill(
              child: Image.asset(
                isUnlimited
                    ? 'assets/rachelscottyoga-woman-2937182_1920.png'
                    : 'assets/iqbalstock-couple-5422806_1920.png',
                fit: BoxFit.cover,
              ),
            ),
            // طبقة شفافة لقراءة النص
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.5),
                      Colors.white.withValues(alpha: 0.88),
                    ],
                  ),
                ),
              ),
            ),
            // المحتوى
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  planName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkBlack,
                  ),
                ),
                const SizedBox(height: 16),
                ...topFeatures.map((f) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            f.$2 ? Icons.all_inclusive : Icons.check_circle_outline,
                            size: 22,
                            color: f.$2 ? AppColors.forestGreen : AppColors.darkBlack.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              f.$1,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.darkBlack.withValues(alpha: 0.85),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      l10n.comingSoon,
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.darkBlack.withValues(alpha: 0.7),
                      ),
                    ),
                    Text(
                      l10n.perMonth,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.darkBlack.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}

/// يعرض مزايا الخطة المختارة فقط (بدون جدول مقارنة).
class _PlanFeaturesList extends StatelessWidget {
  const _PlanFeaturesList({
    required this.isUnlimited,
    required this.l10n,
  });

  final bool isUnlimited;
  final AppLocalizations l10n;

  String _featureTitle(String key) {
    switch (key) {
      case 'featureUnlimitedLikes':
        return l10n.featureUnlimitedLikes;
      case 'featureUnlimitedChat':
        return l10n.featureUnlimitedChat;
      case 'featureSeeProfilePhotos':
        return l10n.featureSeeProfilePhotos;
      case 'featureSeeAllPhotos':
        return l10n.featureSeeAllPhotos;
      case 'featurePersonalityAnalysis':
        return l10n.featurePersonalityAnalysis;
      case 'featureAdvancedFilters':
        return l10n.featureAdvancedFilters;
      case 'featureSeeWhoLiked':
        return l10n.featureSeeWhoLiked;
      case 'featureSeeVisits':
        return l10n.featureSeeVisits;
      case 'featureNewestFirst':
        return l10n.featureNewestFirst;
      case 'featureGiftRoses':
        return l10n.featureGiftRoses;
      case 'featureGiftRings':
        return l10n.featureGiftRings;
      case 'featureGiftBooks':
        return l10n.featureGiftBooks;
      case 'featureGiftCoffee':
        return l10n.featureGiftCoffee;
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = isUnlimited ? AppColors.forestGreen : AppColors.darkBlack;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBlack.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Features (only those included in the selected plan)
          ...SubscriptionService.features.where((f) {
            final status = isUnlimited ? f.swaplyUnlimited : f.swaplyPlus;
            return status != FeatureStatus.cross;
          }).toList().asMap().entries.map((entry) {
            final index = entry.key;
            final feature = entry.value;
            final status = isUnlimited ? feature.swaplyUnlimited : feature.swaplyPlus;
            final isAlt = index % 2 == 1;

            String? trailing;
            if (status == FeatureStatus.infinity) {
              trailing = '∞';
            } else if (status == FeatureStatus.limited) {
              trailing = '${SubscriptionService.swaplyPlusChatLimit}';
            }

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              color: isAlt ? AppColors.darkBlack.withValues(alpha: 0.02) : null,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    status == FeatureStatus.infinity ? Icons.all_inclusive : Icons.check_circle,
                    size: 22,
                    color: accentColor.withValues(alpha: 0.9),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _featureTitle(feature.titleKey),
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.darkBlack.withValues(alpha: 0.9),
                        height: 1.3,
                      ),
                    ),
                  ),
                  if (trailing != null)
                    Text(
                      trailing,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: accentColor,
                      ),
                    ),
                ],
              ),
            );
          }),
          // Gift section
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            color: AppColors.rosePink.withValues(alpha: 0.06),
            child: Row(
              children: [
                Icon(
                  Icons.card_giftcard,
                  size: 20,
                  color: AppColors.rosePink.withValues(alpha: 0.9),
                ),
                const SizedBox(width: 10),
                Text(
                  l10n.featureSendGifts,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkBlack.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          ...SubscriptionService.giftFeatures.map((feature) {
            final qty = isUnlimited ? feature.swaplyUnlimited : feature.swaplyPlus;
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.rosePink.withValues(alpha: 0.04),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _AnimatedGiftIcon(iconType: feature.iconType),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _featureTitle(feature.titleKey),
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.darkBlack.withValues(alpha: 0.9),
                        height: 1.3,
                      ),
                    ),
                  ),
                  Text(
                    '$qty',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// أيقونة هدية متحركة — نفس الأشكال المستخدمة في شاشة إرسال الهدايا (🌹 💍 ☕).
class _AnimatedGiftIcon extends StatefulWidget {
  const _AnimatedGiftIcon({required this.iconType});

  final GiftIconType iconType;

  @override
  State<_AnimatedGiftIcon> createState() => _AnimatedGiftIconState();
}

class _AnimatedGiftIconState extends State<_AnimatedGiftIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _rotateAnimation = Tween<double>(begin: -0.03, end: 0.03).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// نفس الإيموجي المستخدمة في شاشة إرسال الهدايا (الدردشة).
  String get _emoji {
    switch (widget.iconType) {
      case GiftIconType.rose:
        return '🌹';
      case GiftIconType.ring:
        return '💍';
      case GiftIconType.coffee:
        return '☕';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotateAnimation.value,
            child: Text(
              _emoji,
              style: const TextStyle(fontSize: 32),
            ),
          ),
        );
      },
    );
  }
}

class _SelectButton extends StatelessWidget {
  const _SelectButton({required this.l10n, required this.onTap});

  final AppLocalizations l10n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.forestGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(l10n.selectPlan),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward, size: 20),
          ],
        ),
      ),
    );
  }
}

class _ComingSoonBanner extends StatelessWidget {
  const _ComingSoonBanner({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.hingePurple.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.hingePurple.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.payment, color: AppColors.hingePurple, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.paymentComingSoon,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.darkBlack.withValues(alpha: 0.8),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
