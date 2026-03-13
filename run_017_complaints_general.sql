-- دعم الشكاوى العامة (بدون مستخدم مشكو منه)
-- شغّل هذا الملف في: Supabase Dashboard → SQL Editor → الصق المحتوى → Run

ALTER TABLE user_complaints
  ALTER COLUMN reported_id DROP NOT NULL;
