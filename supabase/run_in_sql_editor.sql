-- ========== انسخ من هنا إلى نهاية الملف والصق في Supabase SQL Editor ثم Run ==========
--
-- RLS policies for profile_answers (verify these exist):
--   profile_answers_select: SELECT for all (true)
--   profile_answers_all: ALL only if auth.uid() = profile_id
--
-- ==========

-- 1) Migration 001 - الجداول الأساسية
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS profile_questions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  question_text_ar TEXT,
  question_text_en TEXT,
  question_text_de TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS profile_answers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  profile_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  question_id UUID REFERENCES profile_questions(id) ON DELETE SET NULL,
  item_type TEXT CHECK (item_type IN ('text', 'image', 'video', 'poll')),
  content TEXT NOT NULL,
  sort_order INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS profile_likes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  from_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  to_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  item_id UUID REFERENCES profile_answers(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(from_user_id, to_user_id, item_id)
);

ALTER TABLE profile_answers ENABLE ROW LEVEL SECURITY;
ALTER TABLE profile_likes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "profile_answers_select" ON profile_answers;
CREATE POLICY "profile_answers_select" ON profile_answers FOR SELECT USING (true);
DROP POLICY IF EXISTS "profile_answers_all" ON profile_answers;
CREATE POLICY "profile_answers_all" ON profile_answers FOR ALL USING (auth.uid() = profile_id);

DROP POLICY IF EXISTS "profile_likes_select" ON profile_likes;
CREATE POLICY "profile_likes_select" ON profile_likes FOR SELECT USING (true);
DROP POLICY IF EXISTS "profile_likes_insert" ON profile_likes;
CREATE POLICY "profile_likes_insert" ON profile_likes FOR INSERT WITH CHECK (auth.uid() = from_user_id);
DROP POLICY IF EXISTS "profile_likes_delete" ON profile_likes;
CREATE POLICY "profile_likes_delete" ON profile_likes FOR DELETE USING (auth.uid() = from_user_id);

-- 2) Migration 002 - جدول profiles (اللغات، الأطفال، الموقع)
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
  languages TEXT[] DEFAULT '{}',
  children_preference TEXT CHECK (children_preference IN (
    'have_kids', 'want_kids', 'no_kids', 'prefer_not'
  )),
  city TEXT,
  country TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "profiles_select" ON profiles;
CREATE POLICY "profiles_select" ON profiles FOR SELECT USING (true);
DROP POLICY IF EXISTS "profiles_all" ON profiles;
CREATE POLICY "profiles_all" ON profiles FOR ALL USING (auth.uid() = user_id);

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS profiles_updated_at ON profiles;
CREATE TRIGGER profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE PROCEDURE set_updated_at();

-- 3) Migration 003 - جدول حقول البروفايل (العمل، التعليم، اللغات، إلخ)
CREATE TABLE IF NOT EXISTS user_profile_fields (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  field_key TEXT NOT NULL,
  value TEXT DEFAULT '',
  visibility TEXT DEFAULT 'hidden' CHECK (visibility IN ('hidden', 'visible', 'always_hidden', 'always_visible')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, field_key)
);

CREATE INDEX IF NOT EXISTS idx_user_profile_fields_user ON user_profile_fields(user_id);

ALTER TABLE user_profile_fields ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "المستخدم يقرأ حقوله" ON user_profile_fields;
CREATE POLICY "المستخدم يقرأ حقوله" ON user_profile_fields FOR SELECT USING (auth.uid() = user_id);
-- القراءة للجميع (لاكتشاف البروفايلات والمطابقة)
DROP POLICY IF EXISTS "profile_fields_viewable_by_everyone" ON user_profile_fields;
CREATE POLICY "profile_fields_viewable_by_everyone" ON user_profile_fields FOR SELECT USING (true);

DROP POLICY IF EXISTS "المستخدم يعدل حقوله" ON user_profile_fields;
CREATE POLICY "المستخدم يعدل حقوله" ON user_profile_fields FOR ALL USING (auth.uid() = user_id);

DROP TRIGGER IF EXISTS user_profile_fields_updated_at ON user_profile_fields;
CREATE TRIGGER user_profile_fields_updated_at
  BEFORE UPDATE ON user_profile_fields
  FOR EACH ROW EXECUTE PROCEDURE set_updated_at();
