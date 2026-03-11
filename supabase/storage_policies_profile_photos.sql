-- ========== سياسات RLS لرفع صور البروفايل (bucket: profile-photos) ==========
-- مهم: انسخ والصق كل الملف من أول سطر إلى آخر سطر ثم Run (كل السياسات الثلاث معاً).

-- حذف السياسات إن وُجدت (لتجنب تكرار الاسم)
DROP POLICY IF EXISTS "Users upload own profile photos" ON storage.objects;
DROP POLICY IF EXISTS "Profile photos anon insert" ON storage.objects;
DROP POLICY IF EXISTS "Users update own profile photos" ON storage.objects;
DROP POLICY IF EXISTS "Users delete own profile photos" ON storage.objects;

-- 1) INSERT: السماح للمستخدم المسجل بالرفع داخل مجلده فقط.
--    المسار في التطبيق: {user_id}/slot_0.jpg
--    نستخدم (storage.foldername(name))[1] = أول مجلد في المسار = user_id
CREATE POLICY "Users upload own profile photos"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'profile-photos'
  AND (
    (storage.foldername(name))[1] = (auth.uid())::text
    OR (storage.foldername(name))[1] = (auth.jwt()->>'sub')
  )
);

-- 1ب) طلبات التطبيق قد تأتي بدور anon مع JWT — نسمح بالرفع إن كان المستخدم مصادقاً
CREATE POLICY "Profile photos anon insert"
ON storage.objects FOR INSERT
TO anon
WITH CHECK (
  bucket_id = 'profile-photos'
  AND auth.uid() IS NOT NULL
  AND (
    (storage.foldername(name))[1] = (auth.uid())::text
    OR (storage.foldername(name))[1] = (auth.jwt()->>'sub')
  )
);

-- 2) السماح بتحديث الملفات داخل مجلد المستخدم فقط
CREATE POLICY "Users update own profile photos"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'profile-photos'
  AND (storage.foldername(name))[1] = (auth.uid())::text
);

-- 3) السماح بحذف الملفات داخل مجلد المستخدم فقط
CREATE POLICY "Users delete own profile photos"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'profile-photos'
  AND (storage.foldername(name))[1] = (auth.uid())::text
);

-- بعد التشغيل، جرّب رفع صورة من التطبيق مرة أخرى.
-- ==========
