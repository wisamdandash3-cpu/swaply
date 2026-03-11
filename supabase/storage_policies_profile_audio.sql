-- سياسات RLS لتسجيل الصوت (bucket: profile-audio)
-- أنشئ الـ bucket أولاً: نفّذ storage_profile_audio.sql في SQL Editor، ثم نفّذ هذا الملف.
-- المسار في التطبيق: {user_id}/voice_recording.{m4a|mp3|...} — أول مجلد = auth.uid()

DROP POLICY IF EXISTS "Users upload own profile audio" ON storage.objects;
DROP POLICY IF EXISTS "Profile audio anon insert" ON storage.objects;
DROP POLICY IF EXISTS "Users update own profile audio" ON storage.objects;
DROP POLICY IF EXISTS "Profile audio anon update" ON storage.objects;
DROP POLICY IF EXISTS "Users delete own profile audio" ON storage.objects;
DROP POLICY IF EXISTS "Profile audio anon delete" ON storage.objects;
DROP POLICY IF EXISTS "Profile audio anon insert fallback" ON storage.objects;
DROP POLICY IF EXISTS "Profile audio select authenticated" ON storage.objects;
DROP POLICY IF EXISTS "Profile audio select anon" ON storage.objects;

-- INSERT: الرفع فقط داخل مجلد المستخدم الحالي (مثل profile-photos)
CREATE POLICY "Users upload own profile audio"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'profile-audio'
  AND (
    (storage.foldername(name))[1] = (auth.uid())::text
    OR (storage.foldername(name))[1] = (auth.jwt()->>'sub')
  )
);

CREATE POLICY "Profile audio anon insert"
ON storage.objects FOR INSERT
TO anon
WITH CHECK (
  bucket_id = 'profile-audio'
  AND auth.uid() IS NOT NULL
  AND (
    (storage.foldername(name))[1] = (auth.uid())::text
    OR (storage.foldername(name))[1] = (auth.jwt()->>'sub')
  )
);

-- UPDATE/DELETE: نفس التحقق من المسار
CREATE POLICY "Users update own profile audio"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'profile-audio'
  AND (
    (storage.foldername(name))[1] = (auth.uid())::text
    OR (storage.foldername(name))[1] = (auth.jwt()->>'sub')
  )
)
WITH CHECK (
  bucket_id = 'profile-audio'
  AND (
    (storage.foldername(name))[1] = (auth.uid())::text
    OR (storage.foldername(name))[1] = (auth.jwt()->>'sub')
  )
);

CREATE POLICY "Profile audio anon update"
ON storage.objects FOR UPDATE
TO anon
USING (
  bucket_id = 'profile-audio'
  AND auth.uid() IS NOT NULL
  AND (
    (storage.foldername(name))[1] = (auth.uid())::text
    OR (storage.foldername(name))[1] = (auth.jwt()->>'sub')
  )
)
WITH CHECK (
  bucket_id = 'profile-audio'
  AND auth.uid() IS NOT NULL
  AND (
    (storage.foldername(name))[1] = (auth.uid())::text
    OR (storage.foldername(name))[1] = (auth.jwt()->>'sub')
  )
);

CREATE POLICY "Users delete own profile audio"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'profile-audio'
  AND (
    (storage.foldername(name))[1] = (auth.uid())::text
    OR (storage.foldername(name))[1] = (auth.jwt()->>'sub')
  )
);

CREATE POLICY "Profile audio anon delete"
ON storage.objects FOR DELETE
TO anon
USING (
  bucket_id = 'profile-audio'
  AND auth.uid() IS NOT NULL
  AND (
    (storage.foldername(name))[1] = (auth.uid())::text
    OR (storage.foldername(name))[1] = (auth.jwt()->>'sub')
  )
);

-- السماح بقراءة الملفات (bucket عام)
CREATE POLICY "Profile audio select authenticated"
ON storage.objects FOR SELECT TO authenticated
USING (bucket_id = 'profile-audio');
CREATE POLICY "Profile audio select anon"
ON storage.objects FOR SELECT TO anon
USING (bucket_id = 'profile-audio');

-- انسخ كل المحتوى أعلاه ونفّذه في Supabase → SQL Editor → Run.
