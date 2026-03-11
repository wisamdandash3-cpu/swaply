import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// خدمة حفظ وجلب حقول البروفايل (العمل، التعليم، إلخ).
class ProfileFieldsService {
  ProfileFieldsService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  static const String _tableName = 'user_profile_fields';

  /// جلب كل الحقول لـ user_id.
  /// On failure, logs the error and returns an empty map.
  Future<Map<String, ({String value, String visibility})>> getFields(String userId) async {
    try {
      final list = await _client
          .from(_tableName)
          .select('field_key, value, visibility')
          .eq('user_id', userId);

      final map = <String, ({String value, String visibility})>{};
      for (final e in list as List) {
        final row = e as Map<String, dynamic>;
        map[row['field_key'] as String] = (
          value: (row['value'] as String?) ?? '',
          visibility: (row['visibility'] as String?) ?? 'hidden',
        );
      }
      return map;
    } catch (e, st) {
      debugPrint('ProfileFieldsService.getFields failed: userId=$userId');
      debugPrint('ProfileFieldsService.getFields error: $e');
      debugPrint('ProfileFieldsService.getFields stack: $st');
      return {};
    }
  }

  /// نتيجة الحفظ: success صحيح عند النجاح؛ عند الفشل errorMessage يحتوي رسالة (مثلاً حد العمر).
  Future<({bool success, String? errorMessage})> saveFieldWithMessage({
    required String userId,
    required String fieldKey,
    required String value,
    required String visibility,
  }) async {
    try {
      await _client.from(_tableName).upsert({
        'user_id': userId,
        'field_key': fieldKey,
        'value': value,
        'visibility': visibility,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,field_key');
      return (success: true, errorMessage: null);
    } on PostgrestException catch (e) {
      debugPrint('ProfileFieldsService.saveField failed: field_key=$fieldKey, error: $e');
      if (e.code == 'PGRST302' || (e.message.contains('age_below_minimum'))) {
        return (success: false, errorMessage: 'age_minimum_18');
      }
      return (success: false, errorMessage: e.message);
    } catch (e, st) {
      debugPrint('ProfileFieldsService.saveField failed: userId=$userId, field_key=$fieldKey');
      debugPrint('ProfileFieldsService.saveField error: $e');
      debugPrint('ProfileFieldsService.saveField stack: $st');
      return (success: false, errorMessage: e.toString());
    }
  }

  /// حفظ حقل واحد. يُرجع true عند النجاح و false عند الفشل.
  /// للتحقق من رسالة الخطأ (مثل حد العمر) استخدم saveFieldWithMessage.
  Future<bool> saveField({
    required String userId,
    required String fieldKey,
    required String value,
    required String visibility,
  }) async {
    final result = await saveFieldWithMessage(
      userId: userId,
      fieldKey: fieldKey,
      value: value,
      visibility: visibility,
    );
    return result.success;
  }
}
