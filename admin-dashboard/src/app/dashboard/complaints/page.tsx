import { createAdminClient } from '@/lib/supabase';
import ComplaintsList from './ComplaintsList';

export default async function ComplaintsPage() {
  const admin = createAdminClient();
  const { data: complaints } = await admin
    .from('user_complaints')
    .select('id, reporter_id, reported_id, reason, context, evidence_url, created_at')
    .order('created_at', { ascending: false });

  const list = complaints || [];

  return (
    <div>
      <h1 className="mb-6 text-2xl font-bold text-slate-800">الشكاوى</h1>
      <ComplaintsList complaints={list} />
    </div>
  );
}
