-- مطلوب لـ uuid_generate_v4() في Supabase
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. جدول الأسئلة (اختياري)
CREATE TABLE IF NOT EXISTS profile_questions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  question_text_ar TEXT,
  question_text_en TEXT,
  question_text_de TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. جدول إجابات وعناصر البروفايل (الصور والنصوص)
CREATE TABLE IF NOT EXISTS profile_answers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  profile_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  question_id UUID REFERENCES profile_questions(id) ON DELETE SET NULL,
  item_type TEXT CHECK (item_type IN ('text', 'image', 'video', 'poll')),
  content TEXT NOT NULL, -- رابط الصورة أو نص الإجابة
  sort_order INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. جدول الإعجابات التفاعلية
CREATE TABLE IF NOT EXISTS profile_likes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  from_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  to_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  item_id UUID REFERENCES profile_answers(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(from_user_id, to_user_id, item_id) -- منع تكرار الإعجاب بنفس العنصر
);

-- 4. تفعيل الحماية (RLS) والسياسات
ALTER TABLE profile_answers ENABLE ROW LEVEL SECURITY;
ALTER TABLE profile_likes ENABLE ROW LEVEL SECURITY;

-- سياسات profile_answers
CREATE POLICY "الجميع يمكنهم القراءة" ON profile_answers FOR SELECT USING (true);
CREATE POLICY "المستخدم يتحكم ببياناته" ON profile_answers FOR ALL USING (auth.uid() = profile_id);

-- سياسات profile_likes
CREATE POLICY "عرض الإعجابات للجميع" ON profile_likes FOR SELECT USING (true);
CREATE POLICY "إضافة إعجاب للمسجلين" ON profile_likes FOR INSERT WITH CHECK (auth.uid() = from_user_id);
CREATE POLICY "حذف الإعجاب لصاحبه" ON profile_likes FOR DELETE USING (auth.uid() = from_user_id);
