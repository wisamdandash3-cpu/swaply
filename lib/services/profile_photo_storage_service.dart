import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// رفع صور البروفايل إلى Supabase Storage (bucket عام: القراءة للجميع).
class ProfilePhotoStorageService {
  ProfilePhotoStorageService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  static const String _bucket = 'profile-photos';

  /// يرفع ملف صورة من [filePath] لمستخدم [userId] في الموضع [slotIndex].
  /// يعيد الرابط العام للصورة أو يرمي عند الفشل.
  Future<String> uploadPhoto({
    required String userId,
    required String filePath,
    required int slotIndex,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('الملف غير موجود');
    }
    // مسار داخل المجلد: {userId}/slot_{index}.jpg
    final ext = _extension(filePath);
    final path = '$userId/slot_$slotIndex$ext';
    try {
      await _client.storage.from(_bucket).upload(
            path,
            file,
            fileOptions: const FileOptions(upsert: true),
          );
      final url = _client.storage.from(_bucket).getPublicUrl(path);
      return url;
    } catch (e, st) {
      debugPrint('ProfilePhotoStorageService.uploadPhoto error: $e');
      debugPrint('ProfilePhotoStorageService.uploadPhoto stack: $st');
      rethrow;
    }
  }

  static String _extension(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return '.png';
    if (lower.endsWith('.webp')) return '.webp';
    if (lower.endsWith('.heic')) return '.heic';
    return '.jpg';
  }

  /// حذف صورة من الموضع [slotIndex] لمستخدم [userId].
  Future<void> deletePhoto({required String userId, required int slotIndex}) async {
    try {
      final list = await _client.storage.from(_bucket).list(path: userId);
      for (final f in list) {
        if (f.name.startsWith('slot_$slotIndex')) {
          await _client.storage.from(_bucket).remove(['$userId/${f.name}']);
          return;
        }
      }
    } catch (e, st) {
      debugPrint('ProfilePhotoStorageService.deletePhoto error: $e');
      debugPrint('ProfilePhotoStorageService.deletePhoto stack: $st');
    }
  }
}
