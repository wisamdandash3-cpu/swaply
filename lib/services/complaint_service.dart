import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// خدمة إرسال الشكاوى (مستخدم يشكو من مستخدم آخر).
class ComplaintService {
  ComplaintService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  static const String _tableName = 'user_complaints';
  static const String _storageBucket = 'complaint-evidence';

  /// إرسال شكوى من مستخدم ضد آخر (مع السبب والدليل كصورة).
  /// يعيد true عند النجاح، أو رسالة الخطأ عند الفشل.
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
        evidenceUrl = _client.storage.from(_storageBucket).getPublicUrl(path);
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
}
