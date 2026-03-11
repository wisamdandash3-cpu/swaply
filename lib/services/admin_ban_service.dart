import 'package:supabase_flutter/supabase_flutter.dart';

/// يتحقق مما إذا كان المستخدم الحالي محظوراً إدارياً.
class AdminBanService {
  AdminBanService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// يُرجع true إذا كان المستخدم محظوراً، false إذا لم يكن.
  Future<bool> isCurrentUserBanned() async {
    try {
      final res = await _client.rpc('is_current_user_banned');
      return res == true;
    } catch (_) {
      return false;
    }
  }
}
