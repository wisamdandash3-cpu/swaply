-- جدول الاشتراكات: لتخزين حالة الاشتراك للمستخدمين (للاستخدام لاحقاً مع التحقق من السيرفر).
CREATE TABLE IF NOT EXISTS subscriptions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
  is_active BOOLEAN NOT NULL DEFAULT false,
  product_id TEXT,
  platform TEXT CHECK (platform IN ('ios', 'android')),
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "المستخدم يقرأ اشتراكه" ON subscriptions
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "المستخدم يعدل اشتراكه" ON subscriptions
  FOR ALL USING (auth.uid() = user_id);

-- تحديث updated_at
CREATE TRIGGER subscriptions_updated_at
  BEFORE UPDATE ON subscriptions
  FOR EACH ROW EXECUTE PROCEDURE set_updated_at();
