-- ============================================================
-- 014: حد أقصى لطول photo_url في الرسائل (حماية من روابط ضخمة)
-- تشغيل بعد 013 في Supabase SQL Editor
-- ============================================================

ALTER TABLE public.messages DROP CONSTRAINT IF EXISTS messages_photo_url_length;
ALTER TABLE public.messages ADD CONSTRAINT messages_photo_url_length
  CHECK (photo_url IS NULL OR char_length(photo_url) <= 2048);
