-- إصلاح 403 عند رفع الشكوى: الـ upsert يتطلب INSERT + SELECT + UPDATE
-- Supabase → SQL Editor → الصق المحتوى بالكامل → Run

DROP POLICY IF EXISTS "complaint_evidence_allow_insert" ON storage.objects;
DROP POLICY IF EXISTS "complaint_evidence_allow_select" ON storage.objects;
DROP POLICY IF EXISTS "complaint_evidence_allow_update" ON storage.objects;

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
