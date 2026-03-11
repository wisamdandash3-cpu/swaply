import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/chat_message.dart';

/// نتيجة إرسال رسالة: إما خطأ أو معرّف الرسالة المُنشأة.
class SendMessageResult {
  const SendMessageResult({this.error, this.messageId});
  final String? error;
  final String? messageId;
  bool get isOk => error == null && messageId != null;
}

/// عنصر من قائمة المحادثات (شريك، آخر رسالة، عدد غير المقروءة).
class ConversationListEntry {
  const ConversationListEntry({
    required this.partnerId,
    this.lastMessageAt,
    this.unreadCount = 0,
  });
  final String partnerId;
  final DateTime? lastMessageAt;
  final int unreadCount;
}

/// حفظ وجلب رسائل الدردشة من Supabase.
class MessageService {
  MessageService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  static const String _tableName = 'messages';

  /// إرسال رسالة. يُرجع نتيجة تحتوي معرّف الرسالة عند النجاح أو نص الخطأ عند الفشل (لحذفها لاحقاً من البيانات).
  /// [photoUrl] رابط الصورة أو نوع الهدية (rose_gift إلخ). إن لم يكن عمود photo_url موجوداً في الجدول يُرسل المحتوى فقط.
  /// [replyToId], [replyToContent], [replyToSenderId], [replyToPhotoUrl] لرسالة الرد (عرض "على ماذا رد" وأيقونة الهدية داخل الفقاعة).
  Future<SendMessageResult> sendMessage({
    required String senderId,
    required String receiverId,
    required String content,
    String? photoUrl,
    String? replyToId,
    String? replyToContent,
    String? replyToSenderId,
    String? replyToPhotoUrl,
  }) async {
    final data = <String, dynamic>{
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content': content.trim(),
    };
    if (photoUrl != null && photoUrl.trim().isNotEmpty) {
      data['photo_url'] = photoUrl.trim();
    }
    if (replyToId != null && replyToId.isNotEmpty) {
      data['reply_to_id'] = replyToId;
    }
    if (replyToContent != null) {
      data['reply_to_content'] = replyToContent.length > 500
          ? '${replyToContent.substring(0, 500)}...'
          : replyToContent;
    }
    if (replyToSenderId != null && replyToSenderId.isNotEmpty) {
      data['reply_to_sender_id'] = replyToSenderId;
    }
    if (replyToPhotoUrl != null && replyToPhotoUrl.trim().isNotEmpty) {
      data['reply_to_photo_url'] = replyToPhotoUrl.trim();
    }
    try {
      final res = await _client.from(_tableName).insert(data).select('id').single() as Map<String, dynamic>?;
      final id = res?['id'] as String?;
      return SendMessageResult(messageId: id);
    } catch (e, st) {
      if (e is PostgrestException &&
          (e.code == 'PGRST204' || (e.message.contains('photo_url') || e.message.contains('schema cache')))) {
        data.remove('photo_url');
        try {
          final res = await _client.from(_tableName).insert(data).select('id').single() as Map<String, dynamic>?;
          final id = res?['id'] as String?;
          return SendMessageResult(messageId: id);
        } catch (e2, st2) {
          debugPrint('MessageService.sendMessage error: $e2');
          debugPrint('MessageService.sendMessage stack: $st2');
          final msg = e2.toString();
          return SendMessageResult(error: msg.length > 80 ? '${msg.substring(0, 80)}...' : msg);
        }
      }
      final msg = e.toString();
      final errBody = e is PostgrestException ? e.message : msg;
      final isReplyColumnError = errBody.contains('reply_to_content') ||
          errBody.contains('reply_to_id') ||
          errBody.contains('reply_to_sender_id') ||
          errBody.contains('reply_to_photo_url');
      if (isReplyColumnError && (data.containsKey('reply_to_id') || data.containsKey('reply_to_content') || data.containsKey('reply_to_sender_id') || data.containsKey('reply_to_photo_url'))) {
        data.remove('reply_to_id');
        data.remove('reply_to_content');
        data.remove('reply_to_sender_id');
        data.remove('reply_to_photo_url');
        try {
          final res = await _client.from(_tableName).insert(data).select('id').single() as Map<String, dynamic>?;
          final id = res?['id'] as String?;
          return SendMessageResult(messageId: id);
        } catch (e2, _) {
          debugPrint('MessageService.sendMessage error: $e2');
          final m = e2.toString();
          return SendMessageResult(error: m.length > 80 ? '${m.substring(0, 80)}...' : m);
        }
      }
      debugPrint('MessageService.sendMessage error: $e');
      debugPrint('MessageService.sendMessage stack: $st');
      if (msg.contains('does not exist') || msg.contains('relation') || msg.contains('messages')) {
        return const SendMessageResult(error: 'جدول الرسائل غير موجود. شغّل ملف supabase/messages_table.sql في Supabase SQL Editor.');
      }
      if (msg.contains('policy') || msg.contains('row-level security') || msg.contains('RLS')) {
        return const SendMessageResult(error: 'صلاحيات غير كافية. تحقق من سياسات RLS لجدول messages.');
      }
      if (msg.contains('rate_limit') || (e is PostgrestException && e.code == 'PGRST301')) {
        return const SendMessageResult(error: 'تجاوزت حد الرسائل. حاول لاحقاً.');
      }
      return SendMessageResult(error: msg.length > 80 ? '${msg.substring(0, 80)}...' : msg);
    }
  }

