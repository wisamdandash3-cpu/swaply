import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// عدد رسائل البث الجماعي غير المقروءة (created_at بعد آخر تاريخ مشاهدة).
Future<int> getBroadcastUnreadCount() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final lastSeenStr = prefs.getString('broadcast_last_seen_at');
    DateTime? lastSeen;
    if (lastSeenStr != null) lastSeen = DateTime.tryParse(lastSeenStr);

    final list = await Supabase.instance.client
        .from('broadcast_messages')
        .select('created_at')
        .order('created_at', ascending: false);

    if (list.isEmpty) return 0;
    if (lastSeen == null) return list.length;

    int count = 0;
    for (final row in list) {
      final created = row['created_at'] as String?;
      if (created == null) continue;
      final dt = DateTime.tryParse(created);
      if (dt != null && dt.isAfter(lastSeen)) count++;
    }
    return count;
  } catch (_) {
    return 0;
  }
}

/// آخر تاريخ لرسالة بث (لترتيب محادثة Swaply في القائمة زمنياً).
Future<DateTime?> getLastBroadcastMessageAt() async {
  try {
    final list = await Supabase.instance.client
        .from('broadcast_messages')
        .select('created_at')
        .order('created_at', ascending: false)
        .limit(1);
    if (list.isEmpty) return null;
    final created = list.first['created_at'] as String?;
    return created != null ? DateTime.tryParse(created) : null;
  } catch (_) {
    return null;
  }
}
