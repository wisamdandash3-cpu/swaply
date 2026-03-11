-- جدول profiles: بيانات المستخدم للتطابق (اللغات، الأطفال، الموقع)
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
  -- اللغات التي يتكلمها المستخدم (رموز مثل en, ar)
  languages TEXT[] DEFAULT '{}',
  -- تفضيل الأطفال
  children_preference TEXT CHECK (children_preference IN (
    'have_kids',
    'want_kids',
    'no_kids',
    'prefer_not'
  )),
  -- الموقع
  city TEXT,
  country TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "الجميع يقرأ البروفايلات" ON profiles FOR SELECT USING (true);
CREATE POLICY "المستخدم يعدل بروفايله" ON profiles FOR ALL USING (auth.uid() = user_id);

-- تحديث updated_at تلقائياً (اختياري)
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE PROCEDURE set_updated_at();
