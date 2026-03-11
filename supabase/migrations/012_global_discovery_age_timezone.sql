-- ============================================================
-- 012: اكتشاف عالمي (فلتر مسافة + ترقيم صفحات)، وقت، إقليم، حد عمر 18+
-- تشغيل بعد 011 في Supabase SQL Editor
-- ============================================================

-- ----- 1) دالة الاكتشاف مع فلتر المسافة وترقيم الصفحات -----
-- مسافة هافرساين (كم): 6371 * 2 * asin(sqrt(...))
CREATE OR REPLACE FUNCTION public.get_discoverable_profile_ids(
  p_exclude_user_id uuid,
  p_exclude_ids uuid[] DEFAULT '{}',
  p_max_km double precision DEFAULT NULL,
  p_user_lat double precision DEFAULT NULL,
  p_user_lng double precision DEFAULT NULL,
  p_limit int DEFAULT 500,
  p_offset int DEFAULT 0
)
RETURNS SETOF uuid
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF p_max_km IS NOT NULL AND p_max_km > 0
     AND p_user_lat IS NOT NULL AND p_user_lng IS NOT NULL THEN
    -- فلتر المسافة: فقط من لديهم موقع ضمن p_max_km
    RETURN QUERY
    WITH dist AS (
      SELECT pa.profile_id,
        (6371.0 * 2 * asin(sqrt(
          sin(radians(p_user_lat - p.latitude) / 2) ^ 2
          + cos(radians(p_user_lat)) * cos(radians(p.latitude))
            * sin(radians(p_user_lng - p.longitude) / 2) ^ 2
        ))) AS d_km
      FROM profile_answers pa
      INNER JOIN profiles p ON p.user_id = pa.profile_id
        AND p.latitude IS NOT NULL AND p.longitude IS NOT NULL
      WHERE pa.profile_id <> p_exclude_user_id
        AND pa.profile_id <> ALL(COALESCE(p_exclude_ids, ARRAY[]::uuid[]))
        AND NOT EXISTS (
          SELECT 1 FROM admin_banned_users ab WHERE ab.user_id = pa.profile_id
        )
      GROUP BY pa.profile_id, p.latitude, p.longitude
    )
    SELECT d.profile_id FROM dist d
    WHERE d.d_km <= p_max_km
    ORDER BY d.d_km
    LIMIT GREATEST(1, LEAST(COALESCE(p_limit, 500), 1000))
    OFFSET GREATEST(0, COALESCE(p_offset, 0));
  ELSE
    -- بدون فلتر مسافة: كل المؤهلين مع حد وترقيم
    RETURN QUERY
    SELECT pa.profile_id
    FROM profile_answers pa
    WHERE pa.profile_id <> p_exclude_user_id
      AND pa.profile_id <> ALL(COALESCE(p_exclude_ids, ARRAY[]::uuid[]))
      AND NOT EXISTS (
        SELECT 1 FROM admin_banned_users ab WHERE ab.user_id = pa.profile_id
      )
    GROUP BY pa.profile_id
    ORDER BY random()
    LIMIT GREATEST(1, LEAST(COALESCE(p_limit, 500), 1000))
    OFFSET GREATEST(0, COALESCE(p_offset, 0));
  END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_discoverable_profile_ids(uuid, uuid[], double precision, double precision, double precision, int, int) TO authenticated;

-- ----- 2) حقل المنطقة الزمنية في profiles -----
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS timezone text;

-- ----- 3) حقل الإقليم/الدولة في subscriptions -----
ALTER TABLE subscriptions ADD COLUMN IF NOT EXISTS country text;
ALTER TABLE subscriptions ADD COLUMN IF NOT EXISTS region text;

-- ----- 4) التحقق من عمر 18+ عند حفظ حقل age أو date_of_birth في user_profile_fields -----
CREATE OR REPLACE FUNCTION public.check_profile_age_eligibility()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  age_val int;
  dob_date date;
  min_birth_date date;
BEGIN
  IF NEW.field_key = 'age' AND NEW.value IS NOT NULL AND trim(NEW.value) <> '' THEN
    age_val := (regexp_replace(NEW.value, '[^0-9]', '', 'g'))::int;
    IF age_val < 18 THEN
      RAISE EXCEPTION 'age_below_minimum' USING errcode = 'PGRST302';
    END IF;
  END IF;

  IF NEW.field_key = 'date_of_birth' AND NEW.value IS NOT NULL AND trim(NEW.value) <> '' THEN
    BEGIN
      dob_date := (NEW.value)::date;
    EXCEPTION WHEN OTHERS THEN
      RETURN NEW;
    END;
    min_birth_date := (current_date - interval '18 years')::date;
    IF dob_date > min_birth_date THEN
      RAISE EXCEPTION 'age_below_minimum' USING errcode = 'PGRST302';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_user_profile_fields_age_check ON user_profile_fields;
CREATE TRIGGER trg_user_profile_fields_age_check
  BEFORE INSERT OR UPDATE ON user_profile_fields
  FOR EACH ROW EXECUTE PROCEDURE public.check_profile_age_eligibility();
