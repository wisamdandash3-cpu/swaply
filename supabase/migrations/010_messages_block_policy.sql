-- منع إرسال رسائل للمستخدم الذي حظرك: إذا المستقبل (receiver_id) حظر المرسل (sender_id) لا يُقبل INSERT.
-- Run after messages_table.sql and create_blocked_users.sql.

DROP POLICY IF EXISTS "messages_insert_own" ON public.messages;
CREATE POLICY "messages_insert_own" ON public.messages
  FOR INSERT WITH CHECK (
    auth.uid() = sender_id
    AND NOT EXISTS (
      SELECT 1 FROM public.blocked_users bu
      WHERE bu.blocker_id = receiver_id AND bu.blocked_id = sender_id
    )
  );
