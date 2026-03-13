-- إضافة صورة/فيديو للرسائل الجماعية
ALTER TABLE public.broadcast_messages
  ADD COLUMN IF NOT EXISTS image_url TEXT,
  ADD COLUMN IF NOT EXISTS video_url TEXT;

-- bucket لوسائط الرسائل الجماعية (لوحة التحكم ترفع عبر service_role)
INSERT INTO storage.buckets (id, name, public)
VALUES ('broadcast-media', 'broadcast-media', true)
ON CONFLICT (id) DO UPDATE SET public = true;
