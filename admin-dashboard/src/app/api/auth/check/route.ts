import { createServerSupabaseClient } from '@/lib/supabase-server';
import { createAdminClient } from '@/lib/supabase';
import { NextResponse } from 'next/server';

export async function GET() {
  try {
    const supabase = await createServerSupabaseClient();
    const { data: { user }, error } = await supabase.auth.getUser();

    if (error || !user) {
      return NextResponse.json({ admin: false }, { status: 401 });
    }

    const admin = createAdminClient();
    const { data: adminRow } = await admin
      .from('admin_users')
      .select('id')
      .eq('user_id', user.id)
      .single();

    return NextResponse.json({
      admin: !!adminRow,
      user: { id: user.id, email: user.email },
    });
  } catch {
    return NextResponse.json({ admin: false }, { status: 500 });
  }
}
