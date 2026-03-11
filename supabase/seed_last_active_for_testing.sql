-- تشغيل هذا في Supabase SQL Editor لجعل كل المستخدمين الذين لديهم بروفايل يظهرون كمتصّلين (نقطة خضراء)
-- يساعد على اختبار ميزة "آخر ظهور" والنقطة الخضراء في الاكتشاف.

-- 1) السماح بقراءة حقول المستخدمين الآخرين (لإظهار النقطة الخضراء في الاكتشاف والدردشة)
DROP POLICY IF EXISTS "profile_fields_viewable_by_everyone" ON user_profile_fields;
CREATE POLICY "profile_fields_viewable_by_everyone" ON user_profile_fields
  FOR SELECT USING (true);

-- 2) تحديث last_active_at بتنسيق يتوافق مع Dart (ISO 8601)
INSERT INTO user_profile_fields (user_id, field_key, value, visibility)
SELECT u.profile_id, 'last_active_at',
  to_char(NOW() AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'), 'hidden'
FROM (SELECT DISTINCT profile_id FROM profile_answers) u
ON CONFLICT (user_id, field_key)
DO UPDATE SET value = to_char(NOW() AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'), updated_at = NOW();
