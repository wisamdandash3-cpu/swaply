-- السماح للمستخدم بحذف شكواه وردود الإدارة عليها (محادثة واحدة من التطبيق والقاعدة)
-- user_complaints: حذف شكاوى المستخدم فقط
DROP POLICY IF EXISTS "user_complaints_delete_own" ON public.user_complaints;
CREATE POLICY "user_complaints_delete_own" ON public.user_complaints
  FOR DELETE USING (auth.uid() = reporter_id);

-- admin_replies: حذف ردود الإدارة الموجهة للمستخدم فقط
DROP POLICY IF EXISTS "admin_replies_delete_own" ON public.admin_replies;
CREATE POLICY "admin_replies_delete_own" ON public.admin_replies
  FOR DELETE USING (auth.uid() = user_id);
