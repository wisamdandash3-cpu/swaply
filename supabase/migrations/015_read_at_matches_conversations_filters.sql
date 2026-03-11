-- ============================================================
-- 015: read_at للرسائل، قائمة محادثات، مطابقات، توسيع فلتر الاكتشاف (عمر/جنس)
-- تشغيل بعد 014 في Supabase SQL Editor
--
-- ملاحظة: تفضيلات الفلتر (filter_max_distance, filter_age_min, ...) تُحفظ في
-- user_profile_fields. الجدول لا يفرض قيداً على field_key (TEXT فقط)،
-- فجميع مفاتيح الفلتر مسموحة.
-- ============================================================

-- ----- 1) عمود read_at في messages (لتحديد الرسائل المقروءة) -----
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS read_at TIMESTAMPTZ;

-- المستقبل فقط يحدّث read_at لرسائل الواردة إليه
DROP POLICY IF EXISTS "messages_update_read_at" ON public.messages;
CREATE POLICY "messages_update_read_at" ON public.messages
  FOR UPDATE
  USING (auth.uid() = receiver_id)
  WITH CHECK (auth.uid() = receiver_id);

-- ----- 2) دالة وضع رسائل محادثة كمقروءة -----
CREATE OR REPLACE FUNCTION public.mark_conversation_read(
  p_receiver_id uuid,
  p_sender_id uuid
)
RETURNS int
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  updated int;
BEGIN
  IF p_receiver_id IS NULL OR p_sender_id IS NULL THEN
    RETURN 0;
  END IF;
  IF p_receiver_id != auth.uid() THEN
    RETURN 0;
  END IF;
  UPDATE public.messages
  SET read_at = NOW()
  WHERE receiver_id = p_receiver_id
    AND sender_id = p_sender_id
    AND read_at IS NULL;
  GET DIAGNOSTICS updated = ROW_COUNT;
  RETURN updated;
END;
$$;

GRANT EXECUTE ON FUNCTION public.mark_conversation_read(uuid, uuid) TO authenticated;

-- ----- 3) دالة قائمة المحادثات مع ترتيب حسب آخر رسالة وعدد غير المقروءة -----
CREATE OR REPLACE FUNCTION public.get_conversation_list(p_user_id uuid)
RETURNS TABLE(
  partner_id uuid,
  last_message_at timestamptz,
  unread_count bigint
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  WITH sent AS (
    SELECT receiver_id AS pid, MAX(created_at) AS t
    FROM messages
    WHERE sender_id = p_user_id
    GROUP BY receiver_id
  ),
  received AS (
    SELECT sender_id AS pid, MAX(created_at) AS t
    FROM messages
    WHERE receiver_id = p_user_id
    GROUP BY sender_id
  ),
  merged AS (
    SELECT COALESCE(s.pid, r.pid) AS partner_id,
           GREATEST(COALESCE(s.t, '1970-01-01'::timestamptz), COALESCE(r.t, '1970-01-01'::timestamptz)) AS last_message_at
    FROM sent s
    FULL OUTER JOIN received r ON s.pid = r.pid
  ),
  unread AS (
    SELECT sender_id AS partner_id, COUNT(*)::bigint AS cnt
    FROM messages
    WHERE receiver_id = p_user_id AND read_at IS NULL
    GROUP BY sender_id
  )
  SELECT m.partner_id,
         m.last_message_at,
         COALESCE(u.cnt, 0)
  FROM merged m
  LEFT JOIN unread u ON m.partner_id = u.partner_id
  WHERE m.partner_id IS NOT NULL
  ORDER BY m.last_message_at DESC NULLS LAST;
$$;

GRANT EXECUTE ON FUNCTION public.get_conversation_list(uuid) TO authenticated;

-- ----- 4) دالة المطابقات (معرّف الشريك + تاريخ المطابقة) -----
CREATE OR REPLACE FUNCTION public.get_my_matches(p_user_id uuid)
RETURNS TABLE(partner_id uuid, matched_at timestamptz)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  WITH pairs AS (
    SELECT pl1.from_user_id AS u1, pl1.to_user_id AS u2,
           GREATEST(pl1.created_at, pl2.created_at) AS matched_at
    FROM profile_likes pl1
    INNER JOIN profile_likes pl2
      ON pl1.from_user_id = pl2.to_user_id AND pl1.to_user_id = pl2.from_user_id
    WHERE pl1.from_user_id = p_user_id OR pl1.to_user_id = p_user_id
  )
  SELECT CASE WHEN u1 = p_user_id THEN u2 ELSE u1 END AS partner_id,
         matched_at
  FROM pairs;
$$;

GRANT EXECUTE ON FUNCTION public.get_my_matches(uuid) TO authenticated;

-- ----- 5) توسيع get_discoverable_profile_ids: فلتر عمر وجنس (اختياري) -----
-- إسقاط الدالة الحالية وإعادة إنشائها مع معاملات إضافية
DROP FUNCTION IF EXISTS public.get_discoverable_profile_ids(uuid, uuid[], double precision, double precision, double precision, int, int);

