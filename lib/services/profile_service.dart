import 'package:supabase_flutter/supabase_flutter.dart';

/// خدمة جدول profiles (اللغات، الموقع، إلخ).
class ProfileService {
  ProfileService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  static const String _tableName = 'profiles';

  /// حفظ موقع المستخدم في جدول profiles.
  /// [userId] = user_id، [lat] و [lng] الإحداثيات، [city] و [country] اختياريان.
  Future<void> updateLocation(
    String userId, {
    required double lat,
    required double lng,
    String? city,
    String? country,
  }) async {
    try {
      final data = <String, dynamic>{
        'user_id': userId,
        'latitude': lat,
        'longitude': lng,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (city != null && city.isNotEmpty) data['city'] = city;
      if (country != null && country.isNotEmpty) data['country'] = country;
      await _client.from(_tableName).upsert(data, onConflict: 'user_id');
    } catch (_) {
      // جدول profiles قد لا يكون موجوداً
    }
  }

  /// جلب موقع المستخدم (latitude, longitude) من جدول profiles.
  /// [userId] = user_id في profiles (مثل profile_id من profile_answers).
  Future<({double lat, double lng})?> getLocation(String userId) async {
    try {
      final res = await _client
          .from(_tableName)
          .select('latitude, longitude')
          .eq('user_id', userId)
          .maybeSingle();
      if (res == null) return null;
      final lat = (res as Map)['latitude'];
      final lng = (res as Map)['longitude'];
      if (lat is num && lng is num) {
        return (lat: lat.toDouble(), lng: lng.toDouble());
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// حفظ المنطقة الزمنية للمستخدم (عمود timezone في profiles).
  /// [timezoneOffsetMinutes] انحراف التوقيت عن UTC بالدقائق (مثلاً 120 لـ UTC+2).
  Future<void> updateTimezone(String userId, int timezoneOffsetMinutes) async {
    try {
      final sign = timezoneOffsetMinutes >= 0 ? '+' : '-';
      final hours = (timezoneOffsetMinutes.abs() / 60).floor();
      await _client.from(_tableName).update({
        'timezone': 'UTC$sign$hours',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('user_id', userId);
    } catch (_) {}
  }

  /// تحديث اللغات في جدول profiles.
  /// [languagesText] نص مثل "Arabic, English" أو "العربية، الإنجليزية".
  Future<void> updateLanguages(String userId, String languagesText) async {
    final list = languagesText
        .split(RegExp(r'[,،،\n]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    try {
      await _client.from(_tableName).upsert({
        'user_id': userId,
        'languages': list,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');
    } catch (_) {
      // جدول profiles قد لا يكون موجوداً
    }
  }
}
