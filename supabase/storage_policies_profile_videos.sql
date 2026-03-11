-- سياسات RLS لرفع فيديو البروفايل (bucket: profile-videos)
-- أنشئ الـ bucket أولاً من Dashboard → Storage → New bucket: profile-videos (Public: ON)
-- ثم نفّذ هذا الملف في SQL Editor.

DROP POLICY IF EXISTS "Users upload own profile video" ON storage.objects;
DROP POLICY IF EXISTS "Profile videos anon insert" ON storage.objects;
DROP POLICY IF EXISTS "Users update own profile video" ON storage.objects;
DROP POLICY IF EXISTS "Profile videos anon update" ON storage.objects;
DROP POLICY IF EXISTS "Users delete own profile video" ON storage.objects;
DROP POLICY IF EXISTS "Profile videos anon delete" ON storage.objects;

-- INSERT: رفع فيديو جديد (مجلد المستخدم فقط)
CREATE POLICY "Users upload own profile video"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'profile-videos'
  AND (
    (storage.foldername(name))[1] = (auth.uid())::text
    OR (storage.foldername(name))[1] = (auth.jwt()->>'sub')
  )
);

CREATE POLICY "Profile videos anon insert"
ON storage.objects FOR INSERT
TO anon
WITH CHECK (
  bucket_id = 'profile-videos'
  AND auth.uid() IS NOT NULL
  AND (
    (storage.foldername(name))[1] = (auth.uid())::text
    OR (storage.foldername(name))[1] = (auth.jwt()->>'sub')
  )
);

-- UPDATE: استبدال فيديو موجود (upsert: true يحتاجها)
CREATE POLICY "Users update own profile video"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'profile-videos'
  AND (
    (storage.foldername(name))[1] = (auth.uid())::text
    OR (storage.foldername(name))[1] = (auth.jwt()->>'sub')
  )
)
WITH CHECK (
  bucket_id = 'profile-videos'
  AND (
    (storage.foldername(name))[1] = (auth.uid())::text
    OR (storage.foldername(name))[1] = (auth.jwt()->>'sub')
  )
);

CREATE POLICY "Profile videos anon update"
ON storage.objects FOR UPDATE
TO anon
USING (
  bucket_id = 'profile-videos'
  AND auth.uid() IS NOT NULL
  AND (
    (storage.foldername(name))[1] = (auth.uid())::text
    OR (storage.foldername(name))[1] = (auth.jwt()->>'sub')
  )
)
WITH CHECK (
  bucket_id = 'profile-videos'
  AND auth.uid() IS NOT NULL
  AND (
    (storage.foldername(name))[1] = (auth.uid())::text
    OR (storage.foldername(name))[1] = (auth.jwt()->>'sub')
  )
);

-- DELETE: حذف فيديو المستخدم
CREATE POLICY "Users delete own profile video"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'profile-videos'
  AND (
    (storage.foldername(name))[1] = (auth.uid())::text
    OR (storage.foldername(name))[1] = (auth.jwt()->>'sub')
  )
);

CREATE POLICY "Profile videos anon delete"
ON storage.objects FOR DELETE
TO anon
USING (
  bucket_id = 'profile-videos'
  AND auth.uid() IS NOT NULL
  AND (
    (storage.foldername(name))[1] = (auth.uid())::text
    OR (storage.foldername(name))[1] = (auth.jwt()->>'sub')
  )
);
