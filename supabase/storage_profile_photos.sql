-- ========== صور البروفايل: bucket عام (القراءة للجميع) والرفع للمستخدم المسجل فقط ==========
--
-- إذا ظهر خطأ "Bucket not found" (404) في التطبيق، أنشئ الـ bucket بإحدى الطريقتين:
--
-- الطريقة 1 (من Dashboard - الأسهل):
--   1. افتح مشروعك في https://supabase.com/dashboard
--   2. من القائمة اليسرى: Storage
--   3. New bucket
--   4. Name: profile-photos  (يجب أن يكون بالضبط profile-photos)
--   5. فعّل "Public bucket" (لنشر الصور لكل المستخدمين)
--   6. Create bucket
--   7. بعدها نفّذ فقط السياسات (2 و 3) أدناه من SQL Editor
--
-- الطريقة 2 (كل السكربت من SQL Editor):
--   انسخ والصق كل ما يلي في Supabase → SQL Editor → Run

-- 1) إنشاء bucket عام (القراءة للجميع = نشر الصور لكل المستخدمين)
INSERT INTO storage.buckets (id, name, public)
VALUES ('profile-photos', 'profile-photos', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- 2) السماح للمستخدم المسجل بالرفع داخل مجلده فقط: {user_id}/*
DROP POLICY IF EXISTS "Users upload own profile photos" ON storage.objects;
CREATE POLICY "Users upload own profile photos"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'profile-photos'
  AND (storage.foldername(name))[1] = (auth.uid())::text
);

-- 3) السماح للمستخدم بتحديث/حذف صوره فقط
DROP POLICY IF EXISTS "Users update own profile photos" ON storage.objects;
CREATE POLICY "Users update own profile photos"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'profile-photos' AND (storage.foldername(name))[1] = (auth.uid())::text);

DROP POLICY IF EXISTS "Users delete own profile photos" ON storage.objects;
CREATE POLICY "Users delete own profile photos"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'profile-photos' AND (storage.foldername(name))[1] = (auth.uid())::text);

-- ملاحظة: القراءة (SELECT) على الـ bucket العام لا تحتاج سياسة إضافية.
-- ==========
