import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// خدمة تصدير بيانات المستخدم (GDPR - تحميل بياناتي).
class ExportDataService {
  ExportDataService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// تصدير جميع بيانات المستخدم كـ JSON.
  Future<String> exportUserData(String userId) async {
    final data = <String, dynamic>{
      'exported_at': DateTime.now().toIso8601String(),
      'user_id': userId,
    };

    try {
      final user = _client.auth.currentUser;
      if (user != null) {
        data['auth'] = {
          'email': user.email,
          'phone': user.phone,
          'created_at': user.createdAt,
          'last_sign_in_at': user.lastSignInAt,
        };
      }
    } catch (e) {
      debugPrint('ExportDataService: auth $e');
    }

    try {
      final profileRes = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (profileRes != null) {
        data['profile'] = profileRes;
      }
    } catch (e) {
      debugPrint('ExportDataService: profiles $e');
    }

    try {
      final fieldsRes = await _client
          .from('user_profile_fields')
          .select()
          .eq('user_id', userId);
      data['profile_fields'] = fieldsRes;
    } catch (e) {
      debugPrint('ExportDataService: user_profile_fields $e');
    }

    try {
      final answersRes = await _client
          .from('profile_answers')
          .select()
          .eq('user_id', userId);
      data['profile_answers'] = answersRes;
    } catch (e) {
      debugPrint('ExportDataService: profile_answers $e');
    }

    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(data);
  }
}
