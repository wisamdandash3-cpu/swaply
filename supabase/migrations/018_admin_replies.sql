-- ردود الإدارة على الشكاوى (يُرسلها الأدمن للمستخدم الشاكي)
CREATE TABLE IF NOT EXISTS public.admin_replies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  complaint_id UUID NULL,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_admin_replies_user ON public.admin_replies(user_id);
CREATE INDEX IF NOT EXISTS idx_admin_replies_created ON public.admin_replies(created_at DESC);

ALTER TABLE public.admin_replies ENABLE ROW LEVEL SECURITY;

-- المستخدم يقرأ ردود الإدارة الموجهة له فقط
DROP POLICY IF EXISTS "admin_replies_select_own" ON public.admin_replies;
CREATE POLICY "admin_replies_select_own" ON public.admin_replies
  FOR SELECT USING (auth.uid() = user_id);

-- الإدراج والحذف عبر service_role فقط (لوحة التحكم)
