import 'package:supabase_flutter/supabase_flutter.dart';

/// استدعاء Edge Function لحذف الحساب (GDPR).
/// يتطلب نشر الدالة delete-account في Supabase.
class DeleteAccountService {
  DeleteAccountService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  static const String _functionName = 'delete-account';

  /// حذف حساب المستخدم الحالي. يُرجع null عند النجاح ورسالة خطأ عند الفشل.
  Future<String?> deleteCurrentUser() async {
    if (_client.auth.currentUser == null) {
      return 'Not signed in';
    }
    try {
      final res = await _client.functions.invoke(_functionName);
      if (res.status == 200) return null;
      final data = res.data;
      if (data is Map && data['error'] != null) {
        return data['error'] as String?;
      }
      return res.status.toString();
    } catch (e) {
      return e.toString();
    }
  }
}
