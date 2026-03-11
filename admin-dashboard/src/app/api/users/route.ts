import { createAdminClient } from '@/lib/supabase';
import { NextResponse } from 'next/server';

export async function GET(request: Request) {
  try {
    const admin = createAdminClient();
    const { data: users, error } = await admin.auth.admin.listUsers({
      perPage: 100,
    });

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 500 });
    }

    const { data: banned } = await admin.from('admin_banned_users').select('user_id');
    const bannedIds = new Set((banned || []).map((b) => b.user_id));

    const list = (users?.users || []).map((u) => ({
      id: u.id,
      email: u.email,
      createdAt: u.created_at,
      banned: bannedIds.has(u.id),
    }));

    return NextResponse.json({ users: list });
  } catch (e) {
    return NextResponse.json({ error: String(e) }, { status: 500 });
  }
}
