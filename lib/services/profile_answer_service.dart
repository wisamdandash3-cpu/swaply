import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile_answer.dart';

/// جلب عناصر بروفايل المستخدم (أسئلة/أجوبة أو صور) مرتبة — كل عنصر له [id] للاستخدام كـ item_id عند الإعجاب.
///
/// RLS policies required in Supabase SQL Editor:
/// - profile_answers_select: SELECT for all (true)
/// - profile_answers_all: ALL (INSERT/UPDATE/DELETE) only if auth.uid() = profile_id
class ProfileAnswerService {
  ProfileAnswerService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  static const String _tableName = 'profile_answers';

  Future<List<ProfileAnswer>> getByProfileId(String profileId) async {
    final list = await _client
        .from(_tableName)
        .select()
        .eq('profile_id', profileId)
        .order('sort_order', ascending: true);

    return (list as List)
        .map((e) => ProfileAnswer.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// قائمة بروفايلات للاكتشاف (تدعم فلتر المسافة، العمر، الجنس، وترقيم الصفحات بعد migration 015).
  Future<List<String>> getDiscoveryProfileIds({
    required String excludeUserId,
    Set<String>? excludePausedUserIds,
    Set<String>? excludeBlockedUserIds,
    double? maxDistanceKm,
    double? userLat,
    double? userLng,
    int? ageMin,
    int? ageMax,
    String? interestedIn,
    int limit = 500,
    int offset = 0,
  }) async {
    final excludeIds = <String>[
      ...?excludePausedUserIds,
      ...?excludeBlockedUserIds,
    ];
    try {
      final params = <String, dynamic>{
        'p_exclude_user_id': excludeUserId,
        'p_exclude_ids': excludeIds.isEmpty ? null : excludeIds,
        'p_limit': limit.clamp(1, 1000),
        'p_offset': offset.clamp(0, 10000),
      };
      if (maxDistanceKm != null && maxDistanceKm > 0 && userLat != null && userLng != null) {
        params['p_max_km'] = maxDistanceKm;
        params['p_user_lat'] = userLat;
        params['p_user_lng'] = userLng;
      }
      if (ageMin != null && ageMin > 0) params['p_age_min'] = ageMin;
      if (ageMax != null && ageMax > 0) params['p_age_max'] = ageMax;
      if (interestedIn != null && interestedIn.trim().isNotEmpty) {
        params['p_interested_in'] = interestedIn.trim();
      }
      final res = await _client.rpc('get_discoverable_profile_ids', params: params);
      if (res is List) {
        return res.map((e) => e.toString()).toList();
      }
      return [];
    } catch (_) {
      return _getDiscoveryProfileIdsFallback(
        excludeUserId: excludeUserId,
        excludePausedUserIds: excludePausedUserIds,
        excludeBlockedUserIds: excludeBlockedUserIds,
      );
    }
  }

  /// استعلام مباشر عند عدم توفر RPC (قبل تشغيل migration 011).
  Future<List<String>> _getDiscoveryProfileIdsFallback({
    required String excludeUserId,
    Set<String>? excludePausedUserIds,
    Set<String>? excludeBlockedUserIds,
  }) async {
    final list = await _client
        .from(_tableName)
        .select('profile_id')
        .neq('profile_id', excludeUserId);
    var ids = (list as List)
        .map((e) => e['profile_id'] as String)
        .where((id) => id != excludeUserId)
        .toSet()
        .toList();
    if (excludePausedUserIds != null && excludePausedUserIds.isNotEmpty) {
      ids = ids.where((id) => !excludePausedUserIds.contains(id)).toList();
    }
    if (excludeBlockedUserIds != null && excludeBlockedUserIds.isNotEmpty) {
      ids = ids.where((id) => !excludeBlockedUserIds.contains(id)).toList();
    }
    return ids;
  }

  /// حفظ إجابة/خيار في البروفايل (نوع نص).
  /// يُستدعى عند اختيار خيار في الـ onboarding أو في البروفايل.
  Future<ProfileAnswer> insertAnswer({
    required String profileId,
    String? questionId,
    required String content,
    int sortOrder = 0,
  }) async {
    final data = <String, dynamic>{
      'profile_id': profileId,
      'item_type': 'text',
      'content': content,
      'sort_order': sortOrder,
    };
    if (questionId != null && questionId.isNotEmpty) {
      data['question_id'] = questionId;
    }
    final res = await _client.from(_tableName).insert(data).select().single();
    return ProfileAnswer.fromJson(Map<String, dynamic>.from(res as Map));
  }

  /// تحديث إجابة موجودة.
  Future<ProfileAnswer> updateAnswer({
    required String id,
    required String content,
  }) async {
    final res = await _client
        .from(_tableName)
        .update({'content': content})
        .eq('id', id)
        .select()
        .single();

    return ProfileAnswer.fromJson(Map<String, dynamic>.from(res as Map));
  }

  /// إدراج صورة بروفايل (item_type: image، content = URL عام).
  Future<ProfileAnswer> insertImageAnswer({
    required String profileId,
    required String content,
    required int sortOrder,
  }) async {
    final data = <String, dynamic>{
      'profile_id': profileId,
      'item_type': 'image',
      'content': content,
      'sort_order': sortOrder,
    };
    final res = await _client.from(_tableName).insert(data).select().single();
    return ProfileAnswer.fromJson(Map<String, dynamic>.from(res as Map));
  }

  /// تحديث أو إدراج صورة في slot معيّن. إن وُجد [existingId] يُحدَّث، وإلا يُدرج سطر جديد.
  Future<ProfileAnswer> upsertImageAnswer({
    required String profileId,
    required int sortOrder,
    required String content,
    String? existingId,
  }) async {
    if (existingId != null && existingId.isNotEmpty) {
      return updateAnswer(id: existingId, content: content);
    }
    return insertImageAnswer(profileId: profileId, content: content, sortOrder: sortOrder);
  }

  /// إدراج فيديو بروفايل (item_type: video، content = URL عام).
  Future<ProfileAnswer> insertVideoAnswer({
    required String profileId,
    required String content,
    required int sortOrder,
  }) async {
    final data = <String, dynamic>{
      'profile_id': profileId,
      'item_type': 'video',
      'content': content,
      'sort_order': sortOrder,
    };
    final res = await _client.from(_tableName).insert(data).select().single();
    return ProfileAnswer.fromJson(Map<String, dynamic>.from(res as Map));
  }

  /// تحديث أو إدراج فيديو. إن وُجد [existingId] يُحدَّث، وإلا يُدرج سطر جديد.
  Future<ProfileAnswer> upsertVideoAnswer({
    required String profileId,
    required int sortOrder,
    required String content,
    String? existingId,
  }) async {
    if (existingId != null && existingId.isNotEmpty) {
      return updateAnswer(id: existingId, content: content);
    }
    return insertVideoAnswer(profileId: profileId, content: content, sortOrder: sortOrder);
  }

  /// إدراج استطلاع (item_type: poll، content = JSON: {question, options}).
  Future<ProfileAnswer> insertPollAnswer({
    required String profileId,
    required String content,
    required int sortOrder,
  }) async {
    final data = <String, dynamic>{
      'profile_id': profileId,
      'item_type': 'poll',
      'content': content,
      'sort_order': sortOrder,
    };
    final res = await _client.from(_tableName).insert(data).select().single();
    return ProfileAnswer.fromJson(Map<String, dynamic>.from(res as Map));
  }

  /// تحديث أو إدراج استطلاع.
  Future<ProfileAnswer> upsertPollAnswer({
    required String profileId,
    required int sortOrder,
    required String content,
    String? existingId,
  }) async {
    if (existingId != null && existingId.isNotEmpty) {
      return updateAnswer(id: existingId, content: content);
    }
    return insertPollAnswer(profileId: profileId, content: content, sortOrder: sortOrder);
  }

  /// حذف إجابة (مثلاً صورة أو فيديو أو استطلاع) بالمعرّف.
  Future<void> deleteAnswer(String id) async {
    await _client.from(_tableName).delete().eq('id', id);
  }
}
