import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile_like.dart';

/// خدمة الإعجاب بعنصر محدد (Interactive Profiles).
/// عند ضغط زر الإعجاب، نرسل [itemId] (سواء كان صورة أو إجابة نصية).
class ProfileLikeService {
  ProfileLikeService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  static const String _tableName = 'profile_likes';

  /// إرسال إعجاب بعنصر محدد.
  /// إذا كان الإعجاب موجوداً مسبقاً (تكرار) نعيد السجل الحالي بدون خطأ.
  Future<ProfileLike> likeItem({
    required String toUserId,
    required String itemId,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('User must be signed in to like');
    }

    try {
      final list = await _client
          .from(_tableName)
          .insert({
            'from_user_id': userId,
            'to_user_id': toUserId,
            'item_id': itemId,
          })
          .select();

      final lst = list as List;
      if (lst.isNotEmpty) {
        return ProfileLike.fromJson(lst.first as Map<String, dynamic>);
      }
    } on PostgrestException catch (e) {
      final isDuplicate = e.code == '23505' ||
          (e.message.contains('duplicate key') || e.message.contains('unique constraint'));
      if (isDuplicate) {
        final existing = await _client
            .from(_tableName)
            .select()
            .eq('from_user_id', userId)
            .eq('to_user_id', toUserId)
            .eq('item_id', itemId)
            .limit(1);
        final lst = existing as List;
        if (lst.isNotEmpty) {
          return ProfileLike.fromJson(lst.first as Map<String, dynamic>);
        }
      }
      rethrow;
    }

    throw StateError('Like insert failed');
  }

  /// تسجيل إرسال هدية (وردة/خاتم/قهوة) بعد المطابقة — يُنشئ سجلاً في profile_likes.
  Future<ProfileLike> sendMatchGift({
    required String toUserId,
    required String giftType,
    required String message,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('User must be signed in to send gift');
    }

    final list = await _client.from(_tableName).insert({
      'from_user_id': userId,
      'to_user_id': toUserId,
      'item_id': null,
      'gift_type': giftType,
      'gift_message': message.trim().isEmpty ? null : message.trim(),
    }).select();

    final lst = list as List;
    if (lst.isEmpty) throw StateError('Gift insert failed');
    return ProfileLike.fromJson(lst.first as Map<String, dynamic>);
  }

  /// إلغاء إعجاب بعنصر محدد.
  Future<void> unlikeItem({
    required String toUserId,
    required String itemId,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client.from(_tableName).delete().match({
      'from_user_id': userId,
      'to_user_id': toUserId,
      'item_id': itemId,
    });
  }

  /// التحقق إن كان المستخدم الحالي قد أعجب بهذا العنصر.
  Future<bool> hasLikedItem({
    required String toUserId,
    required String itemId,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    final list = await _client
        .from(_tableName)
        .select('id')
        .eq('from_user_id', userId)
        .eq('to_user_id', toUserId)
        .eq('item_id', itemId)
        .limit(1);

    return (list as List).isNotEmpty;
  }

  /// جلب الإعجابات الواردة للمستخدم الحالي (مع item_id لمعرفة أي عنصر أُعجب به).
  Future<List<ProfileLike>> getIncomingLikes() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final list = await _client
        .from(_tableName)
        .select()
        .eq('to_user_id', userId)
        .order('created_at', ascending: false);

    return (list as List)
        .map((e) => ProfileLike.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// إعجابات واردة من أشخاص لم أُعجب بهم بعد (لشاشة "معجب بك" — عند الإعجاب بالمقابل يُزال من القائمة).
  Future<List<ProfileLike>> getIncomingUnmatchedLikes() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];
    final incoming = await getIncomingLikes();
    final outgoing = await getOutgoingLikes();
    final outgoingToIds = outgoing.map((e) => e.toUserId).toSet();
    return incoming.where((e) => !outgoingToIds.contains(e.fromUserId)).toList();
  }

  /// عدد من أعجبوا بي ولم أُعجب بهم بعد (للشارة على "معجب بك" — يتناقص عند الإعجاب بالمقابل/المطابقة).
  Future<int> getIncomingUnmatchedCount() async {
    final list = await getIncomingUnmatchedLikes();
    return list.map((e) => e.fromUserId).toSet().length;
  }

  /// جلب الهدايا الواردة للمستخدم الحالي (سجلات فيها gift_type).
  Future<List<ProfileLike>> getReceivedGifts() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final list = await _client
        .from(_tableName)
        .select()
        .eq('to_user_id', userId)
        .not('gift_type', 'is', null)
        .order('created_at', ascending: false);

    return (list as List)
        .map((e) => ProfileLike.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// هل أعجبني هذا المستخدم مسبقاً؟ (للتحقق من المطابقة المتبادلة).
  /// إذا أعجب بعدة عناصر نعتبره "أعجبني" ولا نرمي خطأ.
  Future<bool> hasLikedMe(String fromUserId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    final list = await _client
        .from(_tableName)
        .select('id')
        .eq('from_user_id', fromUserId)
        .eq('to_user_id', userId)
        .limit(1);

    return (list as List).isNotEmpty;
  }

  /// جلب الإعجابات المرسلة من المستخدم الحالي (لاكتشاف المطابقات).
  Future<List<ProfileLike>> getOutgoingLikes() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final list = await _client
        .from(_tableName)
        .select()
        .eq('from_user_id', userId)
        .order('created_at', ascending: false);

    return (list as List)
        .map((e) => ProfileLike.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// معرّفات المستخدمين الذين تحققت بيني وبينهم مطابقة (أعجبني وأعجبتهم).
  Future<List<String>> getMutualMatchPartnerIds() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];
    final incoming = await getIncomingLikes();
    final outgoing = await getOutgoingLikes();
    final iLikedThem = outgoing.map((e) => e.toUserId).toSet();
    final theyLikedMe = incoming.map((e) => e.fromUserId).toSet();
    return iLikedThem.where((id) => theyLikedMe.contains(id)).toList();
  }
}
