-- أضف نفسك كمسؤول أول بعد تشغيل 007_admin_panel.sql
-- 1. اذهب إلى Supabase → Authentication → Users
-- 2. انسخ user_id (UUID) لحسابك
-- 3. استبدل YOUR_USER_ID_HERE بالـ UUID
-- 4. شغّل هذا الملف في SQL Editor

INSERT INTO admin_users (user_id, email, role)
VALUES (
  'YOUR_USER_ID_HERE'::uuid,
  'your-email@example.com',
  'super_admin'
)
ON CONFLICT (user_id) DO UPDATE SET role = 'super_admin';
