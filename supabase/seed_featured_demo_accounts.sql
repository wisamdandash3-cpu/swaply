-- =============================================================================
-- إضافة حسابات تجريبية تظهر في تبويب "مميزون" (١٠٠٪ مكتملة + موثّقة)
-- =============================================================================
-- شغّل هذا الملف في Supabase → SQL Editor مرة واحدة.
-- يستهدف أول 5 مستخدمين لديهم سجل في profile_answers (أو الحسابات demo1–demo5 إن وُجدت).
-- لرؤية التصميم: أنشئ من التطبيق أو من لوحة Authentication عدة حسابات،
-- أضف لكل منها صورة واحدة من "تعديل البروفايل"، ثم شغّل هذا السكربت.
-- =============================================================================

DO $$
DECLARE
  r RECORD;
  uid UUID;
  avatar_url TEXT;
  so INT;
  fkey TEXT;
  field_keys TEXT[] := ARRAY[
    'pronouns', 'gender', 'sexuality', 'im_interested_in', 'match_note',
    'work', 'job_title', 'college_or_university', 'education_level', 'religious_beliefs',
    'home_town', 'politics', 'languages_spoken', 'dating_intentions', 'relationship_type',
    'name', 'age', 'height', 'location', 'ethnicity', 'children', 'family_plans',
    'covid_vaccine', 'pets', 'zodiac_sign', 'drinking', 'smoking', 'marijuana', 'drugs'
  ];
  prompt_json TEXT := '{"prompt_id":"p1","answer":"أحب السفر والقهوة."}';
BEGIN
  FOR r IN (
    SELECT u.id, u.email FROM auth.users u
    WHERE EXISTS (SELECT 1 FROM profile_answers pa WHERE pa.profile_id = u.id LIMIT 1)
    ORDER BY u.created_at DESC
    LIMIT 5
  ) LOOP
    uid := r.id;

    -- 1) صور (6 صور = 60%): نستخدم صورة واحدة ونكررها أو pravatar
    SELECT content INTO avatar_url
    FROM profile_answers
    WHERE profile_id = uid AND item_type = 'image' LIMIT 1;
    IF avatar_url IS NULL THEN
      avatar_url := 'https://i.pravatar.cc/400?u=' || uid::text;
    END IF;
    FOR so IN 0..5 LOOP
      IF NOT EXISTS (SELECT 1 FROM profile_answers WHERE profile_id = uid AND item_type = 'image' AND sort_order = so) THEN
        INSERT INTO profile_answers (profile_id, question_id, item_type, content, sort_order)
        VALUES (uid, NULL, 'image', avatar_url, so);
      END IF;
    END LOOP;

    -- 2) ثلاثة أسئلة مكتوبة (sort_order 100,101,102 = 25%)
    FOR so IN 100..102 LOOP
      IF NOT EXISTS (SELECT 1 FROM profile_answers WHERE profile_id = uid AND item_type = 'text' AND sort_order = so) THEN
        INSERT INTO profile_answers (profile_id, question_id, item_type, content, sort_order)
        VALUES (uid, NULL, 'text', prompt_json, so);
      END IF;
    END LOOP;

    -- 3) حقول البروفايل (28 حقل = 15%)
    FOREACH fkey IN ARRAY field_keys
    LOOP
      INSERT INTO user_profile_fields (user_id, field_key, value, visibility, updated_at)
      VALUES (uid, fkey, 'قيمة تجريبية', 'visible', NOW())
      ON CONFLICT (user_id, field_key) DO UPDATE SET value = 'قيمة تجريبية', visibility = 'visible', updated_at = NOW();
    END LOOP;

    -- 4) توثيق (selfie_verification_status = verified)
    INSERT INTO user_profile_fields (user_id, field_key, value, visibility, updated_at)
    VALUES (uid, 'selfie_verification_status', 'verified', 'hidden', NOW())
    ON CONFLICT (user_id, field_key) DO UPDATE SET value = 'verified', updated_at = NOW();

    RAISE NOTICE 'تم إعداد الحساب المميز: %', r.email;
  END LOOP;

  RAISE NOTICE 'انتهى. الحسابات المحددة أصبحت ١٠٠%% مكتملة وموثّقة وستظهر في "مميزون".';
END $$;
