-- ============================================================
-- 013: فهرس موقع، حد طول محتوى، تنظيف rate_limit (عالمي + أداء)
-- تشغيل بعد 012 في Supabase SQL Editor
-- ============================================================

-- ----- 1) فهرس على إحداثيات الموقع لاستعلامات المسافة -----
CREATE INDEX IF NOT EXISTS idx_profiles_latitude_longitude
  ON profiles(latitude, longitude)
  WHERE latitude IS NOT NULL AND longitude IS NOT NULL;

-- ----- 2) حد أقصى لطول المحتوى (حماية من نصوص ضخمة) -----
ALTER TABLE public.messages DROP CONSTRAINT IF EXISTS messages_content_length;
ALTER TABLE public.messages ADD CONSTRAINT messages_content_length
  CHECK (char_length(content) <= 10000);

ALTER TABLE user_complaints DROP CONSTRAINT IF EXISTS user_complaints_reason_length;
ALTER TABLE user_complaints ADD CONSTRAINT user_complaints_reason_length
  CHECK (reason IS NULL OR char_length(reason) <= 2000);

ALTER TABLE user_complaints DROP CONSTRAINT IF EXISTS user_complaints_context_length;
ALTER TABLE user_complaints ADD CONSTRAINT user_complaints_context_length
  CHECK (context IS NULL OR char_length(context) <= 5000);

ALTER TABLE profile_answers DROP CONSTRAINT IF EXISTS profile_answers_content_length;
ALTER TABLE profile_answers ADD CONSTRAINT profile_answers_content_length
  CHECK (char_length(content) <= 50000);

-- ----- 3) تنظيف سجلات rate_limit الأقدم من 24 ساعة -----
CREATE OR REPLACE FUNCTION public.cleanup_old_rate_limits()
RETURNS int
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  deleted int;
BEGIN
  DELETE FROM rate_limit_tracking
  WHERE window_start < (NOW() - interval '24 hours');
  GET DIAGNOSTICS deleted = ROW_COUNT;
  RETURN deleted;
END;
$$;

-- يُنصح بتشغيل cleanup_old_rate_limits دورياً (مثلاً عبر pg_cron أو Edge Function مجدولة).
-- من SQL Editor: SELECT cleanup_old_rate_limits();
