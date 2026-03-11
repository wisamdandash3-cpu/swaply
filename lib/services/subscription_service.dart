import 'package:supabase_flutter/supabase_flutter.dart';

/// معرفات المنتجات — ستُستخدم لاحقاً عند تفعيل طرق الدفع.
const String kProductSwaplyPlus = 'swaply_plus';
const String kProductSwaplyUnlimited = 'swaply_unlimited';

/// نوع الميزة في جدول المقارنة: ✓ متوفرة، ∞ غير محدودة، ✕ غير متوفرة، أو رقم للحد.
enum FeatureStatus { check, infinity, cross, limited }

/// ميزة في جدول المقارنة.
class PlanFeature {
  const PlanFeature({
    required this.titleKey,
    required this.swaplyPlus,
    required this.swaplyUnlimited,
  });

  final String titleKey;
  final FeatureStatus swaplyPlus;
  final FeatureStatus swaplyUnlimited;
}

/// نوع أيقونة الهدية.
enum GiftIconType { rose, ring, coffee }

/// ميزة بعدد (مثل الهدايا: وردة، خاتم، فنجان قهوة).
class PlanNumberedFeature {
  const PlanNumberedFeature({
    required this.titleKey,
    required this.iconType,
    required this.swaplyPlus,
    required this.swaplyUnlimited,
  });

  final String titleKey;
  final GiftIconType iconType;
  final int swaplyPlus;
  final int swaplyUnlimited;
}

/// خدمة الاشتراكات: عرض المزايا والعروض. حالة الاشتراك تُقرأ من Supabase.
class SubscriptionService {
  SubscriptionService._();
  static final SubscriptionService instance = SubscriptionService._();

  bool _cachedIsSubscribed = false;

  /// يحدّث حالة الاشتراك من جدول subscriptions (يُستدعى عند تسجيل الدخول أو بدء التطبيق).
  Future<void> refreshSubscriptionStatus() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      _cachedIsSubscribed = false;
      return;
    }
    try {
      final res = await Supabase.instance.client
          .from('subscriptions')
          .select('is_active, expires_at')
          .eq('user_id', userId)
          .maybeSingle();
      if (res == null) {
        _cachedIsSubscribed = false;
        return;
      }
      final isActive = res['is_active'] as bool? ?? false;
      final expiresAt = res['expires_at'] as String?;
      if (!isActive) {
        _cachedIsSubscribed = false;
        return;
      }
      if (expiresAt != null && DateTime.parse(expiresAt).isBefore(DateTime.now())) {
        _cachedIsSubscribed = false;
        return;
      }
      _cachedIsSubscribed = true;
    } catch (_) {
      _cachedIsSubscribed = false;
    }
  }

  static const List<PlanFeature> features = [
    PlanFeature(
      titleKey: 'featureUnlimitedLikes',
      swaplyPlus: FeatureStatus.check,
      swaplyUnlimited: FeatureStatus.check,
    ),
    PlanFeature(
      titleKey: 'featureUnlimitedChat',
      swaplyPlus: FeatureStatus.limited, // 15 مثلاً
      swaplyUnlimited: FeatureStatus.infinity,
    ),
    PlanFeature(
      titleKey: 'featureSeeProfilePhotos',
      swaplyPlus: FeatureStatus.check,
      swaplyUnlimited: FeatureStatus.check,
    ),
    PlanFeature(
      titleKey: 'featureSeeAllPhotos',
      swaplyPlus: FeatureStatus.cross,
      swaplyUnlimited: FeatureStatus.infinity,
    ),
    PlanFeature(
      titleKey: 'featurePersonalityAnalysis',
      swaplyPlus: FeatureStatus.check,
      swaplyUnlimited: FeatureStatus.check,
    ),
    PlanFeature(
      titleKey: 'featureAdvancedFilters',
      swaplyPlus: FeatureStatus.check,
      swaplyUnlimited: FeatureStatus.check,
    ),
    PlanFeature(
      titleKey: 'featureSeeWhoLiked',
      swaplyPlus: FeatureStatus.check,
      swaplyUnlimited: FeatureStatus.check,
    ),
    PlanFeature(
      titleKey: 'featureSeeVisits',
      swaplyPlus: FeatureStatus.cross,
      swaplyUnlimited: FeatureStatus.check,
    ),
    PlanFeature(
      titleKey: 'featureNewestFirst',
      swaplyPlus: FeatureStatus.cross,
      swaplyUnlimited: FeatureStatus.check,
    ),
  ];

  /// هدايا إرسال الهدايا: وردة، خاتم، فنجان قهوة.
  static const List<PlanNumberedFeature> giftFeatures = [
    PlanNumberedFeature(
      titleKey: 'featureGiftRoses',
      iconType: GiftIconType.rose,
      swaplyPlus: 50,
      swaplyUnlimited: 100,
    ),
    PlanNumberedFeature(
      titleKey: 'featureGiftRings',
      iconType: GiftIconType.ring,
      swaplyPlus: 25,
      swaplyUnlimited: 50,
    ),
    PlanNumberedFeature(
      titleKey: 'featureGiftCoffee',
      iconType: GiftIconType.coffee,
      swaplyPlus: 5,
      swaplyUnlimited: 10,
    ),
  ];

  /// حدود Swaply+ (عدد المحادثات مثلاً).
  static const int swaplyPlusChatLimit = 15;

  /// تفعيل واجهة الشراء. عند الربط مع in_app_purchase استخدم نفس القيمة أو ربطها بجاهزية المتجر.
  bool get isPaymentEnabled => true;

  /// حالة الاشتراك من جدول subscriptions. استدعِ refreshSubscriptionStatus() عند تسجيل الدخول.
  bool get isSubscribed => _cachedIsSubscribed;
}
