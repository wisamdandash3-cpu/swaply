import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// عنصر رد من الإدارة في محادثة الشكوى.
class AdminReplyItem {
  const AdminReplyItem({required this.id, required this.content, required this.createdAt});
  final String id;
  final String content;
  final DateTime createdAt;
}

/// محادثة شكوى: الشكوى + ردود الإدارة.
class ComplaintConversation {
  const ComplaintConversation({
    required this.id,
    required this.reason,
    this.context,
    this.evidenceUrl,
    required this.createdAt,
    required this.replies,
  });
  final String id;
  final String reason;
  final String? context;
  final String? evidenceUrl;
  final DateTime createdAt;
  final List<AdminReplyItem> replies;
}

/// خدمة إرسال الشكاوى (مستخدم يشكو من مستخدم آخر أو شكوى عامة).
class ComplaintService {
  ComplaintService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  static const String _tableName = 'user_complaints';
  static const String _repliesTable = 'admin_replies';
  static const String _storageBucket = 'complaint-evidence';

  Future<String?> _uploadEvidenceAsync(String reporterId, File evidenceImage) async {
    final ext = evidenceImage.path.toLowerCase().endsWith('.png')
        ? '.png'
        : (evidenceImage.path.toLowerCase().endsWith('.webp')
            ? '.webp'
            : '.jpg');
    final path = '$reporterId/${DateTime.now().millisecondsSinceEpoch}$ext';
    await _client.storage.from(_storageBucket).upload(
          path,
          evidenceImage,
          fileOptions: const FileOptions(upsert: true),
        );
    return _client.storage.from(_storageBucket).getPublicUrl(path);
  }

  /// إرسال شكوى عامة (بدون مستخدم مشكو منه): سبب + دليل صورة. تُعرض في لوحة التحكم.
  Future<String?> reportGeneralComplaint({
    required String reporterId,
    required String reason,
    String? context,
    File? evidenceImage,
  }) async {
    try {
      String? evidenceUrl;
      if (evidenceImage != null) {
        evidenceUrl = await _uploadEvidenceAsync(reporterId, evidenceImage);
      }
      await _client.from(_tableName).insert({
        'reporter_id': reporterId,
        'reported_id': null,
        'reason': reason.trim(),
        'context': context ?? 'general',
        'evidence_url': evidenceUrl,
      });
      return null; // success
    } catch (e, st) {
      debugPrint('ComplaintService.reportGeneralComplaint error: $e');
      debugPrint(st.toString());
      String msg = e.toString();
      if (e is PostgrestException) msg = e.message;
      if (msg.contains('rate_limit') || (e is PostgrestException && e.code == 'PGRST301')) {
        return 'تجاوزت حد الشكاوى. حاول لاحقاً.';
      }
      return msg;
    }
  }

  /// إرسال شكوى من مستخدم ضد آخر (مع السبب والدليل كصورة).
  /// يعيد null عند النجاح، أو رسالة الخطأ عند الفشل.
  Future<String?> reportUser({
    required String reporterId,
    required String reportedId,
    required String reason,
    String? context,
    File? evidenceImage,
  }) async {
    try {
      String? evidenceUrl;
      if (evidenceImage != null) {
        evidenceUrl = await _uploadEvidenceAsync(reporterId, evidenceImage);
      }
      await _client.from(_tableName).insert({
        'reporter_id': reporterId,
        'reported_id': reportedId,
        'reason': reason.trim(),
        'context': context ?? '',
        'evidence_url': evidenceUrl,
      });
      return null; // success
    } catch (e, st) {
      debugPrint('ComplaintService.reportUser error: $e');
      debugPrint(st.toString());
      String msg = e.toString();
      if (e is PostgrestException) msg = e.message;
      if (msg.contains('rate_limit') || (e is PostgrestException && e.code == 'PGRST301')) {
        return 'تجاوزت حد الشكاوى. حاول لاحقاً.';
      }
      return msg;
    }
  }

  /// جلب شكاوى المستخدم مع ردود الإدارة كمحادثات (للعرض في التطبيق).
  Future<List<ComplaintConversation>> getMyComplaintConversations(String userId) async {
    try {
      final complaintsRes = await _client
          .from(_tableName)
          .select('id, reason, context, evidence_url, created_at')
          .eq('reporter_id', userId)
          .order('created_at', ascending: false);
      final repliesRes = await _client
          .from(_repliesTable)
          .select('id, complaint_id, content, created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: true);

      final complaints = complaintsRes as List<dynamic>? ?? [];
      final replies = repliesRes as List<dynamic>? ?? [];
      final repliesByComplaint = <String, List<AdminReplyItem>>{};
      for (final r in replies) {
        final map = r as Map<String, dynamic>;
        final cid = map['complaint_id'] as String?;
        if (cid == null) continue;
        final id = map['id'] as String? ?? '';
        final content = (map['content'] as String?) ?? '';
        final createdAtStr = map['created_at'] as String?;
        final createdAt = createdAtStr != null ? DateTime.tryParse(createdAtStr) ?? DateTime.now() : DateTime.now();
        repliesByComplaint.putIfAbsent(cid, () => []).add(AdminReplyItem(id: id, content: content, createdAt: createdAt));
      }

      final list = <ComplaintConversation>[];
      for (final c in complaints) {
        final map = c as Map<String, dynamic>;
        final id = map['id'] as String? ?? '';
        final reason = (map['reason'] as String?) ?? '';
        final context = map['context'] as String?;
        final evidenceUrl = map['evidence_url'] as String?;
        final createdAtStr = map['created_at'] as String?;
        final createdAt = createdAtStr != null ? DateTime.tryParse(createdAtStr) ?? DateTime.now() : DateTime.now();
        list.add(ComplaintConversation(
          id: id,
          reason: reason,
          context: context,
          evidenceUrl: evidenceUrl,
          createdAt: createdAt,
          replies: repliesByComplaint[id] ?? [],
        ));
      }
      return list;
    } catch (e, st) {
      debugPrint('ComplaintService.getMyComplaintConversations error: $e');
      debugPrint(st.toString());
      return [];
    }
  }

  /// عدد ردود الإدارة الموجهة للمستخدم (لإظهار شارة الإشعار).
  Future<int> getAdminRepliesCount(String userId) async {
    try {
      final list = await _client
          .from(_repliesTable)
          .select('id')
          .eq('user_id', userId);
      return (list as List<dynamic>?)?.length ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// حذف محادثة الشكوى (الشكوى + ردود الإدارة) من التطبيق والقاعدة.
  Future<String?> deleteComplaintConversation(String userId, String complaintId) async {
    try {
      await _client.from(_repliesTable).delete().eq('complaint_id', complaintId).eq('user_id', userId);
      await _client.from(_tableName).delete().eq('id', complaintId).eq('reporter_id', userId);
      return null;
    } catch (e, st) {
      debugPrint('ComplaintService.deleteComplaintConversation error: $e');
      debugPrint(st.toString());
      String msg = e.toString();
      if (e is PostgrestException) msg = e.message;
      return msg;
    }
  }
}
