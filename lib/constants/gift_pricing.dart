import 'package:intl/intl.dart';

/// أسعار الهدايا والباقات (بالسنت EUR). العرض حسب locale المستخدم.
class GiftPricing {
  GiftPricing._();

  /// سعر الوردة الواحدة: 0.99 EUR
  static const int rosePriceCents = 99;

  /// سعر الخاتم: 1.99 EUR
  static const int ringPriceCents = 199;

  /// سعر فنجان القهوة: 1.49 EUR
  static const int coffeePriceCents = 149;

  /// باقات الورود: (عدد الورود، السعر بالسنت)
  static const List<({int count, int priceCents})> roseBundles = [
    (count: 1, priceCents: 99),
    (count: 10, priceCents: 799),
    (count: 25, priceCents: 1799),
    (count: 50, priceCents: 3299),
    (count: 100, priceCents: 5999),
  ];

  /// خيارات شراء الخواتم (واحد أو أكثر)
  static const List<({int count, int priceCents})> ringBundles = [
    (count: 1, priceCents: 199),
    (count: 5, priceCents: 899),
    (count: 10, priceCents: 1699),
  ];

  /// خيارات شراء القهوة
  static const List<({int count, int priceCents})> coffeeBundles = [
    (count: 1, priceCents: 149),
    (count: 5, priceCents: 649),
    (count: 10, priceCents: 1199),
  ];

  /// تحويل السنت إلى نص (مثلاً 99 → "0.99")
  static String formatCents(int cents) {
    final euros = cents / 100;
    return euros.toStringAsFixed(2);
  }

  /// تنسيق السعر حسب لغة/منطقة المستخدم (مثلاً 99 → "0,99 €" في de، "€0.99" في en).
  static String formatCentsForDisplay(int cents, String locale) {
    try {
      return NumberFormat.currency(
        locale: locale,
        symbol: '€',
        decimalDigits: 2,
      ).format(cents / 100);
    } catch (_) {
      return '${formatCents(cents)} €';
    }
  }
}
