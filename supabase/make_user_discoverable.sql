-- جعل حساب معيّن يظهر في شاشة "الاكتشاف" للتجربة (مثلاً wisamdandash3 لـ wisamdandash1).
-- شغّل في Supabase SQL Editor بعد استبدال البريد الإلكتروني إن لزم.
-- الشرط: يظهر في الاكتشاف فقط من لديه سجل واحد على الأقل في profile_answers.

DO $$
DECLARE
  target_id UUID;
  existing_count INT;
BEGIN
  -- استبدل البريد بحسابك الذي تريد أن يظهر (مثلاً wisamdandash3@gmail.com)
  SELECT id INTO target_id FROM auth.users WHERE email = 'wisamdandash3@gmail.com' LIMIT 1;

  IF target_id IS NULL THEN
    RAISE NOTICE 'لم يُعثر على المستخدم. تأكد من البريد أو استبدله في السكربت.';
    RETURN;
  END IF;

  SELECT COUNT(*) INTO existing_count FROM profile_answers WHERE profile_id = target_id;

  IF existing_count > 0 THEN
    RAISE NOTICE 'الحساب لديه بالفعل % سجل في profile_answers — سيظهر في الاكتشاف.', existing_count;
    RETURN;
  END IF;

  -- إدراج سطر واحد نصي بسيط حتى يظهر البروفايل في الاكتشاف
  INSERT INTO profile_answers (profile_id, item_type, content, sort_order)
  VALUES (target_id, 'text', 'Test profile for discovery', 0);

  RAISE NOTICE 'تم إضافة سجل لبروفايل %. سيبقى ظاهراً في الاكتشاف.', target_id;
END $$;
