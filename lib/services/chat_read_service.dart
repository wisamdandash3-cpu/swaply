import 'package:shared_preferences/shared_preferences.dart';

import 'message_service.dart';

/// تتبع آخر قراءة لكل محادثة (محلياً) لتحديد الرسائل غير المقروءة.
class ChatReadService {
  ChatReadService({
    MessageService? messageService,
  }) : _messageService = messageService ?? MessageService();

  final MessageService _messageService;
  static const String _prefix = 'chat_last_seen_';

  String _key(String userId, String partnerId) =>
      '$_prefix${userId}_$partnerId';

  /// وضع علامة "مقروء" عند فتح المحادثة.
  Future<void> markConversationAsRead(String userId, String partnerId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(userId, partnerId), DateTime.now().toIso8601String());
  }

  /// وقت آخر قراءة لهذه المحادثة (بدون تعديل) — لاستخدامه في التمرير إلى آخر رسالة غير مقروءة.
  Future<DateTime?> getLastSeen(String userId, String partnerId) async {
    final prefs = await SharedPreferences.getInstance();
    final lastSeenStr = prefs.getString(_key(userId, partnerId));
    if (lastSeenStr == null) return null;
    return DateTime.tryParse(lastSeenStr);
  }

  /// عدد الرسائل غير المقروءة من الشريك في هذه المحادثة.
  Future<int> getUnreadCount(String userId, String partnerId) async {
    final prefs = await SharedPreferences.getInstance();
    final lastSeenStr = prefs.getString(_key(userId, partnerId));
    DateTime? lastSeen;
    if (lastSeenStr != null) {
      lastSeen = DateTime.tryParse(lastSeenStr);
    }

    final messages = await _messageService.getMessagesBetween(userId, partnerId);
    final fromPartner = messages.where((m) =>
        m.senderId == partnerId && m.receiverId == userId);

    if (lastSeen == null) {
      // لم يفتح المحادثة من قبل: كل رسائل الشريك غير مقروءة
      return fromPartner.length;
    }

    return fromPartner.where((m) => m.createdAt.isAfter(lastSeen!)).length;
  }

  /// خريطة: partnerId -> عدد الرسائل غير المقروءة
  Future<Map<String, int>> getUnreadCountsByPartner(
    String userId,
    List<String> partnerIds,
  ) async {
    final result = <String, int>{};
    for (final id in partnerIds) {
      result[id] = await getUnreadCount(userId, id);
    }
    return result;
  }
}
