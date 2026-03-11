import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'profile_display_service.dart';

/// إدارة قائمة الحظر: حظر وإلغاء حظر وعرض المحظورين.
class BlockService {
  BlockService({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  final ProfileDisplayService _profileDisplay = ProfileDisplayService();
  static const String _tableName = 'blocked_users';

  /// قائمة المحظورين (user_id, displayName, avatarUrl, isVerified).
  Future<List<({String id, String name, String? avatarUrl, bool isVerified})>> getBlockedList(String blockerId) async {
    try {
      final list = await _client
          .from(_tableName)
          .select('blocked_id')
          .eq('blocker_id', blockerId)
          .order('created_at', ascending: false);

      final ids = (list as List).map((e) => e['blocked_id'] as String).toList();
      if (ids.isEmpty) return [];

      final results = <({String id, String name, String? avatarUrl, bool isVerified})>[];
      for (final id in ids) {
        final info = await _profileDisplay.getDisplayInfo(id);
        results.add((id: id, name: info.displayName, avatarUrl: info.avatarUrl, isVerified: info.isVerified));
      }
      return results;
    } catch (e) {
      debugPrint('BlockService.getBlockedList error: $e');
      return [];
    }
  }

  /// حظر مستخدم.
  Future<bool> block(String blockerId, String blockedId) async {
    try {
      await _client.from(_tableName).upsert({
        'blocker_id': blockerId,
        'blocked_id': blockedId,
      }, onConflict: 'blocker_id,blocked_id');
      return true;
    } catch (e) {
      debugPrint('BlockService.block error: $e');
      return false;
    }
  }

  /// إلغاء حظر مستخدم.
  Future<bool> unblock(String blockerId, String blockedId) async {
    try {
      await _client.from(_tableName).delete().match({
        'blocker_id': blockerId,
        'blocked_id': blockedId,
      });
      return true;
    } catch (e) {
      debugPrint('BlockService.unblock error: $e');
      return false;
    }
  }

  /// معرفات المحظورين (للاستبعاد من الاكتشاف).
  Future<Set<String>> getBlockedIds(String blockerId) async {
    try {
      final list = await _client
          .from(_tableName)
          .select('blocked_id')
          .eq('blocker_id', blockerId);
      return (list as List).map((e) => e['blocked_id'] as String).toSet();
    } catch (e) {
      debugPrint('BlockService.getBlockedIds error: $e');
      return {};
    }
  }

  /// من حظرني (معرفات من حظروني — لاستبعادهم من قائمة المحادثات).
  Future<Set<String>> getWhoBlockedMe(String userId) async {
    try {
      final list = await _client
          .from(_tableName)
          .select('blocker_id')
          .eq('blocked_id', userId);
      return (list as List).map((e) => e['blocker_id'] as String).toSet();
    } catch (e) {
      debugPrint('BlockService.getWhoBlockedMe error: $e');
      return {};
    }
  }

  /// هل [blockerId] حظر [blockedId]؟
  Future<bool> hasBlocked(String blockerId, String blockedId) async {
    final blocked = await getBlockedIds(blockerId);
    return blocked.contains(blockedId);
  }
}
