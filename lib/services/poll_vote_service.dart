import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// خدمة تصويت الاستطلاعات: إرسال صوت، جلب عدد الأصوات، جلب صوت المستخدم الحالي.
class PollVoteService {
  PollVoteService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  static const String _tableName = 'poll_votes';

  /// إرسال أو تغيير صوت المستخدم الحالي (خيار واحد لكل استطلاع).
  /// يُرجع true عند النجاح.
  Future<bool> submitVote({
    required String profileAnswerId,
    required int optionIndex,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return false;

      final existing = await _client
          .from(_tableName)
          .select('id')
          .eq('profile_answer_id', profileAnswerId)
          .eq('voter_user_id', userId)
          .maybeSingle();

      if (existing != null) {
        await _client
            .from(_tableName)
            .update({'option_index': optionIndex})
            .eq('profile_answer_id', profileAnswerId)
            .eq('voter_user_id', userId);
      } else {
        await _client.from(_tableName).insert({
          'profile_answer_id': profileAnswerId,
          'voter_user_id': userId,
          'option_index': optionIndex,
        });
      }
      return true;
    } catch (e) {
      debugPrint('PollVoteService.submitVote error: $e');
      return false;
    }
  }

  /// عدد الأصوات لكل خيار بالترتيب: [count0, count1, count2, ...].
  Future<List<int>> getVoteCounts(String profileAnswerId) async {
    try {
      final list = await _client
          .from(_tableName)
          .select('option_index')
          .eq('profile_answer_id', profileAnswerId);

      final counts = <int>[];
      for (final row in list as List) {
        final idx = (row['option_index'] as num?)?.toInt() ?? 0;
        while (counts.length <= idx) {
          counts.add(0);
        }
        counts[idx]++;
      }
      return counts;
    } catch (e) {
      debugPrint('PollVoteService.getVoteCounts error: $e');
      return [];
    }
  }

  /// فهرس الخيار الذي صوّت له المستخدم الحالي، أو null إن لم يصوّت.
  Future<int?> getMyVote(String profileAnswerId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;

      final res = await _client
          .from(_tableName)
          .select('option_index')
          .eq('profile_answer_id', profileAnswerId)
          .eq('voter_user_id', userId)
          .maybeSingle();

      if (res == null) return null;
      return (res['option_index'] as num?)?.toInt();
    } catch (e) {
      debugPrint('PollVoteService.getMyVote error: $e');
      return null;
    }
  }
}