  /// رسائل المحادثة بين مستخدمين (مرتبة من الأقدم للأحدث).
  Future<List<ChatMessage>> getMessagesBetween(String userId, String otherUserId) async {
    try {
      final a = await _client
          .from(_tableName)
          .select()
          .eq('sender_id', userId)
          .eq('receiver_id', otherUserId);
      final b = await _client
          .from(_tableName)
          .select()
          .eq('sender_id', otherUserId)
          .eq('receiver_id', userId);
      final list = [...(a as List), ...(b as List)];
      list.sort((x, y) =>
          (DateTime.parse((x as Map)['created_at'] as String))
              .compareTo(DateTime.parse((y as Map)['created_at'] as String)));
      return list
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('MessageService.getMessagesBetween error: $e');
      return [];
    }
  }

  /// حذف رسالة واحدة بالمعرّف (للطرفين). صلاحية الحذف تحددها RLS.
  /// يُرجع true فقط إذا تم حذف صف فعلياً من قاعدة البيانات (لا نزيل من الواجهة إلا عند التأكد).
  Future<bool> deleteMessage(String messageId) async {
    if (messageId.isEmpty || messageId.startsWith('temp-')) {
      debugPrint('MessageService.deleteMessage: skipping temp or empty id');
      return false;
    }
    try {
      // إرجاع الصفوف المحذوفة للتأكد من أن الحذف تم فعلياً (وإلا تظهر الرسائل مرة أخرى عند إعادة فتح المحادثة).
      final res = await _client
          .from(_tableName)
          .delete()
          .eq('id', messageId)
          .select('id');
      final list = res as List;
      if (list.isNotEmpty) return true;
      debugPrint('MessageService.deleteMessage: no row deleted for id=$messageId (RLS or missing row?)');
      return false;
    } catch (e, st) {
      debugPrint('MessageService.deleteMessage error: $e');
      debugPrint('MessageService.deleteMessage stack: $st');
      return false;
    }
  }

  /// حذف كل رسائل المحادثة بين المستخدم الحالي والطرف الآخر (يُستدعى عند السحب للحذف).
  Future<void> deleteConversation(String currentUserId, String partnerId) async {
    try {
      await _client.from(_tableName).delete().eq('sender_id', currentUserId).eq('receiver_id', partnerId);
      await _client.from(_tableName).delete().eq('sender_id', partnerId).eq('receiver_id', currentUserId);
    } catch (e) {
      debugPrint('MessageService.deleteConversation error: $e');
    }
  }

  /// نتيجة عنصر من قائمة المحادثات (من RPC get_conversation_list بعد migration 015).
  static ConversationListEntry? parseConversationEntry(Map<String, dynamic> row) {
    final partnerId = row['partner_id'] as String?;
    if (partnerId == null) return null;
    final lastAt = row['last_message_at'] as String?;
    final unread = row['unread_count'];
    return ConversationListEntry(
      partnerId: partnerId,
      lastMessageAt: lastAt != null ? DateTime.tryParse(lastAt) : null,
      unreadCount: unread is int ? unread : (unread is num ? unread.toInt() : 0),
    );
  }

