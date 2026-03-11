-- سياسة حذف الرسائل: المرسل أو المستقبل يمكنه حذف الرسالة (حذف للطرفين).
-- شغّل هذا الملف في Supabase → SQL Editor بعد messages_table.sql.

DROP POLICY IF EXISTS "messages_delete_own" ON public.messages;
CREATE POLICY "messages_delete_own" ON public.messages
  FOR DELETE USING (
    auth.uid() = sender_id OR auth.uid() = receiver_id
  );
