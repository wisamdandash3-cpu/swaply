-- تصحيح سياسات RLS لرفع دليل الشكاوى (complaint-evidence)
-- شغّل هذا السكربت في Supabase → SQL Editor إذا ظهر خطأ: new row violates row-level security policy

-- 1) التأكد من وجود الـ bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('complaint-evidence', 'complaint-evidence', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- 2) حذف السياسات القديمة
DROP POLICY IF EXISTS "complaint_evidence_upload" ON storage.objects;
DROP POLICY IF EXISTS "complaint_evidence_anon_upload" ON storage.objects;
DROP POLICY IF EXISTS "complaint_evidence_logged_in_upload" ON storage.objects;

-- 3) سياسة مرنة: السماح لأي مستخدم مسجل بالرفع إلى complaint-evidence
--    (المسار يكون reporter_id/timestamp.jpg ويجب أن يطابق المستخدم الحالي)
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

-- 4) للطلبات بدور anon (مثل تطبيق Flutter بمفتاح anon)
CREATE POLICY "complaint_evidence_anon_upload" ON storage.objects
  FOR INSERT
  TO anon
  WITH CHECK (
    bucket_id = 'complaint-evidence'
    AND (auth.uid() IS NOT NULL OR auth.jwt()->>'sub' IS NOT NULL)
    AND (
      (storage.foldername(name))[1] = (auth.uid())::text
      OR (storage.foldername(name))[1] = (auth.jwt()->>'sub')
    )
  );

-- 5) احتياطي: السماح لأي مستخدم لديه JWT بالرفع (حتى لو فشل فحص المسار)
CREATE POLICY "complaint_evidence_logged_in_upload" ON storage.objects
  FOR INSERT
  TO anon
  WITH CHECK (
    bucket_id = 'complaint-evidence'
    AND auth.jwt()->>'sub' IS NOT NULL
  );
