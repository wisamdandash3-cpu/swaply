-- أعمدة الرد على رسالة: لعرض "على ماذا رد" داخل فقاعة الرسالة.
-- شغّل هذا الملف في Supabase → SQL Editor بعد messages_table.sql.

ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS reply_to_id UUID REFERENCES public.messages(id) ON DELETE SET NULL;
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS reply_to_content TEXT;
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS reply_to_sender_id UUID REFERENCES auth.users(id) ON DELETE SET NULL;
