import { createAdminClient } from '@/lib/supabase';
import BannedTable from './BannedTable';

export default async function BannedPage() {
  const admin = createAdminClient();
  const { data: banned } = await admin.from('admin_banned_users').select('id, user_id, reason, created_at');

  return (
    <div>
      <h1 className="mb-6 text-2xl font-bold text-slate-800">المحظورون</h1>
      <BannedTable banned={banned || []} />
    </div>
  );
}
