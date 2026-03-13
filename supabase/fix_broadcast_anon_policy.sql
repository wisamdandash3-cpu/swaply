-- إذا لم تظهر الرسالة الجماعية في التطبيق: شغّل هذا السكربت في Supabase → SQL Editor
-- يسمح لجميع المستخدمين (بما فيهم anon) بقراءة الرسائل الجماعية

DROP POLICY IF EXISTS "broadcast_messages_select_anon" ON public.broadcast_messages;
CREATE POLICY "broadcast_messages_select_anon" ON public.broadcast_messages
  FOR SELECT TO anon USING (true);
