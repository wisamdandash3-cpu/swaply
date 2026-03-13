-- تشغيل من Supabase SQL Editor: إضافة صورة/فيديو للرسائل الجماعية + bucket الوسائط
ALTER TABLE public.broadcast_messages
  ADD COLUMN IF NOT EXISTS image_url TEXT,
  ADD COLUMN IF NOT EXISTS video_url TEXT;

INSERT INTO storage.buckets (id, name, public)
VALUES ('broadcast-media', 'broadcast-media', true)
ON CONFLICT (id) DO UPDATE SET public = true;
