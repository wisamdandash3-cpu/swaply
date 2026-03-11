-- =============================================================================
-- تشخيص قبل تشغيل سكربت الإعجابات — تحقق من بريدك وبروفايلك
-- =============================================================================
-- 1. استبدل YOUR_EMAIL_HERE أدناه ببريدك من Supabase → Authentication → Users
-- 2. شغّل السكربت (Run)
-- 3. إذا ظهر صف واحد: معرّفك وعدد إجابات البروفايل — يمكنك تشغيل seed_dummy_likes.sql
--    إذا لم يظهر أي صف: البريد غير موجود في auth.users أو لا توجد إجابات بروفايل
-- =============================================================================

SELECT
  u.id AS user_id,
  u.email,
  (SELECT count(*) FROM profile_answers WHERE profile_id = u.id) AS profile_answers_count,
  (SELECT count(*) FROM profile_likes WHERE to_user_id = u.id) AS incoming_likes_count
FROM auth.users u
WHERE u.email = 'wisamdandash1@gmail.com';
