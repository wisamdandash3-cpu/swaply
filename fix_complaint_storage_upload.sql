-- إصلاح خطأ 403 عند رفع صورة الشكوى (new row violates row-level security policy)
-- مهم: انسخ من أول السطر حتى آخر السطر (بما فيها CREATE POLICY) ثم Run
-- إذا نفذت فقط الـ DROP دون الـ CREATE فستستمر المشكلة — يجب تنفيذ الكل

-- 1) التأكد من وجود الـ bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('complaint-evidence', 'complaint-evidence', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- 2) حذف كل السياسات القديمة لـ complaint-evidence
DROP POLICY IF EXISTS "complaint_evidence_upload" ON storage.objects;
DROP POLICY IF EXISTS "complaint_evidence_anon_upload" ON storage.objects;
DROP POLICY IF EXISTS "complaint_evidence_logged_in_upload" ON storage.objects;
DROP POLICY IF EXISTS "complaint_evidence_authenticated_upload" ON storage.objects;
DROP POLICY IF EXISTS "complaint_evidence_allow_insert" ON storage.objects;
DROP POLICY IF EXISTS "complaint_evidence_allow_select" ON storage.objects;
DROP POLICY IF EXISTS "complaint_evidence_allow_update" ON storage.objects;

-- 3) الرفع مع upsert: true يتطلب INSERT + SELECT + UPDATE
CREATE POLICY "complaint_evidence_allow_insert" ON storage.objects
  FOR INSERT TO anon, authenticated
  WITH CHECK (bucket_id = 'complaint-evidence');
CREATE POLICY "complaint_evidence_allow_select" ON storage.objects
  FOR SELECT TO anon, authenticated
  USING (bucket_id = 'complaint-evidence');
CREATE POLICY "complaint_evidence_allow_update" ON storage.objects
  FOR UPDATE TO anon, authenticated
  USING (bucket_id = 'complaint-evidence')
  WITH CHECK (bucket_id = 'complaint-evidence');

-- للتحقق بعد التشغيل: عرض السياسات على storage.objects
-- SELECT policyname, permissive, roles, cmd, qual FROM pg_policies WHERE tablename = 'objects' AND schemaname = 'storage';
