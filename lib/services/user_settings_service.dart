import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// مزامنة إعدادات المستخدم (إيقاف مؤقت، آخر نشاط، التحقق بالـ selfie) بين SharedPreferences و Supabase.
class UserSettingsService {
  UserSettingsService({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  static const String _tableName = 'user_profile_fields';
  static const String _storageBucket = 'profile-photos';
  static const String _keyPause = 'temporary_pause';
  static const String _keyLastActive = 'last_active_at';
  static const String _keyShowLastActive = 'show_last_active';
  static const String _keySelfieVerification = 'selfie_verification_status';
  static const String _keyCommentFilter = 'comment_filter_enabled';
  static const String _keyUnits = 'units_of_measurement';
  static const String _keyPrivacyVisibility = 'privacy_profile_visibility';
  static const String _keyPrivacyShowDistance = 'privacy_show_distance';
  /// ضمير المخاطب عند إرسال الهدية: 'male' = له، 'female' = لها
  static const String _keyPreferredRecipientPronoun = 'preferred_recipient_pronoun';

  /// حفظ إيقاف مؤقت في Supabase.
  Future<void> setPause(String userId, bool value) async {
    try {
      await _client.from(_tableName).upsert({
        'user_id': userId,
        'field_key': _keyPause,
        'value': value ? 'true' : 'false',
        'visibility': 'hidden',
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,field_key');
    } catch (e) {
      debugPrint('UserSettingsService.setPause error: $e');
    }
  }

  /// تحديث وقت آخر نشاط.
  Future<void> updateLastActive(String userId) async {
    try {
      await _client.from(_tableName).upsert({
        'user_id': userId,
        'field_key': _keyLastActive,
        'value': DateTime.now().toIso8601String(),
        'visibility': 'hidden',
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,field_key');
    } catch (e) {
      debugPrint('UserSettingsService.updateLastActive error: $e');
    }
  }

  /// هل المستخدم مفعّل الإيقاف المؤقت؟
  Future<bool> isPaused(String userId) async {
    try {
      final res = await _client
          .from(_tableName)
          .select('value')
          .eq('user_id', userId)
          .eq('field_key', _keyPause)
          .maybeSingle();
      if (res == null) return false;
      final v = (res as Map)['value'] as String?;
      return v == 'true';
    } catch (e) {
      debugPrint('UserSettingsService.isPaused error: $e');
      return false;
    }
  }

  /// قائمة user_id المفعل عندهم الإيقاف المؤقت.
  Future<Set<String>> getPausedUserIds() async {
    try {
      final list = await _client
          .from(_tableName)
          .select('user_id')
          .eq('field_key', _keyPause)
          .eq('value', 'true');
      final ids = <String>{};
      for (final row in list as List) {
        final id = (row as Map)['user_id'] as String?;
        if (id != null) ids.add(id);
      }
      return ids;
    } catch (e) {
      debugPrint('UserSettingsService.getPausedUserIds error: $e');
      return {};
    }
  }

  /// آخر نشاط لمستخدم (تاريخ أو null).
  Future<DateTime?> getLastActive(String userId) async {
    try {
      final res = await _client
          .from(_tableName)
          .select('value')
          .eq('user_id', userId)
          .eq('field_key', _keyLastActive)
          .maybeSingle();
      if (res == null) return null;
      final v = (res as Map)['value'] as String?;
      if (v == null || v.isEmpty) return null;
      return DateTime.tryParse(v);
    } catch (e) {
      debugPrint('UserSettingsService.getLastActive error: $e');
      return null;
    }
  }

  /// هل المستخدم متصل الآن (آخر نشاط خلال [withinMinutes] دقيقة).
  Future<bool> isOnline(String userId, {int withinMinutes = 5}) async {
    final last = await getLastActive(userId);
    if (last == null) return false;
    return DateTime.now().difference(last).inMinutes < withinMinutes;
  }

  /// حفظ إظهار آخر نشاط في Supabase.
  Future<void> setShowLastActive(String userId, bool value) async {
    try {
      await _client.from(_tableName).upsert({
        'user_id': userId,
        'field_key': _keyShowLastActive,
        'value': value ? 'true' : 'false',
        'visibility': 'hidden',
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,field_key');
    } catch (e) {
      debugPrint('UserSettingsService.setShowLastActive error: $e');
    }
  }

  /// هل مفعّل إظهار آخر نشاط؟
  Future<bool> getShowLastActive(String userId) async {
    try {
      final res = await _client
          .from(_tableName)
          .select('value')
          .eq('user_id', userId)
          .eq('field_key', _keyShowLastActive)
          .maybeSingle();
      if (res == null) return true; // افتراضي: مفعّل
      final v = (res as Map)['value'] as String?;
      return v != 'false';
    } catch (e) {
      debugPrint('UserSettingsService.getShowLastActive error: $e');
      return true;
    }
  }

  /// حالة التحقق بالـ selfie: null | 'submitted' | 'verified'
  Future<String?> getSelfieVerificationStatus(String userId) async {
    try {
      final res = await _client
          .from(_tableName)
          .select('value')
          .eq('user_id', userId)
          .eq('field_key', _keySelfieVerification)
          .maybeSingle();
      if (res == null) return null;
      return (res as Map)['value'] as String?;
    } catch (e) {
      debugPrint('UserSettingsService.getSelfieVerificationStatus error: $e');
      return null;
    }
  }

  /// إرسال صورة الـ selfie للتحقق.
  Future<void> submitSelfieVerification(String userId, File imageFile) async {
    try {
      final ext = imageFile.path.toLowerCase().endsWith('.png')
          ? '.png'
          : (imageFile.path.toLowerCase().endsWith('.webp') ? '.webp' : '.jpg');
      final path = '$userId/verification_selfie$ext';
      await _client.storage.from(_storageBucket).upload(
            path,
            imageFile,
            fileOptions: const FileOptions(upsert: true),
          );
      await _setVerificationSubmitted(userId);
    } catch (e) {
      debugPrint('UserSettingsService.submitSelfieVerification error: $e');
      rethrow;
    }
  }

  /// إرسال فيديو التحقق للمراجعة.
  Future<void> submitVerificationVideo(String userId, File videoFile) async {
    try {
      final path = '$userId/verification_video.mp4';
      await _client.storage.from(_storageBucket).upload(
            path,
            videoFile,
            fileOptions: const FileOptions(upsert: true),
          );
      await _setVerificationSubmitted(userId);
    } catch (e) {
      debugPrint('UserSettingsService.submitVerificationVideo error: $e');
      rethrow;
    }
  }

  Future<void> _setVerificationSubmitted(String userId) async {
    await _client.from(_tableName).upsert({
      'user_id': userId,
      'field_key': _keySelfieVerification,
      'value': 'submitted',
      'visibility': 'hidden',
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id,field_key');
  }

  /// هل تصفية التعليقات مفعّلة؟
  Future<bool> getCommentFilterEnabled(String userId) async {
    try {
      final res = await _client
          .from(_tableName)
          .select('value')
          .eq('user_id', userId)
          .eq('field_key', _keyCommentFilter)
          .maybeSingle();
      if (res == null) return false;
      final v = (res as Map)['value'] as String?;
      return v == 'true';
    } catch (e) {
      debugPrint('UserSettingsService.getCommentFilterEnabled error: $e');
      return false;
    }
  }

  /// تفعيل/تعطيل تصفية التعليقات.
  Future<void> setCommentFilterEnabled(String userId, bool value) async {
    try {
      await _client.from(_tableName).upsert({
        'user_id': userId,
        'field_key': _keyCommentFilter,
        'value': value ? 'true' : 'false',
        'visibility': 'hidden',
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,field_key');
    } catch (e) {
      debugPrint('UserSettingsService.setCommentFilterEnabled error: $e');
    }
  }

  /// وحدات القياس: 'km_cm' | 'mi_ft'
  Future<String?> getUnits(String userId) async {
    try {
      final res = await _client
          .from(_tableName)
          .select('value')
          .eq('user_id', userId)
          .eq('field_key', _keyUnits)
          .maybeSingle();
      if (res == null) return null;
      return (res as Map)['value'] as String?;
    } catch (e) {
      debugPrint('UserSettingsService.getUnits error: $e');
      return null;
    }
  }

  /// حفظ وحدات القياس.
  Future<void> setUnits(String userId, String value) async {
    try {
      await _client.from(_tableName).upsert({
        'user_id': userId,
        'field_key': _keyUnits,
        'value': value,
        'visibility': 'hidden',
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,field_key');
    } catch (e) {
      debugPrint('UserSettingsService.setUnits error: $e');
    }
  }

  /// تفضيلات الخصوصية.
  Future<Map<String, dynamic>?> getPrivacyPreferences(String userId) async {
    try {
      final res = await _client
          .from(_tableName)
          .select('field_key, value')
          .eq('user_id', userId)
          .inFilter('field_key', [_keyPrivacyVisibility, _keyPrivacyShowDistance]);
      if ((res as List).isEmpty) return null;
      final map = <String, dynamic>{};
      for (final row in res as List) {
        final key = (row as Map)['field_key'] as String?;
        final value = (row)['value'] as String?;
        if (key == _keyPrivacyVisibility) map['visibility'] = value ?? 'everyone';
        if (key == _keyPrivacyShowDistance) map['show_distance'] = value != 'false';
      }
      return map.isEmpty ? null : map;
    } catch (e) {
      debugPrint('UserSettingsService.getPrivacyPreferences error: $e');
      return null;
    }
  }

  /// حفظ تفضيلات الخصوصية.
  Future<void> setPrivacyPreferences(
    String userId, {
    required String visibility,
    required bool showDistance,
  }) async {
    try {
      await _client.from(_tableName).upsert({
        'user_id': userId,
        'field_key': _keyPrivacyVisibility,
        'value': visibility,
        'visibility': 'hidden',
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,field_key');
      await _client.from(_tableName).upsert({
        'user_id': userId,
        'field_key': _keyPrivacyShowDistance,
        'value': showDistance ? 'true' : 'false',
        'visibility': 'hidden',
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,field_key');
    } catch (e) {
      debugPrint('UserSettingsService.setPrivacyPreferences error: $e');
    }
  }

  /// ضمير المخاطب في رسالة الهدية: 'male' (له) أو 'female' (لها). الافتراضي 'male'.
  Future<String> getPreferredRecipientPronoun(String userId) async {
    try {
      final res = await _client
          .from(_tableName)
          .select('value')
          .eq('user_id', userId)
          .eq('field_key', _keyPreferredRecipientPronoun)
          .maybeSingle();
      if (res == null) return 'male';
      final v = (res as Map)['value'] as String?;
      return (v == 'female') ? 'female' : 'male';
    } catch (e) {
      debugPrint('UserSettingsService.getPreferredRecipientPronoun error: $e');
      return 'male';
    }
  }

  /// حفظ ضمير المخاطب: 'male' أو 'female'
  Future<void> setPreferredRecipientPronoun(String userId, String value) async {
    try {
      await _client.from(_tableName).upsert({
        'user_id': userId,
        'field_key': _keyPreferredRecipientPronoun,
        'value': value == 'female' ? 'female' : 'male',
        'visibility': 'hidden',
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,field_key');
    } catch (e) {
      debugPrint('UserSettingsService.setPreferredRecipientPronoun error: $e');
    }
  }
}
