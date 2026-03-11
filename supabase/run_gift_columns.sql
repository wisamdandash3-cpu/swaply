-- تشغيل هذا الملف في Supabase: SQL Editor
-- يضيف أعمدة الهدية لجدول profile_likes حتى لا يظهر خطأ PGRST204 عند "أرسل شعورك"

ALTER TABLE profile_likes
  ADD COLUMN IF NOT EXISTS gift_type TEXT,
  ADD COLUMN IF NOT EXISTS gift_message TEXT;

ALTER TABLE profile_likes
  ALTER COLUMN item_id DROP NOT NULL;
