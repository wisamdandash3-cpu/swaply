-- دعم الشكاوى العامة (بدون مستخدم مشكو منه): reported_id يصبح اختيارياً
-- تشغيل: Supabase Dashboard → SQL Editor → Run

ALTER TABLE user_complaints
  ALTER COLUMN reported_id DROP NOT NULL;

-- إزالة الـ FK لو كانت تمنع NULL (في بعض الإصدارات يبقى المرجع ويسمح بـ NULL)
-- COMMENT: لا حاجة لتعديل الـ REFERENCES؛ السماح بـ NULL كافٍ.
