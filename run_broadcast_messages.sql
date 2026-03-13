-- ============================================================
-- رسائل جماعية للوحة التحكم (إرسال رسالة للجميع)
-- انسخ هذا الملف بالكامل والصقه في Supabase → SQL Editor → Run
-- ============================================================

-- 1) إنشاء جدول الرسائل الجماعية
CREATE TABLE IF NOT EXISTS public.broadcast_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_broadcast_messages_created ON public.broadcast_messages(created_at DESC);

ALTER TABLE public.broadcast_messages ENABLE ROW LEVEL SECURITY;

-- 2) سياسات القراءة (حتى يظهر المحتوى في التطبيق)
DROP POLICY IF EXISTS "broadcast_messages_select_authenticated" ON public.broadcast_messages;
CREATE POLICY "broadcast_messages_select_authenticated" ON public.broadcast_messages
  FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "broadcast_messages_select_anon" ON public.broadcast_messages;
CREATE POLICY "broadcast_messages_select_anon" ON public.broadcast_messages
  FOR SELECT TO anon USING (true);

-- الإدراج من لوحة التحكم عبر service_role فقط
