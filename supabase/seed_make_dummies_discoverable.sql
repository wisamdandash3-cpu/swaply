-- =============================================================================
-- جعل الحسابات الوهمية (demo1–demo5) تظهر في الرئيسية/الاكتشاف
-- =============================================================================
-- الحسابات الوهمية لديها صورة واحدة فقط فنسبة الإكمال 10%، والاكتشاف يطلب ≥50%.
-- هذا السكربت يضيف 4 صور إضافية لكل حساب وهمي (المجموع 5 صور = 50%) فيصبحون ظاهرين.
-- شغّله مرة واحدة في Supabase → SQL Editor.
-- =============================================================================

DO $$
DECLARE
  r RECORD;
  avatar_url TEXT;
  so INT;
BEGIN
  FOR r IN (
    SELECT id, email FROM auth.users
    WHERE email IN (
      'demo1@swaply.local', 'demo2@swaply.local', 'demo3@swaply.local',
      'demo4@swaply.local', 'demo5@swaply.local'
    )
  ) LOOP
    SELECT content INTO avatar_url
    FROM profile_answers
    WHERE profile_id = r.id AND item_type = 'image' LIMIT 1;
    IF avatar_url IS NULL THEN
      avatar_url := 'https://i.pravatar.cc/400?u=' || r.id::text;
    END IF;
    FOR so IN 201..204 LOOP
      IF NOT EXISTS (SELECT 1 FROM profile_answers WHERE profile_id = r.id AND sort_order = so) THEN
        INSERT INTO profile_answers (profile_id, question_id, item_type, content, sort_order)
        VALUES (r.id, NULL, 'image', avatar_url, so);
      END IF;
    END LOOP;
  END LOOP;
  RAISE NOTICE 'تم. الحسابات الوهمية الآن تظهر في الرئيسية (الاكتشاف).';
END $$;
