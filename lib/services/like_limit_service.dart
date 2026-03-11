import 'package:supabase_flutter/supabase_flutter.dart';

import 'subscription_service.dart';

/// خدمة حد الإعجابات: 15 إعجاب مجاني، ثم انتظار 12 ساعة.
class LikeLimitService {
  LikeLimitService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  static const String _tableName = 'profile_likes';

  static const int maxFreeLikes = 15;
  static const Duration cooldownDuration = Duration(hours: 12);

  /// هل يمكن للمستخدم الإعجاب؟ المشتركون غير محدودين.
  Future<({bool canLike, DateTime? cooldownUntil})> checkCanLike(
    String userId,
  ) async {
    if (SubscriptionService.instance.isSubscribed) {
      return (canLike: true, cooldownUntil: null);
    }

    final cutoff = DateTime.now().subtract(cooldownDuration);
    final cutoffIso = cutoff.toUtc().toIso8601String();

    final list = await _client
        .from(_tableName)
        .select('created_at, gift_type')
        .eq('from_user_id', userId)
        .gte('created_at', cutoffIso)
        .order('created_at', ascending: false)
        .limit(maxFreeLikes * 2);

    final rows = (list as List)
        .where((r) => (r as Map<String, dynamic>)['gift_type'] == null)
        .take(maxFreeLikes)
        .toList();
    if (rows.length < maxFreeLikes) {
      return (canLike: true, cooldownUntil: null);
    }

    final oldestInWindow = rows.last as Map<String, dynamic>;
    final createdAtStr = oldestInWindow['created_at'] as String?;
    if (createdAtStr == null) return (canLike: false, cooldownUntil: null);

    final createdAt = DateTime.parse(createdAtStr).toLocal();
    final cooldownUntil = createdAt.add(cooldownDuration);

    if (DateTime.now().isBefore(cooldownUntil)) {
      return (canLike: false, cooldownUntil: cooldownUntil);
    }

    return (canLike: true, cooldownUntil: null);
  }

  /// عدد الإعجابات في نافذة 12 ساعة (للعرض).
  Future<int> getLikesCountInWindow(String userId) async {
    final cutoff = DateTime.now().subtract(cooldownDuration);
    final cutoffIso = cutoff.toUtc().toIso8601String();

    final list = await _client
        .from(_tableName)
        .select('id, gift_type')
        .eq('from_user_id', userId)
        .gte('created_at', cutoffIso);

    return (list as List)
        .where((r) => (r as Map<String, dynamic>)['gift_type'] == null)
        .length;
  }

  /// وقت انتهاء الانتظار (للعداد التنازلي). null إذا لم يكن في فترة انتظار.
  Future<DateTime?> getCooldownUntil(String userId) async {
    final result = await checkCanLike(userId);
    return result.cooldownUntil;
  }
}
