-- إنشاء bucket لتسجيلات الصوت في البروفايل (تسجيل واحد لكل مستخدم).
-- نفّذ هذا الملف أولاً في Supabase Dashboard → SQL Editor.
-- بعدها نفّذ storage_policies_profile_audio.sql.

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'profile-audio',
  'profile-audio',
  true,
  10485760,
  ARRAY['audio/mp4', 'audio/mpeg', 'audio/mp3', 'audio/wav', 'audio/x-m4a', 'audio/aac']
)
ON CONFLICT (id) DO NOTHING;
