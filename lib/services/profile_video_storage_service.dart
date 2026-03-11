import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// رفع فيديو البروفايل الواحد (سؤال فيديو) إلى Supabase Storage.
/// المسار: profile-videos/{userId}/prompt_video.mp4
class ProfileVideoStorageService {
  ProfileVideoStorageService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  static const String _bucket = 'profile-videos';

  /// يرفع ملف فيديو لمستخدم [userId]. يستبدل أي فيديو سابق.
  /// يعيد الرابط العام أو يرمي عند الفشل.
  Future<String> uploadVideo({
    required String userId,
    required String filePath,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('الملف غير موجود');
    }
    final ext = filePath.toLowerCase().endsWith('.mov') ? '.mov' : '.mp4';
    final path = 'prompt_video$ext';
    final userPath = '$userId/$path';
    try {
      await _client.storage.from(_bucket).upload(
            userPath,
            file,
            fileOptions: const FileOptions(upsert: true),
          );
      return _client.storage.from(_bucket).getPublicUrl(userPath);
    } catch (e, st) {
      debugPrint('ProfileVideoStorageService.uploadVideo error: $e');
      debugPrint('ProfileVideoStorageService.uploadVideo stack: $st');
      rethrow;
    }
  }

  /// حذف فيديو البروفايل لمستخدم [userId].
  Future<void> deleteVideo({required String userId}) async {
    try {
      await _client.storage.from(_bucket).remove([
        '$userId/prompt_video.mp4',
        '$userId/prompt_video.mov',
      ]);
    } catch (e, st) {
      debugPrint('ProfileVideoStorageService.deleteVideo error: $e');
      debugPrint('ProfileVideoStorageService.deleteVideo stack: $st');
    }
  }
}
