-- بيانات تجريبية مؤقتة لحساب wisamdandash3@gmail.com
-- لرؤية المطابقات والرسائل. شغّل في Supabase SQL Editor.
-- يحتاج وجود مستخدمين على الأقل في auth.users (أنت + أي حساب آخر للتجربة).

DO $$
DECLARE
  wisam_id UUID;
  other_id UUID;
  other_item_id UUID;
BEGIN
  -- 1) الحصول على معرّف wisamdandash3@gmail.com
  SELECT id INTO wisam_id FROM auth.users WHERE email = 'wisamdandash3@gmail.com' LIMIT 1;
  IF wisam_id IS NULL THEN
    RAISE NOTICE 'لم يُعثر على wisamdandash3@gmail.com في auth.users. تأكد من تسجيل الدخول به أولاً.';
    RETURN;
  END IF;

  -- 2) الحصول على مستخدم آخر (للمطابقات والرسائل)
  SELECT id INTO other_id FROM auth.users WHERE id != wisam_id LIMIT 1;
  IF other_id IS NULL THEN
    RAISE NOTICE 'يجب وجود مستخدم آخر للتجربة. أنشئ حساباً ثانياً أو استخدم حساباً موجوداً.';
    RETURN;
  END IF;

  -- 3) رسائل تجريبية (محادثة بين wisam والمستخدم الآخر)
  INSERT INTO public.messages (sender_id, receiver_id, content)
  VALUES
    (other_id, wisam_id, 'مرحباً! كيف حالك؟'),
    (wisam_id, other_id, 'أهلاً، أنا بخير شكراً!'),
    (other_id, wisam_id, 'أحب بروفايلك 😊')
  ON CONFLICT DO NOTHING;

  -- 4) مطابقات (profile_likes): نحتاج item_id من profile_answers للمستخدم الآخر
  SELECT id INTO other_item_id FROM profile_answers WHERE profile_id = other_id LIMIT 1;
  IF other_item_id IS NOT NULL THEN
    -- إعجاب من المستخدم الآخر بـ wisam (يدخل في "أعجبوك")
    INSERT INTO profile_likes (from_user_id, to_user_id, item_id)
    SELECT other_id, wisam_id, id FROM profile_answers WHERE profile_id = wisam_id LIMIT 1
    ON CONFLICT (from_user_id, to_user_id, item_id) DO NOTHING;
    -- إعجاب من wisam بالمستخدم الآخر (مطابقة متبادلة)
    INSERT INTO profile_likes (from_user_id, to_user_id, item_id)
    VALUES (wisam_id, other_id, other_item_id)
    ON CONFLICT (from_user_id, to_user_id, item_id) DO NOTHING;
  ELSE
    RAISE NOTICE 'المطابقات تحتاج profile_answers للمستخدم الآخر. أضف صوراً أو أجوبة لبروفايله أولاً.';
  END IF;

  RAISE NOTICE 'تم إضافة بيانات تجريبية لـ wisamdandash3@gmail.com';
END $$;
