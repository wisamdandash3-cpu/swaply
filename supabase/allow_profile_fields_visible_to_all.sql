-- شغّل هذا في Supabase → SQL Editor ثم Run
-- يجعل حقول البروفايل (الاسم، الجنس، إلخ) قابلة للقراءة من الجميع (للظهور في الاكتشاف والمطابقة)

DROP POLICY IF EXISTS "profile_fields_viewable_by_everyone" ON user_profile_fields;
CREATE POLICY "profile_fields_viewable_by_everyone" ON user_profile_fields
  FOR SELECT
  USING (true);
