-- رسائل جماعية من الإدارة (تظهر في محادثة "فريق سوابلي" في التطبيق)
CREATE TABLE IF NOT EXISTS public.broadcast_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_broadcast_messages_created ON public.broadcast_messages(created_at DESC);

ALTER TABLE public.broadcast_messages ENABLE ROW LEVEL SECURITY;

-- المستخدمون يقرؤون الرسائل الجماعية (authenticated و anon لضمان عمل التطبيق)
DROP POLICY IF EXISTS "broadcast_messages_select_authenticated" ON public.broadcast_messages;
CREATE POLICY "broadcast_messages_select_authenticated" ON public.broadcast_messages
  FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "broadcast_messages_select_anon" ON public.broadcast_messages;
CREATE POLICY "broadcast_messages_select_anon" ON public.broadcast_messages
  FOR SELECT TO anon USING (true);

-- الإدراج والحذف عبر service_role فقط (لوحة التحكم)
