import { redirect } from 'next/navigation';
import { createServerSupabaseClient } from '@/lib/supabase-server';
import { createAdminClient } from '@/lib/supabase';
import DashboardNav from './DashboardNav';

export default async function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const supabase = await createServerSupabaseClient();
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) {
    redirect('/login');
  }

  const admin = createAdminClient();
  const { data: adminRow } = await admin
    .from('admin_users')
    .select('id')
    .eq('user_id', user.id)
    .single();

  if (!adminRow) {
    redirect('/login');
  }

  return (
    <div className="flex min-h-screen bg-slate-50" dir="rtl">
      <aside className="w-64 border-l border-slate-200 bg-white p-4">
        <h2 className="mb-6 text-lg font-bold text-slate-800">Swaply Admin</h2>
        <DashboardNav />
        <div className="mt-auto pt-8 text-sm text-slate-500">
          {user.email}
        </div>
      </aside>
      <main className="flex-1 p-8">{children}</main>
    </div>
  );
}
