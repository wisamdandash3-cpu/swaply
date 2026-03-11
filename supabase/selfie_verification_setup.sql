-- ============================================================
-- إعداد التحقق بالـ selfie وشارة التوثيق
-- شغّل هذا الملف في Supabase → SQL Editor ثم Run
-- ============================================================

-- 1) التأكد من أن الجدول user_profile_fields موجود (إن لم يكن، شغّل create_user_profile_fields.sql أولاً)

-- 2) السماح للجميع بقراءة حقول البروفايل (بما فيها حالة التوثيق) حتى تظهر الشارة عند الآخرين
DROP POLICY IF EXISTS "profile_fields_viewable_by_everyone" ON user_profile_fields;
CREATE POLICY "profile_fields_viewable_by_everyone" ON user_profile_fields
  FOR SELECT
  USING (true);

-- 3) قيم الحقل selfie_verification_status في user_profile_fields:
--    - غير موجود: المستخدم لم يرسل selfie
--    - value = 'submitted': أرسل صورة، بانتظار المراجعة
--    - value = 'verified': تم التحقق، تظهر له شارة التوثيق

-- 4) لتفعيل شارة التوثيق لمستخدم معيّن (بعد المراجعة اليدوية أو عبر لوحة إدارية)،
--    نفّذ أحد الأمرين التاليين في SQL Editor:

-- إذا كان المستخدم قد أرسل selfie مسبقاً (يوجد صف submitted)، حدّث القيمة:
-- UPDATE user_profile_fields
-- SET value = 'verified', updated_at = NOW()
-- WHERE field_key = 'selfie_verification_status'
--   AND user_id = 'USER_UUID_HERE';

-- إذا لم يوجد صف، أضف صفاً جديداً:
-- INSERT INTO user_profile_fields (user_id, field_key, value, visibility, updated_at)
-- VALUES ('USER_UUID_HERE', 'selfie_verification_status', 'verified', 'hidden', NOW())
-- ON CONFLICT (user_id, field_key) DO UPDATE SET value = 'verified', updated_at = NOW();

-- استبدل USER_UUID_HERE بـ user_id الفعلي من auth.users (مثلاً من Supabase Dashboard → Authentication → Users)
