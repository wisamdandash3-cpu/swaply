-- إضافة عمود photo_url للرسائل المرسلة على صورة في الاكتشاف.
-- شغّل هذا الملف في Supabase SQL Editor بعد messages_table.sql.
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS photo_url TEXT;
