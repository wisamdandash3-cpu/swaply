-- عمود نوع الهدية المُرد عليها: لعرض أيقونة الهدية (ورد/خاتم/قهوة) داخل كتلة الرد.
-- شغّل هذا الملف في Supabase → SQL Editor بعد messages_reply_columns.sql.

ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS reply_to_photo_url TEXT;
