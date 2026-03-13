import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_colors.dart';
import '../constants/gift_pricing.dart';
import '../generated/l10n/app_localizations.dart';
import '../services/subscription_service.dart';
import '../services/wallet_service.dart';
import 'cinematic_rose_widget.dart';
import 'coffee_icon_widget.dart';
import 'ring_icon_widget.dart';

/// نوع الهدية لورقة الشراء.
enum _GiftTab { roses, rings, coffee }

/// ورقة شراء الهدايا — ورود، خواتم، قهوة. مع شراء سريع بضغطة واحدة.
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

  int? _bestValueIndex(List<({int count, int priceCents})> bundles, int singlePrice) {
    if (bundles.length < 2) return null;
    double best = 0;
    int idx = 0;
    for (var i = 0; i < bundles.length; i++) {
      final b = bundles[i];
      if (b.count > 1) {
        final perUnit = b.priceCents / b.count;
        final save = (singlePrice - perUnit) / singlePrice;
        if (save > best) {
          best = save;
          idx = i;
        }
      }
    }
    return best > 0 ? idx : null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.darkBlack.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (!_loading && _balance != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.hingePurple.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.hingePurple.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 22,
                      color: AppColors.hingePurple,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${l10n.yourBalance}: ${l10n.rosesBalance(_balance!.roses)}  ·  ${_balance!.rings} ${l10n.giftRing}  ·  ${_balance!.coffee} ${l10n.giftCoffee}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkBlack,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // تبويبات سريعة
          Row(
            children: [
              _TabChip(
                label: l10n.giftRose,
                icon: Icons.local_florist_rounded,
                color: AppColors.rosePink,
                selected: _selectedTab == _GiftTab.roses,
                onTap: () => setState(() => _selectedTab = _GiftTab.roses),
                iconWidget: _RealGiftIcon(asset: 'assets/34.png', size: 26, fallback: Icon(Icons.local_florist_rounded, size: 26, color: AppColors.rosePink)),
              ),
              const SizedBox(width: 8),
              _TabChip(
                label: l10n.giftRing,
                icon: Icons.diamond_rounded,
                color: AppColors.ringGold,
                selected: _selectedTab == _GiftTab.rings,
                onTap: () => setState(() => _selectedTab = _GiftTab.rings),
                iconWidget: _RealGiftIcon(asset: 'assets/434.png', size: 20, fallback: RingIconWidget(size: 20, color: null, withGlow: false)),
              ),
              const SizedBox(width: 8),
              _TabChip(
                label: l10n.giftCoffee,
                icon: Icons.coffee_rounded,
                color: AppColors.coffeeBrown,
                selected: _selectedTab == _GiftTab.coffee,
                onTap: () => setState(() => _selectedTab = _GiftTab.coffee),
                iconWidget: _RealGiftIcon(asset: 'assets/coffee_icon.png', size: 20, fallback: CoffeeIconWidget(size: 20, color: null, withGlow: false)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.hingePurple),
              ),
            )
          else ...[
            if (_selectedTab == _GiftTab.roses)
              _RosesContent(
                balance: _balance!.roses,
                bestIdx: _bestValueIndex(GiftPricing.roseBundles, GiftPricing.rosePriceCents),
                onTap: _onRosesTap,
              ),
            if (_selectedTab == _GiftTab.rings)
              _RingsContent(
                balance: _balance!.rings,
                bestIdx: _bestValueIndex(GiftPricing.ringBundles, GiftPricing.ringPriceCents),
                onTap: _onRingsTap,
              ),
            if (_selectedTab == _GiftTab.coffee)
              _CoffeeContent(
                balance: _balance!.coffee,
                bestIdx: _bestValueIndex(GiftPricing.coffeeBundles, GiftPricing.coffeePriceCents),
                onTap: _onCoffeeTap,
              ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.warmSand.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: AppColors.darkBlack.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.paymentComingSoonGifts,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.darkBlack.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// أيقونة هدية من أصل صورة (وردة/خاتم/قهوة الحقيقية) مع fallback.
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
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
    this.iconWidget,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final Widget? iconWidget;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: selected ? color.withValues(alpha: 0.2) : color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                iconWidget ?? Icon(icon, size: 20, color: selected ? color : color.withValues(alpha: 0.7)),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.montserrat(
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 13,
                    color: selected ? color : AppColors.darkBlack.withValues(alpha: 0.7),
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

class _RosesContent extends StatelessWidget {
  const _RosesContent({
    required this.balance,
    required this.bestIdx,
    required this.onTap,
  });

  final int balance;
  final int? bestIdx;
  final void Function(int count) onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${l10n.yourBalance}: $balance 🌹', style: TextStyle(fontSize: 14, color: AppColors.darkBlack.withValues(alpha: 0.7))),
        const SizedBox(height: 16),
        SizedBox(
          height: 320,
          child: SingleChildScrollView(
            child: Column(
              children: GiftPricing.roseBundles.asMap().entries.map((e) {
                final i = e.key;
                final b = e.value;
                final isBest = bestIdx == i && b.count > 1;
                final perUnit = b.count > 1 ? GiftPricing.formatCents(b.priceCents ~/ b.count) : GiftPricing.formatCents(b.priceCents);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _BundleCard(
                    count: b.count,
                    label: l10n.giftRose,
                    priceCents: b.priceCents,
                    perUnit: perUnit,
                    isBestValue: isBest,
                    icon: _RealGiftIcon(
                      asset: 'assets/34.png',
                      size: 40,
                      fallback: CinematicRoseWidget(size: 40, color: null, withGlow: false),
                    ),
                    accentColor: AppColors.rosePink,
                    onTap: () => onTap(b.count),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _RingsContent extends StatelessWidget {
  const _RingsContent({
    required this.balance,
    required this.bestIdx,
    required this.onTap,
  });

  final int balance;
  final int? bestIdx;
  final void Function(int count) onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${l10n.yourBalance}: $balance 💎', style: TextStyle(fontSize: 14, color: AppColors.darkBlack.withValues(alpha: 0.7))),
        const SizedBox(height: 16),
        SizedBox(
          height: 320,
          child: SingleChildScrollView(
            child: Column(
              children: GiftPricing.ringBundles.asMap().entries.map((e) {
                final i = e.key;
                final b = e.value;
                final isBest = bestIdx == i && b.count > 1;
                final perUnit = b.count > 1 ? GiftPricing.formatCents(b.priceCents ~/ b.count) : GiftPricing.formatCents(b.priceCents);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _BundleCard(
                    count: b.count,
                    label: l10n.giftRing,
                    priceCents: b.priceCents,
                    perUnit: perUnit,
                    isBestValue: isBest,
                    icon: _RealGiftIcon(
                      asset: 'assets/434.png',
                      size: 32,
                      fallback: RingIconWidget(size: 32, color: null, withGlow: false),
                    ),
                    accentColor: AppColors.ringGold,
                    onTap: () => onTap(b.count),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _CoffeeContent extends StatelessWidget {
  const _CoffeeContent({
    required this.balance,
    required this.bestIdx,
    required this.onTap,
  });

  final int balance;
  final int? bestIdx;
  final void Function(int count) onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${l10n.yourBalance}: $balance ☕', style: TextStyle(fontSize: 14, color: AppColors.darkBlack.withValues(alpha: 0.7))),
        const SizedBox(height: 16),
        SizedBox(
          height: 320,
          child: SingleChildScrollView(
            child: Column(
              children: GiftPricing.coffeeBundles.asMap().entries.map((e) {
                final i = e.key;
                final b = e.value;
                final isBest = bestIdx == i && b.count > 1;
                final perUnit = b.count > 1 ? GiftPricing.formatCents(b.priceCents ~/ b.count) : GiftPricing.formatCents(b.priceCents);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _BundleCard(
                    count: b.count,
                    label: l10n.giftCoffee,
                    priceCents: b.priceCents,
                    perUnit: perUnit,
                    isBestValue: isBest,
                    icon: _RealGiftIcon(
                      asset: 'assets/coffee_icon.png',
                      size: 32,
                      fallback: CoffeeIconWidget(size: 32, color: null, withGlow: false),
                    ),
                    accentColor: AppColors.coffeeBrown,
                    onTap: () => onTap(b.count),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _BundleCard extends StatelessWidget {
  const _BundleCard({
    required this.count,
    required this.label,
    required this.priceCents,
    required this.perUnit,
    required this.isBestValue,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  final int count;
  final String label;
  final int priceCents;
  final String perUnit;
  final bool isBestValue;
  final Widget icon;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final priceStr = GiftPricing.formatCentsForDisplay(priceCents, locale);
    return Material(
      color: isBestValue ? accentColor.withValues(alpha: 0.08) : AppColors.warmSand.withValues(alpha: 0.25),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: isBestValue ? Border.all(color: accentColor.withValues(alpha: 0.4), width: 1.5) : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: icon,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isBestValue)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.forestGreen,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            l10n.bestValue,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                        ),
                      ),
                    Text(
                      '$count $label',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: AppColors.darkBlack,
                      ),
                    ),
                    if (count > 1)
                      Text(
                        l10n.perUnit(perUnit),
                        style: TextStyle(fontSize: 12, color: AppColors.darkBlack.withValues(alpha: 0.6)),
                      ),
                  ],
                ),
              ),
              Text(
                priceStr,
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: accentColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
