-- جدول حقول البروفايل القابلة للتعديل (العمل، التعليم، إلخ)
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

CREATE POLICY "المستخدم يقرأ حقوله" ON user_profile_fields FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "المستخدم يعدل حقوله" ON user_profile_fields FOR ALL USING (auth.uid() = user_id);

CREATE TRIGGER user_profile_fields_updated_at
  BEFORE UPDATE ON user_profile_fields
  FOR EACH ROW EXECUTE PROCEDURE set_updated_at();
