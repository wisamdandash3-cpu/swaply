-- إنشاء bucket لفيديوهات البروفايل (فيديو واحد لكل مستخدم، حد 15 ثانية).
-- نفّذ في Supabase Dashboard → Storage → New bucket، أو عبر SQL:

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'profile-videos',
  'profile-videos',
  true,
  52428800,
  ARRAY['video/mp4', 'video/quicktime']
)
ON CONFLICT (id) DO NOTHING;

-- سياسات RLS لـ profile-videos (مثل profile-photos):
-- المستخدم يرفع لحسابه فقط: (storage.foldername(name))[1] = auth.uid()::text
-- القراءة للجميع لأن الـ bucket عام (public).
