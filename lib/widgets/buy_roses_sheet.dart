import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_colors.dart';
import '../constants/gift_pricing.dart';
import '../generated/l10n/app_localizations.dart';
import '../screens/legal_screen.dart';
import '../services/subscription_service.dart';
import '../services/wallet_service.dart';
import 'cinematic_rose_widget.dart';
import 'coffee_icon_widget.dart';
import 'ring_icon_widget.dart';

/// لون زر السعر الأزرق (مثل صورة Add credits).
const Color _priceButtonBlue = Color(0xFF4A90E2);

/// نوع الهدية لورقة الشراء.
enum _GiftTab { roses, rings, coffee }

/// ورقة شراء الهدايا — تصميم داكن: أيقونة مركزية كبيرة، صفوف مع أيقونات واضحة، أزرار سعر زرقاء.
Future<void> showBuyRosesSheet(BuildContext context, {String? initialGiftType}) async {
  _GiftTab initialTab = _GiftTab.roses;
  if (initialGiftType == 'ring_gift') {
    initialTab = _GiftTab.rings;
  } else if (initialGiftType == 'coffee_gift') {
    initialTab = _GiftTab.coffee;
  }
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => _BuyGiftsSheetContent(initialTab: initialTab),
  );
}

class _BuyGiftsSheetContent extends StatefulWidget {
  const _BuyGiftsSheetContent({this.initialTab = _GiftTab.roses});

  final _GiftTab initialTab;

  @override
  State<_BuyGiftsSheetContent> createState() => _BuyGiftsSheetContentState();
}

class _BuyGiftsSheetContentState extends State<_BuyGiftsSheetContent> {
  final WalletService _walletService = WalletService();
  WalletBalance? _balance;
  bool _loading = true;
  late _GiftTab _selectedTab;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    final b = await _walletService.getBalance();
    if (mounted) {
      setState(() {
        _balance = b;
        _loading = false;
      });
    }
  }

  Future<void> _onRosesTap(int count) async {
    final ok = await _walletService.addRoses(count);
    await _handlePurchaseResult(ok, count, 'rose');
  }

  Future<void> _onRingsTap(int count) async {
    final ok = await _walletService.addRings(count);
    await _handlePurchaseResult(ok, count, 'ring');
  }

  Future<void> _onCoffeeTap(int count) async {
    final ok = await _walletService.addCoffee(count);
    await _handlePurchaseResult(ok, count, 'coffee');
  }

  Future<void> _handlePurchaseResult(bool ok, int count, String type) async {
    if (!mounted) return;
    if (ok) {
      await _loadBalance();
      final l10n = AppLocalizations.of(context);
      String message;
      switch (type) {
        case 'rose':
          message = l10n.rosesAdded(count);
          break;
        case 'ring':
          message = l10n.ringsAdded(count);
          break;
        case 'coffee':
          message = l10n.coffeeAdded(count);
          break;
        default:
          message = l10n.rosesAdded(count);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: AppColors.forestGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (!SubscriptionService.instance.isPaymentEnabled) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context).paymentComingSoonGifts),
                backgroundColor: AppColors.hingePurple,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        });
      }
    }
  }

  void _onRestorePurchases() {
    // يمكن ربطه لاحقاً بخدمة استعادة المشتريات
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF2D2438),
            Color(0xFF1a1a2e),
          ],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // مقبض + زر إغلاق
            Padding(
              padding: const EdgeInsets.only(top: 12, right: 8, left: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 48),
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white, size: 26),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // أيقونة مركزية كبيرة للهدية (واضحة)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _CentralGiftIcon(tab: _selectedTab),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.addCreditsToAccount,
              style: GoogleFonts.montserrat(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            // عرض الرصيد في مربعات احترافية
            if (!_loading && _balance != null)
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _BalanceBox(
                        icon: _RealGiftIcon(
                          asset: 'assets/34.png',
                          size: 22,
                          fallback: Icon(Icons.local_florist_rounded, size: 22, color: AppColors.rosePink),
                        ),
                        count: _balance!.roses,
                        label: l10n.giftRose,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _BalanceBox(
                        icon: _RealGiftIcon(
                          asset: 'assets/4.png',
                          size: 20,
                          fallback: RingIconWidget(size: 20, color: null, withGlow: false),
                        ),
                        count: _balance!.rings,
                        label: l10n.giftRing,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _BalanceBox(
                        icon: _RealGiftIcon(
                          asset: 'assets/454.png',
                          size: 20,
                          fallback: CoffeeIconWidget(size: 20, color: null, withGlow: false),
                        ),
                        count: _balance!.coffee,
                        label: l10n.giftCoffee,
                      ),
                    ),
                  ],
                ),
              ),
            // تبويبات الهدايا مع أيقونات واضحة
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _TabChip(
                    label: l10n.giftRose,
                    selected: _selectedTab == _GiftTab.roses,
                    onTap: () => setState(() => _selectedTab = _GiftTab.roses),
                    iconWidget: _RealGiftIcon(
                      asset: 'assets/34.png',
                      size: 28,
                      fallback: Icon(Icons.local_florist_rounded, size: 28, color: AppColors.rosePink),
                    ),
                    color: AppColors.rosePink,
                  ),
                  const SizedBox(width: 8),
                  _TabChip(
                    label: l10n.giftRing,
                    selected: _selectedTab == _GiftTab.rings,
                    onTap: () => setState(() => _selectedTab = _GiftTab.rings),
                    iconWidget: _RealGiftIcon(
                      asset: 'assets/4.png',
                      size: 24,
                      fallback: RingIconWidget(size: 24, color: null, withGlow: false),
                    ),
                    color: AppColors.ringGold,
                  ),
                  const SizedBox(width: 8),
                  _TabChip(
                    label: l10n.giftCoffee,
                    selected: _selectedTab == _GiftTab.coffee,
                    onTap: () => setState(() => _selectedTab = _GiftTab.coffee),
                    iconWidget: _RealGiftIcon(
                      asset: 'assets/454.png',
                      size: 24,
                      fallback: CoffeeIconWidget(size: 24, color: null, withGlow: false),
                    ),
                    color: AppColors.coffeeBrown,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_loading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              )
            else
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    if (_selectedTab == _GiftTab.roses)
                      ...GiftPricing.roseBundles.map(
                        (b) => _DarkGiftRow(
                          icon: _RealGiftIcon(
                            asset: 'assets/34.png',
                            size: 44,
                            fallback: CinematicRoseWidget(size: 44, color: null, withGlow: false),
                          ),
                          title: '${b.count} ${l10n.giftRose}',
                          subtitle: b.count > 1 ? l10n.perUnit(GiftPricing.formatCents(b.priceCents ~/ b.count)) : null,
                          priceCents: b.priceCents,
                          onTap: () => _onRosesTap(b.count),
                        ),
                      ),
                    if (_selectedTab == _GiftTab.rings)
                      ...GiftPricing.ringBundles.map(
                        (b) => _DarkGiftRow(
                          icon: _RealGiftIcon(
                            asset: 'assets/4.png',
                            size: 40,
                            fallback: RingIconWidget(size: 40, color: null, withGlow: false),
                          ),
                          title: '${b.count} ${l10n.giftRing}',
                          subtitle: b.count > 1 ? l10n.perUnit(GiftPricing.formatCents(b.priceCents ~/ b.count)) : null,
                          priceCents: b.priceCents,
                          onTap: () => _onRingsTap(b.count),
                        ),
                      ),
                    if (_selectedTab == _GiftTab.coffee)
                      ...GiftPricing.coffeeBundles.map(
                        (b) => _DarkGiftRow(
                          icon: _RealGiftIcon(
                            asset: 'assets/454.png',
                            size: 40,
                            fallback: CoffeeIconWidget(size: 40, color: null, withGlow: false),
                          ),
                          title: '${b.count} ${l10n.giftCoffee}',
                          subtitle: b.count > 1 ? l10n.perUnit(GiftPricing.formatCents(b.priceCents ~/ b.count)) : null,
                          priceCents: b.priceCents,
                          onTap: () => _onCoffeeTap(b.count),
                        ),
                      ),
                  ],
                ),
              ),
            // رسالة الدفع قريباً
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 18, color: Colors.white.withValues(alpha: 0.7)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.paymentComingSoonGifts,
                        style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // تذييل: استعادة المشتريات، الشروط، الخصوصية (بدون overflow)
            Padding(
              padding: const EdgeInsets.only(bottom: 24, left: 12, right: 12),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 4,
                runSpacing: 4,
                children: [
                  TextButton(
                    onPressed: _onRestorePurchases,
                    style: TextButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      l10n.restorePurchases,
                      style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '·',
                    style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.5)),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      final locale = Localizations.localeOf(context).languageCode;
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => LegalScreen(type: LegalType.terms, languageCode: locale),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      l10n.termsOfUse,
                      style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '·',
                    style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.5)),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      final locale = Localizations.localeOf(context).languageCode;
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => LegalScreen(type: LegalType.privacy, languageCode: locale),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      l10n.privacyPolicy,
                      style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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

