-- جدول الشكاوى: عندما يشكو مستخدم من مستخدم آخر
CREATE TABLE IF NOT EXISTS user_complaints (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  reported_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  reason TEXT,
  context TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_user_complaints_reporter ON user_complaints(reporter_id);
CREATE INDEX IF NOT EXISTS idx_user_complaints_reported ON user_complaints(reported_id);
CREATE INDEX IF NOT EXISTS idx_user_complaints_created ON user_complaints(created_at DESC);

ALTER TABLE user_complaints ENABLE ROW LEVEL SECURITY;

-- المستخدم يرسل شكوى فقط (INSERT) و يقرأ شكاويه فقط (SELECT)
DROP POLICY IF EXISTS "user_complaints_insert_own" ON user_complaints;
CREATE POLICY "user_complaints_insert_own" ON user_complaints
  FOR INSERT WITH CHECK (auth.uid() = reporter_id);

DROP POLICY IF EXISTS "user_complaints_select_own" ON user_complaints;
CREATE POLICY "user_complaints_select_own" ON user_complaints
  FOR SELECT USING (auth.uid() = reporter_id);

-- الإدارة تقرأ الكل عبر service_role
