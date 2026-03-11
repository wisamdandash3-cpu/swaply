import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// تخزين معرّفات الهدايا الواردة التي عُرِضت في شاشة "وصلك شعور جاد" لعدم تكرار العرض.
class GiftReceivedStorage {
  static const String _key = 'gift_received_shown_ids';

  /// هل عُرِضت هذه الهدية مسبقاً؟
  static Future<bool> hasBeenShown(String profileLikeId) async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json == null) return false;
    try {
      final list = jsonDecode(json) as List<dynamic>?;
      return list?.cast<String>().contains(profileLikeId) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// تسجيل أن الهدية عُرِضت.
  static Future<void> markAsShown(String profileLikeId) async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    List<String> list = [];
    if (json != null) {
      try {
        list = (jsonDecode(json) as List<dynamic>?)?.cast<String>() ?? [];
      } catch (_) {}
    }
    if (!list.contains(profileLikeId)) {
      list.add(profileLikeId);
      if (list.length > 200) list = list.sublist(list.length - 150);
      await prefs.setString(_key, jsonEncode(list));
    }
  }

  /// قراءة معرّفات الهدايا المعروضة مرة واحدة (تجنب N استدعاء لـ SharedPreferences).
  static Future<Set<String>> _getShownIds() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json == null) return {};
    try {
      final list = jsonDecode(json) as List<dynamic>?;
      return list?.cast<String>().toSet() ?? {};
    } catch (_) {
      return {};
    }
  }

  /// تصفية قائمة الهدايا لإرجاع التي لم تُعرض بعد.
  static Future<List<T>> filterUnshown<T>(List<T> gifts, String Function(T) idOf) async {
    if (gifts.isEmpty) return [];
    final shown = await _getShownIds();
    return gifts.where((g) => !shown.contains(idOf(g))).toList();
  }
}
