-- =============================================================================
-- حسابات وهمية تعجب ببروفايلك — لمعاينة "معجب بك" (٥ أشخاص)
-- =============================================================================
-- خطوات مهمة:
-- 1. في Supabase: Authentication → Users → انسخ بريدك بالضبط.
-- 2. استبدل YOUR_EMAIL_HERE أدناه بهذا البريد (نفس الحروف والأحرف الكبيرة/الصغيرة).
-- 3. تأكد أن بروفايلك فيه صورة أو إجابة واحدة على الأقل (من التطبيق).
-- 4. Supabase → SQL Editor → الصق هذا الملف → Run.
--
-- النتيجة: يظهر في تاب "معجب بك" ٥ بطاقات (سارة، ليلى، نور، ريم، هناء).
-- إذا لم يظهر أحد: شغّل أيضاً seed_add_likes_to_me.sql (بنفس البريد).
-- كلمة مرور الحسابات الوهمية: Demo123!
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- جدول مؤقت لعرض نتيجة التنفيذ في نافذة النتائج
CREATE TEMP TABLE IF NOT EXISTS _seed_result (msg TEXT, likes_count INT);

DO $$
DECLARE
  my_id UUID;
  my_item_id UUID;
  i INT;
  dummy_emails TEXT[] := ARRAY[
    'demo1@swaply.local', 'demo2@swaply.local', 'demo3@swaply.local',
    'demo4@swaply.local', 'demo5@swaply.local'
  ];
  dummy_names TEXT[] := ARRAY['سارة', 'ليلى', 'نور', 'ريم', 'هناء'];
  dummy_avatars TEXT[] := ARRAY[
    'https://i.pravatar.cc/400?u=demo1',
    'https://i.pravatar.cc/400?u=demo2',
    'https://i.pravatar.cc/400?u=demo3',
    'https://i.pravatar.cc/400?u=demo4',
    'https://i.pravatar.cc/400?u=demo5'
  ];
  v_encrypted_pw TEXT;
  v_user_id UUID;
  v_name TEXT;
  v_avatar TEXT;
BEGIN
  DELETE FROM _seed_result;

  -- 1) معرّفك — يجب استبدال YOUR_EMAIL_HERE ببريدك من Supabase → Authentication → Users
  SELECT id INTO my_id FROM auth.users WHERE email = 'wisamdandash1@gmail.com' LIMIT 1;
  IF my_id IS NULL THEN
    RAISE EXCEPTION 'لم يُعثر على المستخدم. استبدل YOUR_EMAIL_HERE ببريدك من Supabase (Authentication → Users) ثم شغّل السكربت مرة أخرى.';
  END IF;

  -- 2) عنصر واحد من بروفايلك (صورة أو إجابة) — مطلوب لربط الإعجاب
  SELECT id INTO my_item_id FROM profile_answers WHERE profile_id = my_id LIMIT 1;
  IF my_item_id IS NULL THEN
    RAISE EXCEPTION 'بروفايلك لا يحتوي على أي صورة أو إجابة. أضف من التطبيق (تعديل البروفايل) ثم شغّل السكربت.';
  END IF;

  v_encrypted_pw := crypt('Demo123!', gen_salt('bf'));

  -- 3) إنشاء 5 حسابات وهمية (تخطي إن وجدت مسبقاً)
  FOR i IN 1..5 LOOP
    SELECT id INTO v_user_id FROM auth.users WHERE email = dummy_emails[i] LIMIT 1;
    IF v_user_id IS NOT NULL THEN
      -- الحساب موجود: نضيف إعجاباً فقط إن لم يكن موجوداً
      INSERT INTO profile_likes (from_user_id, to_user_id, item_id)
      VALUES (v_user_id, my_id, my_item_id)
      ON CONFLICT (from_user_id, to_user_id, item_id) DO NOTHING;
      CONTINUE;
    END IF;

    v_user_id := gen_random_uuid();
    v_name := dummy_names[i];
    v_avatar := dummy_avatars[i];

    INSERT INTO auth.users (
      id, instance_id, aud, role, email, encrypted_password,
      email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at
    ) VALUES (
      v_user_id,
      '00000000-0000-0000-0000-000000000000',
      'authenticated',
      'authenticated',
      dummy_emails[i],
      v_encrypted_pw,
      NOW(),
      '{"provider":"email","providers":["email"]}'::jsonb,
      jsonb_build_object('full_name', v_name),
      NOW(),
      NOW()
    ) ON CONFLICT (id) DO NOTHING;

    IF NOT EXISTS (SELECT 1 FROM auth.identities WHERE user_id = v_user_id) THEN
      INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, created_at, updated_at)
      VALUES (
        v_user_id,
        v_user_id,
        jsonb_build_object('sub', v_user_id::text, 'email', dummy_emails[i]),
        'email',
        dummy_emails[i],
        NOW(),
        NOW()
      );
    END IF;

    -- profile_answers: اسم + 5 صور (نسبة إكمال ≥50% ليظهروا في الرئيسية/الاكتشاف)
    INSERT INTO profile_answers (profile_id, question_id, item_type, content, sort_order)
    VALUES (v_user_id, NULL, 'text', v_name, 1);
    INSERT INTO profile_answers (profile_id, question_id, item_type, content, sort_order)
    VALUES (v_user_id, NULL, 'image', v_avatar, 200),
           (v_user_id, NULL, 'image', v_avatar, 201),
           (v_user_id, NULL, 'image', v_avatar, 202),
           (v_user_id, NULL, 'image', v_avatar, 203),
           (v_user_id, NULL, 'image', v_avatar, 204);

    -- إعجاب من الحساب الوهمي بك (يظهر في "معجب بك")
    INSERT INTO profile_likes (from_user_id, to_user_id, item_id)
    VALUES (v_user_id, my_id, my_item_id)
    ON CONFLICT (from_user_id, to_user_id, item_id) DO NOTHING;
  END LOOP;

  INSERT INTO _seed_result (msg, likes_count)
  SELECT 'تم إنشاء ٥ حسابات وإعجابات. افتح تاب معجب بك في التطبيق (اسحب للتحديث إن لزم).', count(*)::int
  FROM profile_likes WHERE to_user_id = my_id;

  RAISE NOTICE 'تم. عدد الإعجابات الواردة لك: %', (SELECT likes_count FROM _seed_result LIMIT 1);
END $$;

-- عرض النتيجة في نافذة Results
SELECT * FROM _seed_result;