/// مربع عرض رصيد نوع هدية واحد (وردة / خاتم / قهوة).
class _BalanceBox extends StatelessWidget {
  const _BalanceBox({
    required this.icon,
    required this.count,
    required this.label,
  });

  final Widget icon;
  final int count;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(height: 6),
          Text(
            '$count',
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.75),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// أيقونة الهدية الكبيرة في المنتصف (واضحة).
class _CentralGiftIcon extends StatelessWidget {
  const _CentralGiftIcon({required this.tab});

  final _GiftTab tab;

  @override
  Widget build(BuildContext context) {
    switch (tab) {
      case _GiftTab.roses:
        return _RealGiftIcon(
          asset: 'assets/34.png',
          size: 88,
          fallback: CinematicRoseWidget(size: 88, color: null, withGlow: false),
        );
      case _GiftTab.rings:
        return _RealGiftIcon(
          asset: 'assets/4.png',
          size: 72,
          fallback: RingIconWidget(size: 72, color: null, withGlow: false),
        );
      case _GiftTab.coffee:
        return _RealGiftIcon(
          asset: 'assets/454.png',
          size: 72,
          fallback: CoffeeIconWidget(size: 72, color: null, withGlow: false),
        );
    }
  }
}

/// أيقونة هدية من أصل صورة مع fallback — بحجم واضح.
class _RealGiftIcon extends StatelessWidget {
  const _RealGiftIcon({
    required this.asset,
    required this.size,
    required this.fallback,
  });

  final String asset;
  final double size;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        asset,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.iconWidget,
    required this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget iconWidget;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: selected ? color.withValues(alpha: 0.25) : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                iconWidget,
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    style: GoogleFonts.montserrat(
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 13,
                      color: selected ? color : Colors.white.withValues(alpha: 0.8),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// صف خيار شراء بتصميم داكن: أيقونة واضحة + عنوان + فرعي + زر سعر أزرق.
class _DarkGiftRow extends StatelessWidget {
  const _DarkGiftRow({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.priceCents,
    required this.onTap,
  });

  final Widget icon;
  final String title;
  final String? subtitle;
  final int priceCents;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final priceStr = GiftPricing.formatCentsForDisplay(priceCents, locale);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // أيقونة الهدية واضحة في خلفية فاتحة
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: icon,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Material(
                  color: _priceButtonBlue,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Text(
                        priceStr,
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
