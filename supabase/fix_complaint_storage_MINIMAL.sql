-- حل أبسط: سياسة واحدة فقط تسمح بالرفع
-- انسخ هذا السكربت بالكامل ثم Run في Supabase SQL Editor

-- 1) إنشاء الـ bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('complaint-evidence', 'complaint-evidence', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- 2) حذف كل السياسات المرتبطة بـ complaint-evidence
DROP POLICY IF EXISTS "complaint_evidence_upload" ON storage.objects;
DROP POLICY IF EXISTS "complaint_evidence_anon_upload" ON storage.objects;
DROP POLICY IF EXISTS "complaint_evidence_logged_in_upload" ON storage.objects;

-- 3) سياسة واحدة بسيطة: أي مستخدم مسجل (لديه JWT) يمكنه الرفع
CREATE POLICY "complaint_evidence_logged_in_upload" ON storage.objects
  FOR INSERT
  TO anon
  WITH CHECK (
    bucket_id = 'complaint-evidence'
    AND auth.jwt()->>'sub' IS NOT NULL
  );

CREATE POLICY "complaint_evidence_authenticated_upload" ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'complaint-evidence');
