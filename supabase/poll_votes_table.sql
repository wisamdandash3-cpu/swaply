-- جدول أصوات الاستطلاع: كل مستخدم يصوّت مرة واحدة لكل استطلاع (خيار واحد).
-- profile_answer_id = id صف الاستطلاع في profile_answers (item_type = 'poll').

CREATE TABLE IF NOT EXISTS public.poll_votes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  profile_answer_id UUID NOT NULL REFERENCES public.profile_answers(id) ON DELETE CASCADE,
  voter_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  option_index INT NOT NULL CHECK (option_index >= 0),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(profile_answer_id, voter_user_id)
);

CREATE INDEX IF NOT EXISTS idx_poll_votes_profile_answer
  ON public.poll_votes(profile_answer_id);
CREATE INDEX IF NOT EXISTS idx_poll_votes_voter
  ON public.poll_votes(voter_user_id);

ALTER TABLE public.poll_votes ENABLE ROW LEVEL SECURITY;

-- أي شخص يمكنه رؤية عدد الأصوات (للعرض العام).
DROP POLICY IF EXISTS "poll_votes_select" ON public.poll_votes;
CREATE POLICY "poll_votes_select" ON public.poll_votes
  FOR SELECT USING (true);

-- المستخدم المسجّل فقط يمكنه إضافة أو تغيير صوته (voter_user_id = auth.uid()).
DROP POLICY IF EXISTS "poll_votes_insert_own" ON public.poll_votes;
CREATE POLICY "poll_votes_insert_own" ON public.poll_votes
  FOR INSERT WITH CHECK (auth.uid() = voter_user_id);

DROP POLICY IF EXISTS "poll_votes_update_own" ON public.poll_votes;
CREATE POLICY "poll_votes_update_own" ON public.poll_votes
  FOR UPDATE USING (auth.uid() = voter_user_id)
  WITH CHECK (auth.uid() = voter_user_id);

DROP POLICY IF EXISTS "poll_votes_delete_own" ON public.poll_votes;
CREATE POLICY "poll_votes_delete_own" ON public.poll_votes
  FOR DELETE USING (auth.uid() = voter_user_id);
