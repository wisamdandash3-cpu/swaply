-- تفعيل Realtime لجدول messages حتى تظهر الرسائل الجديدة فوراً دون الخروج من المحادثة.
-- مطلوب: انسخ هذا الملف والصقه في Supabase → SQL Editor → Run.
-- أو من لوحة التحكم: Database → Publications → supabase_realtime → إضافة جدول messages.
--
ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
