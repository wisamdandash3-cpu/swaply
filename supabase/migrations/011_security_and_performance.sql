-- ============================================================
-- 011: أمان المحفظة والاشتراكات، استبعاد المحظورين من الاكتشاف، فهرسة، rate limiting
-- تشغيل: Supabase Dashboard → SQL Editor → Run
-- ============================================================

-- ----- 1) المحفظة (user_wallet): المستخدم يقرأ فقط، الإنشاء والخصم عبر دوال آمنة -----
DROP POLICY IF EXISTS "المستخدم يعدل رصيده" ON user_wallet;
-- السماح للمستخدم بقراءة رصيده فقط (لا UPDATE ولا INSERT من العميل)
CREATE POLICY "user_wallet_select_own" ON user_wallet
  FOR SELECT USING (auth.uid() = user_id);

-- لا سياسة INSERT/UPDATE للمستخدم العادي؛ الإنشاء والخصم عبر الدوال أدناه.

-- دالة: إنشاء محفظة إن لم تكن موجودة وإرجاع الرصيد (رصيد ابتدائي 5 ورد، 2 خاتم، 1 قهوة)
CREATE OR REPLACE FUNCTION public.get_or_create_wallet()
RETURNS TABLE (roses_balance int, rings_balance int, coffee_balance int)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO user_wallet (user_id, roses_balance, rings_balance, coffee_balance)
  VALUES (auth.uid(), 5, 2, 1)
  ON CONFLICT (user_id) DO NOTHING;
  RETURN QUERY
  SELECT uw.roses_balance::int, uw.rings_balance::int, uw.coffee_balance::int
  FROM user_wallet uw
  WHERE uw.user_id = auth.uid();
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_or_create_wallet() TO authenticated;

-- دالة: خصم هدية واحدة (وردة / خاتم / قهوة). تُرجع true إذا تم الخصم.
CREATE OR REPLACE FUNCTION public.deduct_gift(p_gift_type text)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  col text;
  row_count int;
BEGIN
  col := CASE p_gift_type
    WHEN 'rose_gift' THEN 'roses_balance'
    WHEN 'ring_gift' THEN 'rings_balance'
    WHEN 'coffee_gift' THEN 'coffee_balance'
    ELSE NULL
  END;
  IF col IS NULL THEN
    RETURN false;
  END IF;
  EXECUTE format(
    'UPDATE user_wallet SET %I = %I - 1, updated_at = NOW() WHERE user_id = $1 AND %I >= 1',
    col, col, col
  ) USING auth.uid();
  GET DIAGNOSTICS row_count = ROW_COUNT;
  RETURN row_count > 0;
END;
$$;

GRANT EXECUTE ON FUNCTION public.deduct_gift(text) TO authenticated;

-- ----- 2) الاشتراكات (subscriptions): المستخدم يقرأ فقط (إزالة صلاحية التعديل) -----
DROP POLICY IF EXISTS "المستخدم يعدل اشتراكه" ON subscriptions;
-- سياسة "المستخدم يقرأ اشتراكه" تبقى من migration 004؛ التحديث/الإدراج من السيرفر فقط

-- ----- 3) قائمة بروفايلات الاكتشاف مع استبعاد المحظورين إدارياً -----
CREATE OR REPLACE FUNCTION public.get_discoverable_profile_ids(
  p_exclude_user_id uuid,
  p_exclude_ids uuid[] DEFAULT '{}'
)
RETURNS SETOF uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT DISTINCT pa.profile_id
  FROM profile_answers pa
  WHERE pa.profile_id <> p_exclude_user_id
    AND pa.profile_id <> ALL(COALESCE(p_exclude_ids, ARRAY[]::uuid[]))
    AND NOT EXISTS (
      SELECT 1 FROM admin_banned_users ab WHERE ab.user_id = pa.profile_id
    );
$$;

GRANT EXECUTE ON FUNCTION public.get_discoverable_profile_ids(uuid, uuid[]) TO authenticated;

-- ----- 4) فهرس لتحسين استعلام الاكتشاف -----
CREATE INDEX IF NOT EXISTS idx_profile_answers_profile_id ON profile_answers(profile_id);

-- ----- 5) Rate limiting: جدول ودالة وربط بالرسائل والشكاوى -----
CREATE TABLE IF NOT EXISTS rate_limit_tracking (
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  action text NOT NULL,
  window_start timestamptz NOT NULL,
  count int NOT NULL DEFAULT 0,
  PRIMARY KEY (user_id, action, window_start)
);

ALTER TABLE rate_limit_tracking ENABLE ROW LEVEL SECURITY;
-- لا نسمح للمستخدمين بقراءة/كتابة هذا الجدول؛ الاستخدام عبر الدالة فقط (SECURITY DEFINER)

CREATE OR REPLACE FUNCTION public.check_rate_limit(
  p_action text,
  p_max_count int,
  p_window_seconds int
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_window timestamptz;
  v_count int;
BEGIN
  v_window := date_trunc('second', NOW() - (extract(epoch from NOW())::bigint % p_window_seconds || ' seconds')::interval);
  -- تبسيط: نستخدم نافذة دقيقة للرسائل وساعة للشكاوى
  IF p_window_seconds >= 3600 THEN
    v_window := date_trunc('hour', NOW());
  ELSE
    v_window := date_trunc('minute', NOW());
  END IF;

  INSERT INTO rate_limit_tracking (user_id, action, window_start, count)
  VALUES (auth.uid(), p_action, v_window, 1)
  ON CONFLICT (user_id, action, window_start)
  DO UPDATE SET count = rate_limit_tracking.count + 1;

  SELECT r.count INTO v_count
  FROM rate_limit_tracking r
  WHERE r.user_id = auth.uid() AND r.action = p_action AND r.window_start = v_window;

  IF v_count > p_max_count THEN
    RAISE EXCEPTION 'rate_limit_exceeded' USING errcode = 'PGRST301';
  END IF;
END;
$$;

-- دالة تُستدعى قبل إدراج رسالة (من trigger)
CREATE OR REPLACE FUNCTION public.check_message_rate_limit()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM check_rate_limit('send_message', 30, 60);
  RETURN NEW;
END;
$$;

-- دالة تُستدعى قبل إدراج شكوى
CREATE OR REPLACE FUNCTION public.check_complaint_rate_limit()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM check_rate_limit('complaint', 5, 3600);
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_messages_rate_limit ON public.messages;
CREATE TRIGGER trg_messages_rate_limit
  BEFORE INSERT ON public.messages
  FOR EACH ROW EXECUTE PROCEDURE public.check_message_rate_limit();

DROP TRIGGER IF EXISTS trg_complaint_rate_limit ON user_complaints;
CREATE TRIGGER trg_complaint_rate_limit
  BEFORE INSERT ON user_complaints
  FOR EACH ROW EXECUTE PROCEDURE public.check_complaint_rate_limit();
