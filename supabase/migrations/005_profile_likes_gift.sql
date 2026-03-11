-- إضافة أعمدة الهدية لجدول profile_likes (تسجيل "إرسال شعورك").
ALTER TABLE profile_likes
  ADD COLUMN IF NOT EXISTS gift_type TEXT,
  ADD COLUMN IF NOT EXISTS gift_message TEXT;

-- جعل item_id قابلاً للإلغاء حتى نتمكن من إدراج سجل هدية بدون عنصر محدد.
ALTER TABLE profile_likes
  ALTER COLUMN item_id DROP NOT NULL;
