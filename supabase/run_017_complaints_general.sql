-- دعم الشكاوى العامة (بدون مستخدم مشكو منه): reported_id يصبح اختيارياً
-- شغّل هذا الملف في Supabase Dashboard → SQL Editor → Run

ALTER TABLE user_complaints
  ALTER COLUMN reported_id DROP NOT NULL;
