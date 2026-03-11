-- =============================================================================
-- إضافة إعجابات بك من مستخدمين موجودين (بدون إنشاء حسابات جديدة)
-- =============================================================================
-- استخدم هذا السكربت إذا شغّلت seed_dummy_likes.sql سابقاً ولم يظهر أحد في "معجب بك"،
-- أو إذا لديك بالفعل حسابات أخرى (وهمية أو حقيقية) وتريد أن "يعجبوا" بك.
--
-- 1. استبدل YOUR_EMAIL_HERE أدناه ببريدك المسجّل في التطبيق.
-- 2. شغّل السكربت في Supabase → SQL Editor.
-- 3. سيسجّل إعجاباً من حتى 5 مستخدمين آخرين ببروفايلك (إن وُجدوا ولديهم بيانات).
-- =============================================================================

DO $$
DECLARE
  my_id UUID;
  my_item_id UUID;
  r RECORD;
BEGIN
  SELECT id INTO my_id FROM auth.users WHERE email = 'wisamdandash1@gmail.com' LIMIT 1;
  IF my_id IS NULL THEN
    RAISE NOTICE 'غيّر YOUR_EMAIL_HERE إلى بريدك ثم شغّل السكربت مرة أخرى.';
    RETURN;
  END IF;

  SELECT id INTO my_item_id FROM profile_answers WHERE profile_id = my_id LIMIT 1;
  IF my_item_id IS NULL THEN
    RAISE NOTICE 'أضف صورة أو إجابة واحدة لبروفايلك من التطبيق ثم شغّل السكربت.';
    RETURN;
  END IF;

  FOR r IN (
    SELECT id FROM auth.users WHERE id != my_id LIMIT 5
  ) LOOP
    INSERT INTO profile_likes (from_user_id, to_user_id, item_id)
    VALUES (r.id, my_id, my_item_id)
    ON CONFLICT (from_user_id, to_user_id, item_id) DO NOTHING;
  END LOOP;

  RAISE NOTICE 'تمت إضافة إعجابات. افتح تاب "معجب بك" في التطبيق (قد تحتاج سحب للتحديث).';
END $$;