  /// قائمة المحادثات مرتبة حسب آخر رسالة مع عدد غير المقروءة (يتطلب migration 015).
  Future<List<ConversationListEntry>> getConversationList(String currentUserId) async {
    try {
      final res = await _client.rpc(
        'get_conversation_list',
        params: {'p_user_id': currentUserId},
      );
      if (res is! List) return [];
      final list = <ConversationListEntry>[];
      for (final e in res) {
        if (e is Map<String, dynamic>) {
          final entry = parseConversationEntry(e);
          if (entry != null) list.add(entry);
        }
      }
      return list;
    } catch (e) {
      debugPrint('MessageService.getConversationList error: $e');
      return [];
    }
  }

  /// وضع رسائل محادثة كمقروءة (يتطلب migration 015).
  Future<int> markConversationRead(String receiverId, String senderId) async {
    try {
      final res = await _client.rpc(
        'mark_conversation_read',
        params: {'p_receiver_id': receiverId, 'p_sender_id': senderId},
      );
      return res is int ? res : 0;
    } catch (e) {
      debugPrint('MessageService.markConversationRead error: $e');
      return 0;
    }
  }

  /// قائمة معرّفات المستخدمين الذين تبادلت معهم رسائل (لعرض قائمة المحادثات).
  Future<List<String>> getConversationPartnerIds(String currentUserId) async {
    try {
      final sent = await _client
          .from(_tableName)
          .select('receiver_id')
          .eq('sender_id', currentUserId);
      final received = await _client
          .from(_tableName)
          .select('sender_id')
          .eq('receiver_id', currentUserId);

      final ids = <String>{};
      for (final row in sent as List) {
        final id = row['receiver_id'] as String?;
        if (id != null && id != currentUserId) ids.add(id);
      }
      for (final row in received as List) {
        final id = row['sender_id'] as String?;
        if (id != null && id != currentUserId) ids.add(id);
      }
      return ids.toList();
    } catch (e) {
      debugPrint('MessageService.getConversationPartnerIds error: $e');
      return [];
    }
  }

  static const List<String> _giftPhotoUrls = ['rose_gift', 'ring_gift', 'coffee_gift'];

  /// نوع الهدية التي بدأت بها المحادثة (إن وُجدت). يُرجع null إذا لم يكن عمود photo_url موجوداً في الجدول.
  Future<String?> getConversationGiftType(String currentUserId, String partnerId) async {
    try {
      final sent = await _client
          .from(_tableName)
          .select('photo_url, created_at')
          .eq('sender_id', currentUserId)
          .eq('receiver_id', partnerId)
          .inFilter('photo_url', _giftPhotoUrls)
          .order('created_at', ascending: true)
          .limit(1);
      final received = await _client
          .from(_tableName)
          .select('photo_url, created_at')
          .eq('sender_id', partnerId)
          .eq('receiver_id', currentUserId)
          .inFilter('photo_url', _giftPhotoUrls)
          .order('created_at', ascending: true)
          .limit(1);
      final sentList = sent as List;
      final receivedList = received as List;
      DateTime? sentAt;
      String? sentType;
      if (sentList.isNotEmpty) {
        final row = sentList.first as Map<String, dynamic>;
        sentType = row['photo_url'] as String?;
        if (row['created_at'] != null) sentAt = DateTime.parse(row['created_at'] as String);
      }
      DateTime? receivedAt;
      String? receivedType;
      if (receivedList.isNotEmpty) {
        final row = receivedList.first as Map<String, dynamic>;
        receivedType = row['photo_url'] as String?;
        if (row['created_at'] != null) receivedAt = DateTime.parse(row['created_at'] as String);
      }
      if (sentAt == null && receivedAt == null) return null;
      if (sentAt != null && (receivedAt == null || sentAt.isBefore(receivedAt))) return sentType;
      return receivedType;
    } on PostgrestException catch (e) {
      if (e.code == '42703' || e.message.contains('photo_url') || e.message.contains('does not exist')) {
        return null;
      }
      debugPrint('MessageService.getConversationGiftType error: $e');
      return null;
    } catch (e) {
      debugPrint('MessageService.getConversationGiftType error: $e');
      return null;
    }
  }
}
