-- إضافة عمود دليل الصورة للشكاوى
ALTER TABLE user_complaints
  ADD COLUMN IF NOT EXISTS evidence_url TEXT;

-- إنشاء bucket للدليل (إن لم يكن موجوداً)
INSERT INTO storage.buckets (id, name, public)
VALUES ('complaint-evidence', 'complaint-evidence', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- سياسات الرفع: المستخدم يرفع ضمن مجلده (reporter_id)
-- مثل profile-photos: نستخدم auth.jwt()->>'sub' لأن الطلبات قد تأتي بدور anon
DROP POLICY IF EXISTS "complaint_evidence_upload" ON storage.objects;
CREATE POLICY "complaint_evidence_upload" ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'complaint-evidence'
    AND (
      (storage.foldername(name))[1] = (auth.uid())::text
      OR (storage.foldername(name))[1] = (auth.jwt()->>'sub')
    )
  );

DROP POLICY IF EXISTS "complaint_evidence_anon_upload" ON storage.objects;
CREATE POLICY "complaint_evidence_anon_upload" ON storage.objects
  FOR INSERT
  TO anon
  WITH CHECK (
    bucket_id = 'complaint-evidence'
    AND auth.uid() IS NOT NULL
    AND (
      (storage.foldername(name))[1] = (auth.uid())::text
      OR (storage.foldername(name))[1] = (auth.jwt()->>'sub')
    )
  );
