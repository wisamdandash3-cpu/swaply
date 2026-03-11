-- إصلاح قيد item_type في profile_answers ليقبل 'video' و 'poll' بالإضافة إلى 'text' و 'image'.
-- نفّذ هذا الملف في Supabase → SQL Editor ثم Run.

ALTER TABLE profile_answers
  DROP CONSTRAINT IF EXISTS profile_answers_item_type_check;

ALTER TABLE profile_answers
  ADD CONSTRAINT profile_answers_item_type_check
  CHECK (item_type IN ('text', 'image', 'video', 'poll'));