CREATE OR REPLACE FUNCTION public.get_discoverable_profile_ids(
  p_exclude_user_id uuid,
  p_exclude_ids uuid[] DEFAULT '{}',
  p_max_km double precision DEFAULT NULL,
  p_user_lat double precision DEFAULT NULL,
  p_user_lng double precision DEFAULT NULL,
  p_limit int DEFAULT 500,
  p_offset int DEFAULT 0,
  p_age_min int DEFAULT NULL,
  p_age_max int DEFAULT NULL,
  p_interested_in text DEFAULT NULL
)
RETURNS SETOF uuid
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  age_filter boolean;
  gender_filter boolean;
BEGIN
  age_filter := (p_age_min IS NOT NULL AND p_age_min > 0) OR (p_age_max IS NOT NULL AND p_age_max > 0);
  gender_filter := p_interested_in IS NOT NULL AND trim(p_interested_in) <> '';

  IF p_max_km IS NOT NULL AND p_max_km > 0
     AND p_user_lat IS NOT NULL AND p_user_lng IS NOT NULL THEN
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
        AND NOT EXISTS (SELECT 1 FROM admin_banned_users ab WHERE ab.user_id = pa.profile_id)
        AND (NOT age_filter OR EXISTS (
          SELECT 1 FROM user_profile_fields upf
          WHERE upf.user_id = pa.profile_id AND upf.field_key = 'age'
            AND trim(upf.value) ~ '^\d+$'
            AND (p_age_min IS NULL OR (regexp_replace(upf.value, '[^0-9]', '', 'g'))::int >= p_age_min)
            AND (p_age_max IS NULL OR (regexp_replace(upf.value, '[^0-9]', '', 'g'))::int <= p_age_max)
        ))
        AND (NOT gender_filter OR EXISTS (
          SELECT 1 FROM user_profile_fields upf2
          WHERE upf2.user_id = pa.profile_id AND upf2.field_key = 'gender'
            AND (
              (p_interested_in ILIKE '%men%' AND (upf2.value ILIKE '%man%' OR upf2.value ILIKE '%male%'))
              OR (p_interested_in ILIKE '%women%' AND (upf2.value ILIKE '%woman%' OR upf2.value ILIKE '%female%'))
              OR (p_interested_in ILIKE '%male%' AND (upf2.value ILIKE '%man%' OR upf2.value ILIKE '%male%'))
              OR (p_interested_in ILIKE '%female%' AND (upf2.value ILIKE '%woman%' OR upf2.value ILIKE '%female%'))
            )
        ))
      GROUP BY pa.profile_id, p.latitude, p.longitude
    )
    SELECT d.profile_id FROM dist d
    WHERE d.d_km <= p_max_km
    ORDER BY d.d_km
    LIMIT GREATEST(1, LEAST(COALESCE(p_limit, 500), 1000))
    OFFSET GREATEST(0, COALESCE(p_offset, 0));
  ELSE
    RETURN QUERY
    SELECT pa.profile_id
    FROM profile_answers pa
    WHERE pa.profile_id <> p_exclude_user_id
      AND pa.profile_id <> ALL(COALESCE(p_exclude_ids, ARRAY[]::uuid[]))
      AND NOT EXISTS (SELECT 1 FROM admin_banned_users ab WHERE ab.user_id = pa.profile_id)
      AND (NOT age_filter OR EXISTS (
        SELECT 1 FROM user_profile_fields upf
        WHERE upf.user_id = pa.profile_id AND upf.field_key = 'age'
          AND trim(upf.value) ~ '^\d+$'
          AND (p_age_min IS NULL OR (regexp_replace(upf.value, '[^0-9]', '', 'g'))::int >= p_age_min)
          AND (p_age_max IS NULL OR (regexp_replace(upf.value, '[^0-9]', '', 'g'))::int <= p_age_max)
      ))
      AND (NOT gender_filter OR EXISTS (
        SELECT 1 FROM user_profile_fields upf2
        WHERE upf2.user_id = pa.profile_id AND upf2.field_key = 'gender'
          AND (
            (p_interested_in ILIKE '%men%' AND (upf2.value ILIKE '%man%' OR upf2.value ILIKE '%male%'))
            OR (p_interested_in ILIKE '%women%' AND (upf2.value ILIKE '%woman%' OR upf2.value ILIKE '%female%'))
            OR (p_interested_in ILIKE '%male%' AND (upf2.value ILIKE '%man%' OR upf2.value ILIKE '%male%'))
            OR (p_interested_in ILIKE '%female%' AND (upf2.value ILIKE '%woman%' OR upf2.value ILIKE '%female%'))
          )
      ))
    GROUP BY pa.profile_id
    ORDER BY random()
    LIMIT GREATEST(1, LEAST(COALESCE(p_limit, 500), 1000))
    OFFSET GREATEST(0, COALESCE(p_offset, 0));
  END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_discoverable_profile_ids(uuid, uuid[], double precision, double precision, double precision, int, int, int, int, text) TO authenticated;
