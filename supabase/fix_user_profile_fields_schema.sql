-- استبدال جدول user_profile_fields بنسخة متوافقة مع تطبيق Swaply
-- التطبيق يتوقع أعمدة: value (وليس field_value) و visibility

-- حذف الجدول القديم إن وُجد (احذر: سيُحذف البيانات)
DROP TABLE IF EXISTS public.user_profile_fields;

-- إنشاء الجدول بالأعمدة الصحيحة
CREATE TABLE public.user_profile_fields (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    field_key TEXT NOT NULL,
    value TEXT DEFAULT '',
    visibility TEXT DEFAULT 'hidden' CHECK (visibility IN ('hidden', 'visible', 'always_hidden', 'always_visible')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, field_key)
);

CREATE INDEX IF NOT EXISTS idx_user_profile_fields_user ON public.user_profile_fields(user_id);

ALTER TABLE public.user_profile_fields ENABLE ROW LEVEL SECURITY;

-- المستخدم يقرأ ويكتب حقوله فقط
DROP POLICY IF EXISTS "Users can manage their own fields" ON public.user_profile_fields;
DROP POLICY IF EXISTS "Profiles are viewable by everyone" ON public.user_profile_fields;

CREATE POLICY "المستخدم يقرأ حقوله" ON public.user_profile_fields
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "المستخدم يعدل حقوله" ON public.user_profile_fields
  FOR ALL USING (auth.uid() = user_id);
