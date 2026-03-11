import { redirect } from 'next/navigation';
import { createServerSupabaseClient } from '@/lib/supabase-server';
import { createAdminClient } from '@/lib/supabase';

export default async function Home() {
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

  redirect(adminRow ? '/dashboard' : '/login');
}
