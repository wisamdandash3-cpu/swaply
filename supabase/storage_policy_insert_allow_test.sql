-- ========== اختبار: السماح بالرفع إلى profile-photos ==========
-- حسب وثائق Supabase، سياسة الرفع قد تحتاج TO public (كل الأدوار).

DROP POLICY IF EXISTS "Users upload own profile photos" ON storage.objects;
DROP POLICY IF EXISTS "Profile photos anon insert" ON storage.objects;
DROP POLICY IF EXISTS "Profile photos public insert" ON storage.objects;
DROP POLICY IF EXISTS "Profile photos public select" ON storage.objects;
DROP POLICY IF EXISTS "Profile photos public update" ON storage.objects;

-- INSERT: رفع ملف جديد
CREATE POLICY "Profile photos public insert"
ON storage.objects FOR INSERT
TO public
WITH CHECK (bucket_id = 'profile-photos');

-- SELECT + UPDATE: مطلوبان عند استخدام upsert (الاستبدال إذا وُجد الملف)
CREATE POLICY "Profile photos public select"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'profile-photos');

CREATE POLICY "Profile photos public update"
ON storage.objects FOR UPDATE
TO public
USING (bucket_id = 'profile-photos');

-- نفّذ Run ثم جرّب رفع صورة من التطبيق.
-- إن نجح، يمكن لاحقاً استبدالها بسياسة تقيّد بمجلد المستخدم (storage_policies_profile_photos.sql).
-- ==========
