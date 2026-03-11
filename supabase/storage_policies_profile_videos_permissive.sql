-- سياسات أوسع لـ profile-videos إذا استمر خطأ 403 (للاختبار فقط).
-- نفّذها في Supabase → SQL Editor إذا السياسات العادية لم تحل المشكلة.

DROP POLICY IF EXISTS "Users upload own profile video" ON storage.objects;
DROP POLICY IF EXISTS "Profile videos anon insert" ON storage.objects;
DROP POLICY IF EXISTS "Users update own profile video" ON storage.objects;
DROP POLICY IF EXISTS "Profile videos anon update" ON storage.objects;
DROP POLICY IF EXISTS "Users delete own profile video" ON storage.objects;
DROP POLICY IF EXISTS "Profile videos anon delete" ON storage.objects;
DROP POLICY IF EXISTS "Profile videos public insert" ON storage.objects;
DROP POLICY IF EXISTS "Profile videos public update" ON storage.objects;
DROP POLICY IF EXISTS "Profile videos public select" ON storage.objects;

-- السماح بالرفع لأي مستخدم مصادق أو طلب anon مع JWT (التحقق من bucket فقط)
CREATE POLICY "Profile videos public insert"
ON storage.objects FOR INSERT
TO public
WITH CHECK (bucket_id = 'profile-videos');

CREATE POLICY "Profile videos public update"
ON storage.objects FOR UPDATE
TO public
USING (bucket_id = 'profile-videos')
WITH CHECK (bucket_id = 'profile-videos');

CREATE POLICY "Profile videos public select"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'profile-videos');
