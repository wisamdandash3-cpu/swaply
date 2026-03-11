import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// رفع تسجيل صوتي للبروفايل إلى Supabase Storage.
/// المسار: profile-audio/{userId}/voice_recording.{ext}
/// إذا ظهر Bucket not found: نفّذ supabase/storage_profile_audio.sql ثم storage_policies_profile_audio.sql في SQL Editor.
class ProfileAudioStorageService {
  ProfileAudioStorageService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  static const String _bucket = 'profile-audio';

  /// يرفع ملف صوت لمستخدم [userId]. يستبدل أي تسجيل سابق.
  /// يعيد الرابط العام أو يرمي عند الفشل.
  /// يدعم: .m4a, .aac, .mp3, .wav
  Future<String> uploadAudio({
    required String userId,
    required String filePath,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('الملف غير موجود');
    }
    final lower = filePath.toLowerCase();
    String ext = '.m4a';
    if (lower.endsWith('.mp3')) {
      ext = '.mp3';
    } else if (lower.endsWith('.wav'))
      ext = '.wav';
    else if (lower.endsWith('.aac'))
      ext = '.aac';
    else if (lower.endsWith('.m4a'))
      ext = '.m4a';
    final path = 'voice_recording$ext';
    final userPath = '$userId/$path';
    try {
      await _client.storage
          .from(_bucket)
          .upload(userPath, file, fileOptions: const FileOptions(upsert: true));
      return _client.storage.from(_bucket).getPublicUrl(userPath);
    } catch (e, st) {
      debugPrint('ProfileAudioStorageService.uploadAudio error: $e');
      debugPrint('ProfileAudioStorageService.uploadAudio stack: $st');
      rethrow;
    }
  }

  /// حذف تسجيل الصوت لمستخدم [userId].
  Future<void> deleteAudio({required String userId}) async {
    try {
      await _client.storage.from(_bucket).remove([
        '$userId/voice_recording.m4a',
        '$userId/voice_recording.aac',
        '$userId/voice_recording.mp3',
        '$userId/voice_recording.wav',
      ]);
    } catch (e, st) {
      debugPrint('ProfileAudioStorageService.deleteAudio error: $e');
      debugPrint('ProfileAudioStorageService.deleteAudio stack: $st');
    }
  }
}
